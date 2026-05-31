# Scene Tree and File Layout

## Main.tscn

```text
Main (Node3D)
  Main.gd
  World (Node3D)
    Ground (StaticBody3D)
      MeshInstance3D
      CollisionShape3D
    Environment (Node3D)
      WoodPiles (Node3D)
        WoodPileA
        WoodPileB
        WoodPileC
      TargetDummies (Node3D)
        TargetDummyA
        TargetDummyB
      Hostiles (Node3D)
        HostileEnemyA
    TargetIndicator (Node3D)
  Player (CharacterBody3D)
    EnergySystem (Node)
    MeshInstance3D
    CollisionShape3D
    CameraPivot (Node3D)
      Camera3D
  SpellManager (Node)
    ActiveSpells (Node3D)
  InputController (Node)
    VoicePowerTracker (Node)
    DiagramRecognizer (Node)
  UI (CanvasLayer)
    HUD (Control)
      AimReticle (Control)
    DebugPanel (Control)
```

## Current Core Files

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
scripts/effects/ImpactBurst.gd
scripts/effects/ScorchMark.gd
scripts/effects/TargetIndicator.gd
scripts/environment/TargetDummy.gd
scripts/environment/HostileEnemy.gd
scripts/environment/WoodPile.gd
scripts/ui/HUD.gd
scripts/ui/DebugPanel.gd
scripts/tests/AcceptanceRunner.gd
scripts/Main.gd
```

## Combat Sandbox Notes

The project is no longer just a scene shell. The current `Main.tscn` functions as a local combat sandbox with:

- visible target reticle and ground marker,
- target dummy health/destruction loop,
- hostile chase/contact damage loop,
- wood fuel interaction loop,
- combat HUD score/feed,
- player defeat and automatic encounter reset,
- optional runtime hitbox debug toggle with `F3`,
- headless acceptance verification.
