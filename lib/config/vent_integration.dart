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

  static bool isRoomVisible(Room room) =>
      roomVisibilityFilter?.call(room) ?? true;
}
