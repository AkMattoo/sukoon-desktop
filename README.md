# Sukoon — Qt / QML edition

A native C++17 + Qt Quick rewrite of [sukoon-sanctuary-space](https://github.com/AkMattoo/sukoon-sanctuary-space).
It talks to the **same Node/Express backend** with the same endpoints, payloads, consent flow and crisis signal,
so nothing on the server side changes.

## Build

Requires **Qt 6.5 or newer** with these modules: Quick, QuickControls2, Network, WebSockets, and
**Qt Quick Effects** (`MultiEffect`, which powers every blur, glow and shadow).

```bash
cmake -S . -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x/<compiler>
cmake --build build -j
SUKOON_API_BASE=http://localhost:4000 ./build/sukoon
```

Or open `CMakeLists.txt` in Qt Creator and hit Run.

| Env var | What it does |
|---|---|
| `SUKOON_API_BASE` | Backend URL (same as `VITE_API_BASE`). Default `http://localhost:4000`. The WebSocket URL is derived from it. |
| `SUKOON_REDUCED_MOTION=1` | What "Auto" motion falls back to (Qt has no portable OS reduced-motion query). |

Run with `--tour` to auto-step through every tab and sheet. It's handy as a smoke test or for grabbing screenshots.

## Layout

```
src/                     C++ backend, exposed to QML as singletons in `Sukoon.Backend`
  apiclient.*            port of lib/sukoon.ts: every endpoint, mood mapping, insights bucketing, crisis signal
  session.*              anonymous session + local memory (replaces localStorage via QSettings)
  appsettings.*          comfort settings (lib/settings.ts)
  breathcontroller.*     4-7-8 / grounding timing loop, in C++ so the timing stays exact
  roomsocket.*           room WebSocket: occupancy, chat, captions, help signals, crisis nudge, room-full
  catalog.*              moods, themes, languages, agreement text, offline helplines
qml/
  Main.qml               window, navigation, sticky footer (settings · SOS · tabs)
  Theme.qml              colour/type tokens from styles.css
  components/            AuroraBackground, GradientOrb, GlassCard, GradientButton, Chip, TabBar, Sheet, …
  sheets/                Consent, SOS, Settings
  pages/                 Onboarding, Home, Rooms, Room, Breathe, Buddy, Circle
```

## The effects (QtQuick.Effects / MultiEffect)

- **Aurora background**: three drifting colour fields under a heavy MultiEffect blur, plus a film-grain layer.
- **Real frosted glass**: `GlassCard` samples the live aurora under itself (`ShaderEffectSource` kept in sync by a
  `FrameAnimation`), blurs it, and masks it to the rounded shape, so it stays correct while scrolling.
- **Glowing orb**: a rotating gradient core, a masked blurred halo, and a coloured shadow glow. On Breathe it
  scales over each phase's exact duration and glows brighter on the hold. Ripple rings blur outward on every in-breath.
- **Blurred modal backdrop**: when a sheet opens, the whole app behind it is live-blurred and dimmed.
- **Glow everywhere it means something**: gradient buttons bloom on hover, the active tab tile springs between tabs,
  the SOS button gently pulses, live-room dots breathe, mood bars grow in with a stagger and today's bar glows pink,
  hearts pop.
- **Gradient text**: the accent word in each header is the hero gradient masked through the text.

"Reduced" motion in Comfort settings (or `SUKOON_REDUCED_MOTION=1` under "Auto") stops all ambient animation.

## Differences from the web app

- **No voice audio in rooms.** WebRTC isn't part of Qt. The room still joins the same socket, so you get live occupancy,
  text chat, live captions from web/mobile speakers, help signals and crisis nudges. To add audio, wire up libwebrtc
  behind `RoomSocket` (the `peers/offer/answer/candidate` messages are already arriving).
- **No spoken breathing guide.** The visual guide is complete. Spoken prompts can be added with `QtTextToSpeech`
  using the per-language lines in the original `breathe.tsx`.
- No PWA, service worker or admin page, since those are browser-only.
