# Qollider

An AR ping-pong game for Android that uses the front-facing camera and MediaPipe hand tracking to control a virtual paddle in a Qt Quick 3D physics environment.

---

## What it does

The front camera detects the player's hand in real time. The hand position drives a kinematic paddle inside a 3D arena. A ball bounces around the arena and the player must keep it in play. Speed increases every 5 successful hits. Three lives per game; high scores are saved locally.

---

## Prerequisites

| Tool | Version |
|---|---|
| Android Studio | Ladybug or newer |
| Qt | 6.10.3 (arm64-v8a kit required) |
| Android SDK | API 35 (compile), API 28 (min) |
| Android NDK | as bundled with the above SDK |
| Physical device | arm64-v8a, Android 9+, front camera |

Qt can be installed via the [Qt Online Installer](https://www.qt.io/download). Make sure to include the **Android arm64-v8a** kit and **Qt Quick 3D** / **Qt Quick 3D Physics** components.

---

## Setup

1. **Clone the repo**

2. **Configure your Qt path** — add a line to `Qollider/local.properties` (create it if it doesn't exist; it is gitignored):
   ```
   qt.path=/path/to/your/Qt/6.10.3
   ```
   The build falls back to the `QT_PATH` environment variable if this property is absent.

3. **Open in Android Studio** — open the `Qollider/` directory (not the repo root).

4. **Sync Gradle** — Android Studio will prompt you. Accept. First sync downloads ~200 MB of dependencies including the MediaPipe hands model.

5. **Run on device** — plug in an arm64 device with USB debugging enabled and hit Run. The emulator does not have a front camera and will not work.

---

## Project structure

```
qollider/
├── qollider_qml/          # Qt Quick 3D game (built by CMake, embedded as a native lib)
│   ├── Main.qml           # Root item: game state, physics world, hand→racket mapping
│   ├── RacketBody.qml     # DynamicRigidBody paddle; receives pitch/yaw/roll from Java
│   ├── Racket.qml         # Visual mesh for the paddle (ping-pong bat)
│   ├── ArenaWalls.qml     # Static physics walls; emits ballMissed signal
│   ├── GlowBall.qml       # Ball mesh + physics body
│   ├── StartScreen.qml    # Pre-game hand placement screen
│   ├── MainMenuScreen.qml # Title / high score screen
│   ├── GameOverScreen.qml # Score entry and retry
│   └── CMakeLists.txt     # Qt cmake module definition
│
└── Qollider/              # Android Studio project (wraps the QML lib)
    └── app/src/main/java/…/
        └── MainActivity.java  # Camera, MediaPipe, hand→QML bridge
```

---

## Architecture

```
Front camera (CameraX)
        │  YUV frames at 30 fps
        ▼
  downsample → 320px  ──► rotateBitmap (display-align)
        │
        ▼
  MediaPipe Hands
        │  NormalizedLandmark coords (0–1)
        ▼
  mapLandmark()          X: raw, Y: pre-inverted (1−y), Z: negated
        │
  Exponential smooth     POSITION_ALPHA=0.3, ROTATION_ALPHA=0.7
        │
  ┌─────┴───────────────┐
  │                     │
setMoveDiff()      setHandRotation()
"wx,wy,mx,my"     "pitch,yaw,roll"   (CSV strings over Qt/QML bridge)
  │                     │
  ▼                     ▼
Main.qml           RacketBody.qml
onMoveDiffChanged  pitch/yaw/roll properties
mapFromViewport()  kinematicEulerRotation
rack.kinematicPosition
```

### The QML/Java bridge

Qt exposes QML properties as Java setters via `QtQuickView`. Java calls `setMoveDiff(String)` and `setHandRotation(String)` which trigger `onMoveDiffChanged` and `onHandRotationChanged` in QML. The bridge is one-way (Java→QML) except for high scores, which are polled every 100 ms from a Handler because `connectSignalListener` doesn't reliably fire for custom QML properties in Qt 6.10.

---

## Coordinate systems

This is the trickiest part of the codebase — read carefully.

### MediaPipe output
- `X`: 0 = left edge, 1 = right edge of image
- `Y`: 0 = top edge, 1 = bottom edge (**positive downward**)
- `Z`: relative depth, negative = closer to camera

### After `mapLandmark()` in Java
- `X`: unchanged (still 0=left, 1=right of sensor image)
- `Y`: **inverted** → `1 - lm.getY()` (now 0=bottom, 1=top)
- `Z`: negated → `-lm.getZ()` (now positive = closer)

### After the front-camera mirror correction in QML (`onMoveDiffChanged`)
QML applies `1.0 - parseFloat(parts[0])` to X and `1.0 - parseFloat(parts[1])` to Y:
- `X`: now 0=right, 1=left (mirror-corrected for front camera)
- `Y`: double-inverted → back to 0=top, 1=bottom of display
  This is intentional: Java pre-inverts so that QML's second `1−y` cancels back to display convention.

### Qt 3D world space
- `Y`: positive = up
- `Z`: positive = toward camera (camera sits at Z=1200, arena back wall at Z=0)
- `camera.mapFromViewport(x, y, z)` converts 0–1 viewport coords into world space

---

## Game logic (Main.qml)

| Property | Purpose |
|---|---|
| `ballLaunchForce` | Impulse applied to ball on serve (Z direction) |
| `racketHitForce` | Base additive impulse on racket contact |
| `ballSpeedMultiplier` | Starts at 1.0; increases by `speedBoostPerHit` every 5 hits; resets on life loss |
| `racketWorldHeight` | Paddle mesh height in world units — used to scale racket to match hand size |
| `stuckBallTimeoutTicks` | 312 ticks × 16 ms ≈ 5 s before a stuck ball is silently reset (no life lost) |
| `zoneRadius` | Viewport-fraction radius of the start-detection zone (0.30 = 30% of screen width) |

**Ball hit impulse formula:** `speed = racketHitForce + ballLaunchForce × ballSpeedMultiplier`

**Life loss:** triggered by `ArenaWalls.onBallMissed` (ball passes the front wall). A stuck ball does **not** cost a life — it silently resets after ~5 s.

**Game start:** player holds wrist inside the central zone for ~3 seconds (hold progress fills on `holdTimer`).

---

## Known issues / future work

- **Rotation calculation** (`MainActivity.java`): pitch and yaw use `atan2` on raw MediaPipe depth values, scaled by 0.5 and hard-clamped to prevent wrap-around. This works but is approximate. The correct approach is to compute the paddle surface normal via a cross-product of the wrist→middle and thumb→pinky vectors, then extract Euler angles from that. The existing code has a `// TODO` comment marking the spot.

- **Lives HUD size** is currently hardcoded in pixels. It should use device-independent units or be proportional to screen size.

- **Start zone detection** uses wrist position only. A more robust trigger would also check that the hand is open (wrist-to-middle distance above a threshold), to avoid accidentally starting with a closed fist.

---

## Dependencies

| Library | Purpose |
|---|---|
| `com.google.mediapipe:hands` | Hand landmark detection |
| `com.google.mediapipe:solution-core` | MediaPipe runtime |
| `androidx.camera:camera-*` | CameraX preview + analysis |
| ~~`org.apache.commons:commons-math3`~~ | Removed — was unused |
| `org.qtproject.qt.gradleplugin` | Gradle plugin that builds the CMake/QML module |

---

## Build notes

- **Gradle 8.9 / AGP 8.7.3** — pinned because the Qt Gradle plugin (`1.x`) has a Groovy version conflict with newer AGP. Do not upgrade without testing.
- The `tasks.register("testClasses")` stub in `app/build.gradle` exists because AGP 8.x removed that task and the Qt plugin still expects it.
- `local.properties` is gitignored. Every developer needs their own with `qt.path` set.
- `qollider_qml/CMakeLists.txt.qtds` is a Qt Design Studio artifact — it is gitignored and should not be committed.
