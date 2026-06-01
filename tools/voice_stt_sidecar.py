import asyncio
import json
import queue
import threading
from dataclasses import dataclass, field

try:
    import sounddevice as sd
    from vosk import KaldiRecognizer, Model
    import websockets
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency for voice STT sidecar. Install with: "
        "pip install vosk sounddevice websockets"
    ) from exc


@dataclass
class SessionConfig:
    language: str = "en-US"
    phrase_timeout_ms: int = 5000
    active_surface_forms: list[str] = field(default_factory=list)
    active_aliases: dict[str, str] = field(default_factory=dict)
    expected_words: list[str] = field(default_factory=list)


class StreamingRecognizer:
    def __init__(self) -> None:
        self.config = SessionConfig()
        self.audio_queue: "queue.Queue[bytes]" = queue.Queue()
        self.model = Model(lang="en-us")
        self.recognizer: KaldiRecognizer | None = None
        self.stream: sd.RawInputStream | None = None
        self.is_listening = False
        self.last_level = 0.0

    def update_config(self, payload: dict) -> None:
        self.config = SessionConfig(
            language=payload.get("language", "en-US"),
            phrase_timeout_ms=int(payload.get("phrase_timeout_ms", 5000)),
            active_surface_forms=list(payload.get("active_surface_forms", [])),
            active_aliases=dict(payload.get("active_aliases", {})),
            expected_words=list(payload.get("expected_words", [])),
        )
        grammar_words = self.config.active_surface_forms or ["UH"]
        grammar_json = json.dumps(grammar_words)
        self.recognizer = KaldiRecognizer(self.model, 16000, grammar_json)

    def start(self) -> None:
        if self.recognizer is None:
            self.update_config({})
        self.is_listening = True
        self.stream = sd.RawInputStream(
            samplerate=16000,
            blocksize=8000,
            device=None,
            dtype="int16",
            channels=1,
            callback=self._audio_callback,
        )
        self.stream.start()

    def stop(self) -> None:
        self.is_listening = False
        if self.stream is not None:
            self.stream.stop()
            self.stream.close()
            self.stream = None
        while not self.audio_queue.empty():
            self.audio_queue.get_nowait()

    def _audio_callback(self, indata, frames, time_info, status) -> None:
        del frames, time_info, status
        if not self.is_listening:
            return
        audio_bytes = bytes(indata)
        self.audio_queue.put(audio_bytes)
        if audio_bytes:
            peak = max(abs(int.from_bytes(audio_bytes[index:index + 2], "little", signed=True)) for index in range(0, len(audio_bytes), 2))
            self.last_level = min(1.0, peak / 32768.0)


async def session_handler(websocket):
    recognizer = StreamingRecognizer()
    recognizer.update_config({})
    await websocket.send(json.dumps({"type": "ready"}))

    async def send_levels():
        while True:
            await asyncio.sleep(0.08)
            if recognizer.is_listening:
                await websocket.send(json.dumps({"type": "level", "level": recognizer.last_level}))

    async def drain_audio():
        while True:
            await asyncio.sleep(0.05)
            if not recognizer.is_listening or recognizer.recognizer is None:
                continue
            try:
                data = recognizer.audio_queue.get_nowait()
            except queue.Empty:
                continue

            if recognizer.recognizer.AcceptWaveform(data):
                result = json.loads(recognizer.recognizer.Result() or "{}")
                text = str(result.get("text", "")).strip().upper()
                tokens = [token for token in text.split(" ") if token]
                await websocket.send(json.dumps({
                    "type": "final",
                    "raw_text": text,
                    "normalized_text": text,
                    "tokens": tokens,
                    "confidence": 0.85,
                }))
            else:
                partial = json.loads(recognizer.recognizer.PartialResult() or "{}")
                text = str(partial.get("partial", "")).strip().upper()
                tokens = [token for token in text.split(" ") if token]
                await websocket.send(json.dumps({
                    "type": "partial",
                    "raw_text": text,
                    "normalized_text": text,
                    "tokens": tokens,
                }))

    level_task = asyncio.create_task(send_levels())
    audio_task = asyncio.create_task(drain_audio())
    try:
        async for raw_message in websocket:
            message = json.loads(raw_message)
            message_type = message.get("type", "")
            if message_type == "configure_session":
                recognizer.update_config(message)
            elif message_type == "start_listening":
                recognizer.start()
            elif message_type == "stop_listening":
                recognizer.stop()
    finally:
        recognizer.stop()
        level_task.cancel()
        audio_task.cancel()


async def main() -> None:
    async with websockets.serve(session_handler, "127.0.0.1", 8765):
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())
