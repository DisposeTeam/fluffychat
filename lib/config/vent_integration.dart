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

  static bool isRoomVisible(Room room) =>
      roomVisibilityFilter?.call(room) ?? true;
}
