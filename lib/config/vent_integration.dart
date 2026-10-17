// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

/// [vent] Hooks a host app can install to adapt the embedded chat widgets to
/// its own shell.
///
/// Every hook defaults to stock FluffyChat behaviour, so the standalone
/// Mio Chat build is unaffected by anything in here. The Vent app installs its
/// hooks once, before the chat list is first built. See VENT_CHANGES.md.
abstract class VentIntegration {
  /// True when the chat widgets run inside a host app that provides its own
  /// navigation, settings and account management. The chat list then drops the
  /// UI that would duplicate or fight with the host's chrome.
  static bool embedded = false;

  /// Visibility filter for the chat list. Rooms this rejects are hidden
  /// everywhere the chat list counts, filters or renders rooms — the host uses
  /// it to hide server-managed rooms a fresh account may be joined to.
  static bool Function(Room room)? roomVisibilityFilter;

  /// Host-provided empty state for the chat list.
  ///
  /// [hasChatsOutsideFilter] is true when the account does have chats but none
  /// match the active filter, so the host can word that differently from an
  /// account with no chats at all.
  static Widget Function(
    BuildContext context, {
    required bool hasChatsOutsideFilter,
  })?
  chatListEmptyBuilder;

  /// Host claim on a link tapped inside the chat. Return true when the host
  /// navigated to one of its own screens; the chat then does nothing further,
  /// so a link to host content never bounces out to the browser.
  ///
  /// Anything the host does not claim takes the stock path — matrix.to links,
  /// the confirm-before-opening dialog and the external browser.
  static bool Function(BuildContext context, String url)? urlHandler;

  static bool handleUrl(BuildContext context, String url) =>
      urlHandler?.call(context, url) ?? false;

  /// Host-rendered body for a text message that turns out to be host content —
  /// a shared event, say, which the host can draw as a preview card instead of
  /// a title and a bare URL.
  ///
  /// Returning null (the default, and for any body the host does not
  /// recognise) leaves the message to the stock renderer. [textColor] is the
  /// bubble's own colour, so the host's widget reads correctly on both the
  /// sent and received bubble.
  static Widget? Function(BuildContext context, String body, Color textColor)?
  messageEmbedBuilder;

  /// Host-supplied replacement for the chat's overflow menu.
  ///
  /// The stock menu offers room plumbing — encryption, emote packs, leaving —
  /// that a host app built on one-to-one conversations has no use for.
  /// Returning null (the default) keeps the stock [ChatSettingsPopupMenu].
  static Widget? Function(
    BuildContext context,
    Room room, {
    required bool displayChatDetails,
  })?
  chatActionsBuilder;

  /// Host claim on a tap of the conversation's title bar. Return true when the
  /// host navigated somewhere itself — a social app opens the person, not the
  /// room's settings. False falls through to the chat details screen.
  static bool Function(BuildContext context, Room room)? chatTitleTapHandler;

  static bool handleChatTitleTap(BuildContext context, Room room) =>
      chatTitleTapHandler?.call(context, room) ?? false;

  /// Host claim on a tap of a room member. Same contract as
  /// [chatTitleTapHandler]; false falls through to the moderation menu.
  static bool Function(BuildContext context, User user)? memberTapHandler;

  static bool handleMemberTap(BuildContext context, User user) =>
      memberTapHandler?.call(context, user) ?? false;

  /// Host claim on "start a new chat". Return true when the host opened its
  /// own way of finding someone; the stock NewPrivateChat screen — a Matrix ID
  /// search, an invite link and a QR code — is then never shown.
  ///
  /// A host whose accounts are its own users, not arbitrary Matrix addresses,
  /// has no use for that screen: you find a person in the host's directory and
  /// message them from their profile. Standalone builds leave this null and
  /// keep the stock screen, which is the only way to reach someone on another
  /// homeserver.
  static bool Function(BuildContext context)? startChatHandler;

  static bool handleStartChat(BuildContext context) =>
      startChatHandler?.call(context) ?? false;

  /// Host claim on the chat list's search. Return true when the host opened
  /// its own search; the search bar then acts as a button and the stock
  /// in-list search mode — public rooms, spaces, a homeserver picker and the
  /// homeserver's user directory — never opens.
  ///
  /// A homeserver's directory only knows people the searcher already shares a
  /// room with, so a host with its own user directory searches people there,
  /// alongside the chats, in its own design.
  static bool Function(BuildContext context)? searchHandler;

  static bool get hasSearchHandler => searchHandler != null;

  static bool handleSearch(BuildContext context) =>
      searchHandler?.call(context) ?? false;

  /// Whether the host offers group chats. False hides the chat list's
  /// "Groups" filter, which would otherwise be an empty tab promising a
  /// feature the host has no way to start.
  static bool groupChatsEnabled = true;

  /// What to call [userId] when it has no display name: its local part in
  /// Mio Chat, and the plain [userLabel] when embedded, where chat ids are
  /// opaque (`@u<hash>`) and never shown.
  static String nameFallback(String userId, String userLabel) =>
      embedded ? userLabel : (userId.localpart ?? userId);

  static bool isRoomVisible(Room room) =>
      roomVisibilityFilter?.call(room) ?? true;

  /// Shows a chat notification for [event], a message the live sync just
  /// delivered, in place of FluffyChat's own. The title and body are already
  /// localized and decrypted. When set, FluffyChat raises these on every
  /// platform (not just web and Linux) and never initializes the local
  /// notifications plugin itself: the host owns it, along with tap routing.
  ///
  /// The sync also replays what arrived while the app was in the background,
  /// so the host decides from the event's timestamp whether it is news.
  static Future<void> Function({
    required Event event,
    required String title,
    required String body,
  })?
  chatNotificationHandler;

  /// The room the host is showing, if any. FluffyChat otherwise reads it from
  /// its own router, which an embedding host never displays — so without this
  /// the open chat would notify about its own messages.
  static String? Function()? activeRoomIdResolver;

  /// Host-supplied date and time labels, so the chat shows dates in the
  /// calendar the host's user picked (Jalali, say) instead of the Gregorian
  /// ones `intl` knows. Return null for a [style] the host does not handle and
  /// FluffyChat formats it as usual; null (the default) hook = stock behaviour.
  ///
  /// Asked every time a label is built, so the host reads its calendar setting
  /// inside the callback and a change shows on the next rebuild.
  static String? Function(DateTime date, VentDateStyle style)? dateFormatter;

  /// [fallback] when the host has no opinion (no hook, or it returned null).
  static String formatDate(
    DateTime date,
    VentDateStyle style,
    String Function() fallback,
  ) => dateFormatter?.call(date, style) ?? fallback();

  /// Wraps a chat-list row so a long-press (or right-click) opens the host's
  /// own menu for [room]; the host owns the items, since what a chat offers
  /// (block, report, delete) is a product decision. [onOpen] opens the chat —
  /// what tapping the lifted row does. Null keeps FluffyChat's stock menu.
  static Widget Function(
    BuildContext context, {
    required Room room,
    required Widget child,
    required VoidCallback onOpen,
  })?
  chatListItemMenuBuilder;

  /// Wraps [child] so a long-press (or right-click) opens the host's context
  /// menu with [actions], asked for at the moment it opens. Null keeps the
  /// stock gesture (FluffyChat's message long-press enters selection mode).
  static Widget Function(
    BuildContext context, {
    required Widget child,
    required List<VentChatMenuAction> Function() actions,
    BorderRadius? borderRadius,
  })?
  contextMenuBuilder;

  /// A button that opens the host's pull-down menu with [actions]. [anchor]
  /// draws the button; wire its tap to `open`, which is null while there is
  /// nothing to show. Null keeps FluffyChat's stock `PopupMenuButton`.
  static Widget Function(
    BuildContext context, {
    required Widget Function(BuildContext context, VoidCallback? open) anchor,
    required List<VentChatMenuAction> Function() actions,
  })?
  pullDownMenuBuilder;

  /// The host's confirmation dialog, in place of the stock adaptive alert.
  /// Resolves true only when the user confirmed.
  static Future<bool> Function(
    BuildContext context, {
    required String title,
    String? message,
    required String okLabel,
    required String cancelLabel,
    required bool isDestructive,
  })?
  confirmHandler;

  /// The host's action sheet, in place of the stock Material/Cupertino one:
  /// pick one of [actions]. Resolves to the picked index, or null.
  static Future<int?> Function(
    BuildContext context, {
    String? title,
    String? message,
    required List<VentChatMenuAction> actions,
  })?
  actionSheetHandler;
}

/// [vent] One row in a host-drawn menu or sheet.
class VentChatMenuAction {
  const VentChatMenuAction({
    required this.label,
    required this.onTap,
    this.id,
    this.icon,
    this.isDestructive = false,
    this.startsSection = false,
  });

  /// FluffyChat's own wording; the host may replace it by [id].
  final String label;

  /// A stable name for the action (`reply`, `copy`, `delete`…), so the host
  /// can relabel it in its own voice and language. Null for one-off rows.
  final String? id;

  /// Runs after the menu has closed.
  final VoidCallback onTap;

  final IconData? icon;
  final bool isDestructive;

  /// Opens a new group of rows (a wider separator before it).
  final bool startsSection;
}

/// The shapes of date label the chat shows. Each maps to the `intl` skeleton
/// named beside it, which is what the stock formatting uses.
enum VentDateStyle {
  /// `E`: "Wed".
  weekdayShort,

  /// `EEEE`: "Wednesday".
  weekdayLong,

  /// `MMMd`: "Sep 9".
  monthDay,

  /// `MMMMd`: "September 9".
  monthDayLong,

  /// `yMMMd`: "Sep 9, 2026".
  yearMonthDay,

  /// `yMMMMd`: "September 9, 2026".
  yearMonthDayLong,

  /// `yMMMM`: "September 2026".
  yearMonth,

  /// The clock: "17:05" / "5:05 PM". Calendar-independent; the host decides
  /// 12/24 hour and the digits.
  timeOfDay,
}
