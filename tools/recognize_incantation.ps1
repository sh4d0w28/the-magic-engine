param(
    [int]$TimeoutSeconds = 5
)

$ErrorActionPreference = "Stop"

function Write-Result {
    param(
        [hashtable]$Payload
    )

    $Payload | ConvertTo-Json -Compress
}

try {
    Add-Type -AssemblyName System.Speech

    $culture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    $recognizerInfo = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers() |
        Where-Object { $_.Culture.Name -eq $culture.Name } |
        Select-Object -First 1

    if ($null -eq $recognizerInfo) {
        throw "No installed speech recognizer found for $($culture.Name)."
    }

    $recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine

    $phraseMap = [ordered]@{
        "rak" = "RAK"
        "rack" = "RAK"
        "rock" = "RAK"
        "rag" = "RAK"
        "wreck" = "RAK"
        "rak tor" = "RAK TOR"
        "rack tor" = "RAK TOR"
        "rock tor" = "RAK TOR"
        "rag tor" = "RAK TOR"
        "rak tore" = "RAK TOR"
        "rack tore" = "RAK TOR"
        "rock tore" = "RAK TOR"
        "rak tour" = "RAK TOR"
        "rack tour" = "RAK TOR"
        "rock tour" = "RAK TOR"
        "rak door" = "RAK TOR"
        "rack door" = "RAK TOR"
        "rock door" = "RAK TOR"
        "rak dum" = "RAK DUM"
        "rack dum" = "RAK DUM"
        "rock dum" = "RAK DUM"
        "rak dumb" = "RAK DUM"
        "rack dumb" = "RAK DUM"
        "rock dumb" = "RAK DUM"
        "rak doom" = "RAK DUM"
        "rack doom" = "RAK DUM"
        "rock doom" = "RAK DUM"
    }

    $choices = New-Object System.Speech.Recognition.Choices
    foreach ($phrase in $phraseMap.Keys) {
        $choices.Add((New-Object System.Speech.Recognition.SemanticResultValue($phrase, $phraseMap[$phrase])))
    }

    $grammarBuilder = New-Object System.Speech.Recognition.GrammarBuilder
    $grammarBuilder.Culture = $culture
    $grammarBuilder.Append($choices)

    $grammar = New-Object System.Speech.Recognition.Grammar($grammarBuilder)
    $recognizer.LoadGrammar($grammar)
    $recognizer.SetInputToDefaultAudioDevice()

    $result = $recognizer.Recognize([TimeSpan]::FromSeconds($TimeoutSeconds))
    if ($null -eq $result) {
        Write-Result @{
            success = $false
            status = "timeout"
            raw_text = ""
            normalized_input = ""
            confidence = 0.0
            error = "Timed out waiting for microphone input."
        }
        exit 2
    }

    $normalized = ""
    if ($result.Semantics -and $result.Semantics.Value) {
        $normalized = [string]$result.Semantics.Value
    }

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        $normalized = ([string]$result.Text).Trim().ToUpperInvariant()
    }

    Write-Result @{
        success = $true
        status = "recognized"
        raw_text = [string]$result.Text
        normalized_input = $normalized
        confidence = [double]$result.Confidence
        error = ""
    }
    exit 0
}
catch {
    Write-Result @{
        success = $false
        status = "error"
        raw_text = ""
        normalized_input = ""
        confidence = 0.0
        error = $_.Exception.Message
    }
    exit 1
}
