# Scene Tree and File Layout

## Main.tscn

```text
Main (Node3D)
  World (Node3D)
    Ground (StaticBody3D)
      MeshInstance3D
      CollisionShape3D
    Environment (Node3D)
      WoodPiles (Node3D)
  Player (CharacterBody3D)
    MeshInstance3D
    CollisionShape3D
    CameraPivot (Node3D)
      Camera3D
  SpellManager (Node)
    ActiveSpells (Node3D)
  InputController (Node)
  UI (CanvasLayer)
    HUD (Control)
    DebugPanel (Control)
```

## Initial files to create

```text
scripts/player/PlayerController.gd
scripts/player/EnergySystem.gd
scripts/magic/SpellDefinitions.gd
scripts/magic/MagicEngine.gd
scripts/magic/SpellManager.gd
scripts/input/InputController.gd
scripts/input/VoicePowerTracker.gd
scripts/input/DiagramRecognizer.gd
scripts/effects/SparkEffect.gd
scripts/effects/Fireball.gd
scripts/effects/Bonfire.gd
scripts/environment/WoodPile.gd
scripts/ui/HUD.gd
scripts/ui/DebugPanel.gd
```
