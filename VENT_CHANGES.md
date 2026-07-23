# Vent / Mio Chat fork — customization log

This fork of [FluffyChat](https://github.com/krille-chan/fluffychat) is maintained
for two consumers from a **single** integration branch, `vent`:

1. **Embedded in the Vent app** (`vent-app` submodule). Vent imports only widgets
   (e.g. `ChatList`) and wraps them in its **own** `MaterialApp` + theme. FluffyChat's
   own app name and theme are therefore **never rendered** inside Vent.
2. **Standalone "Mio Chat" app**, built directly from this fork. Uses FluffyChat's own
   `FluffyChatApp` / `FluffyThemes`, so it shows the Mio Chat identity + B&W theme.

## Branch model

| Branch  | Role                                                        | Commit here? |
|---------|-------------------------------------------------------------|--------------|
| `main`  | Pristine mirror of `upstream/main` (krille-chan/fluffychat) | ❌ never      |
| `vent`  | All customizations below; submodule + standalone build from | ✅ yes        |
| topic/* | Generic bug fixes → PR to upstream, then delete             | ✅ then PR    |

Sync upstream often (small conflicts beat rare huge ones): `./scripts/sync-upstream.sh`.
All customization commits are prefixed `[vent]` so they are easy to find and re-apply.

## Customization map (every upstream file we touch — keep this current)

| File | Change | Why |
|------|--------|-----|
| `lib/config/setting_keys.dart` | `applicationName` default `FluffyChat` → `Mio Chat` | Standalone app identity |
| `lib/config/setting_keys.dart` | `colorSchemeSeedInt` default `0xFF5625BA` → `0xFF000000` | Black seed for B&W theme |
| `lib/config/themes.dart` | `DynamicSchemeVariant.rainbow` → `.monochrome` | Black & white "prototype" theme |

### Not yet done (planned)
- Standalone platform identity for store publishing: `android/app/src/main/AndroidManifest.xml`
  label, `ios/Runner/Info.plist` `CFBundleDisplayName` → "Mio Chat"; unique appId/bundle id.
  (Vent has its own `android/` + `ios/`, so these only affect the standalone build.)
- Logo / launcher icon / splash asset swaps (replace file contents, keep filenames → no text conflict).

## Why this stays conflict-free
- Changes are concentrated in 2 low-churn config files, as small in-place value edits.
- No edits to chat/list widgets, which are the files upstream changes most.
- Branding is driven by runtime settings + a Material 3 scheme variant, not by forking widgets.
