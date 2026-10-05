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
| `lib/config/vent_integration.dart` | **New file** — `VentIntegration` host hooks | Single seam for everything below |
| `lib/pages/chat_list/chat_list.dart` | Add `visibleRooms`; `filteredRooms` + `_updateRoomTags` read it | Host can hide server-managed rooms |
| `lib/pages/chat_list/chat_list_body.dart` | Room counts use `visibleRooms`; empty state defers to `chatListEmptyBuilder`; Groups filter hidden unless `VentIntegration.groupChatsEnabled` | Vent renders its own empty state |
| `lib/pages/chat_list/chat_list_header.dart` | Hide `ClientChooserButton`, pin the search icon when `embedded`; with `VentIntegration.searchHandler` set the search bar is read-only and opens the host's search | Host owns accounts/settings/navigation, and searches chats + its own user directory (Conduit's only finds people you already share a room with) |
| `lib/widgets/matrix.dart` | No `BackgroundPush` at all when `embedded` | Host owns push: it registers its own FCM token as the Matrix pusher (one Firebase plugin, one token for chat and host notifications). Also retires the `onFcmError` dialog, which crashed there ("context that does not include a Navigator") |
| `lib/widgets/matrix.dart` | No unprompted web `Notification.requestPermission()` when `embedded` | Host asks from a button (iOS ignores gesture-less prompts); a blocked unprompted prompt would block the host's web push for good |
| `lib/widgets/local_notifications_extension.dart` | Web in-page notification only when permission is granted, and never throws | The constructor throws on mobile browsers (service-worker only there); tag stays the room id so it replaces the host's push instead of doubling it |
| `lib/widgets/local_notifications_extension.dart`, `lib/widgets/matrix.dart` | With `VentIntegration.chatNotificationHandler` set, in-app chat notifications go to the host on every platform, and FluffyChat never initializes the notifications plugin | One plugin owner and one tap router: FluffyChat routed taps through `FluffyChatApp.router`, which an embedding host never shows, so a tapped chat notification went nowhere. Mobile also had no in-app chat notification at all |
| `lib/widgets/matrix.dart` | `activeRoomId` asks `VentIntegration.activeRoomIdResolver` first | Same router reason: without it the open chat notified about its own messages |
| `lib/pages/chat_list/chat_list_item.dart` | Declining an invite the server 403s on marks it left locally | A stale local invite was undismissable ("no permission") |
| `lib/pages/chat_list/start_chat_fab.dart` | Offers the tap to `VentIntegration.handleStartChat` before `/rooms/newprivatechat` | Host finds people in its own directory; its accounts are not arbitrary Matrix IDs |
| `lib/utils/url_launcher.dart` | `launchUrl()` offers the URL to `VentIntegration.handleUrl` first | A link to a host screen opens in the app, not the browser |
| `lib/pages/chat/events/message_content.dart` | Text branch offers the body to `VentIntegration.messageEmbedBuilder` | Host renders a shared event/moment/profile as its own preview card |
| `lib/pages/chat/chat_view.dart` | App-bar overflow defers to `VentIntegration.chatActionsBuilder` | Host replaces the Matrix menu (encryption / emotes / leave) with its own |
| `lib/pages/chat_details/chat_details_view.dart` | Same deferral for the details screen | A deep link can still land there |
| `lib/pages/chat/chat_app_bar_title.dart` | Title tap offers itself to `VentIntegration.handleChatTitleTap` first | Host opens the person, not the room settings |
| `lib/pages/chat_details/participant_list_item.dart` | Member tap offers itself to `VentIntegration.handleMemberTap` first | Host opens the member profile, not the moderation menu |
| `lib/pages/chat/chat_input_row.dart` | Composer placeholder is neutral when `embedded` | "Unencrypted message" advertises a setting an embedded user cannot change |

### The `VentIntegration` seam

Host-app behaviour is injected through `VentIntegration` (a handful of static
hooks) rather than by forking widgets. Every hook is null/false by default, so
the standalone Mio Chat build takes exactly the upstream path. Prefer adding a
hook + a one-line call site over rewriting a widget — that is what keeps the
`sync-upstream.sh` conflicts to a `git merge` of adjacent lines.

The Vent app installs its hooks in
`vent-app/lib/modules/chat/presentation/pages/vent_chat_tab.dart`, themes the
embedded screens via `VentChatTheme`, and mounts the FluffyChat routes it
exposes from `vent-app/lib/modules/chat/presentation/chat_routes.dart`.

### Not yet done (planned)
- Standalone platform identity for store publishing: `android/app/src/main/AndroidManifest.xml`
  label, `ios/Runner/Info.plist` `CFBundleDisplayName` → "Mio Chat"; unique appId/bundle id.
  (Vent has its own `android/` + `ios/`, so these only affect the standalone build.)
- Logo / launcher icon / splash asset swaps (replace file contents, keep filenames → no text conflict).

## Why this stays conflict-free
- Branding is driven by runtime settings + a Material 3 scheme variant, not by forking widgets.
- Host-app behaviour goes through `VentIntegration`, so the chat/list widgets —
  the files upstream changes most — carry a handful of guarded lines rather than
  a rewrite. Each is tagged `[vent]` so `sync-upstream.sh` conflicts are obvious.
- Vent's own theme, routes and empty state live in `vent-app`, not in this fork.
