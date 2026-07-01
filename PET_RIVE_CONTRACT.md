# Pet Rive Contract

This document is the handoff spec for the `.riv` file. Build your Rive animation to match these names **exactly** — the code looks up inputs by string, so any typo will silently fail.

## Asset location

```
assets/rive/pet.riv
```

## Artboard

| Field | Value |
|---|---|
| Artboard name | `Pet` |
| State Machine name | `PetSM` |

## Inputs

| Name | Type | Range / Values | Description |
|---|---|---|---|
| `mood` | Number | `0.0` – `1.0` | `0.0` = cheerful, `1.0` = distressed. Drives the expression blend continuously. |
| `greet` | Trigger | — | Fire when pet appears on Home screen. |
| `poke` | Trigger | — | Fire on tap interaction. |
| `celebrate` | Trigger | — | Fire on milestone (streak, compliance win). |
| `cry` | Trigger | — | Fire when session intensity exceeds ~85% of threshold. |
| `wave` | Trigger | — | Generic positive acknowledgement. |
| `isDragging` | Boolean | `true` / `false` | Set while user drags the pet on the Settings screen. |
| `isSleeping` | Boolean | `true` / `false` | Reserved for future idle state. |

## Mood → expression guide

The code maps `mood` linearly across these states; design your blend tree accordingly:

| `mood` range | Intended expression |
|---|---|
| 0.0 – 0.25 | Cheerful, relaxed |
| 0.25 – 0.50 | Mildly worried |
| 0.50 – 0.75 | Pleading, concerned |
| 0.75 – 1.00 | Distressed |

## How to swap in your `.riv`

1. Place your finished file at `assets/rive/pet.riv`.
2. In `lib/core/config.dart`, set `useRivePet = true`.
3. Run the app — no other code changes are needed.

## Notes

- The Rive runtime is initialised automatically when the file loads (`File.asset()` calls `RiveNative.init()` internally). No manual init call is needed.
- The widget is wrapped in a `RepaintBoundary` for performance.
- Keep the artboard size square; the code scales it to the requested `size` parameter.
- If the artboard name `"Pet"` or state machine name `"PetSM"` don't match exactly, the app shows a broken-image error tile and logs the problem to the debug console.
