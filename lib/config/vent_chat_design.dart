// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:ui' as ui;

import 'package:fluffychat/config/vent_integration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// [vent] Design tokens the Vent app hands to the embedded chat screens, as a
/// [ThemeExtension] on the host's chat theme.
///
/// The fork cannot import the host's palette, so the host installs the values
/// it wants (glass fills, display font, accent) here and the restyled widgets
/// read them back. Everything is gated on [VentIntegration.embedded] *and* the
/// extension being present, so the standalone Mio Chat build — which has
/// neither — takes the stock FluffyChat path untouched.
@immutable
class VentChatDesign extends ThemeExtension<VentChatDesign> {
  const VentChatDesign({
    required this.listTitle,
    required this.titleStyle,
    required this.glassFill,
    required this.glassBorder,
    required this.incomingBubble,
    required this.ownBubble,
    required this.onOwnBubble,
    required this.unreadDot,
    required this.surface,
    this.bubbleRadius = 22,
    this.cardRadius = 24,
  });

  /// "Conversations", already localized by the host.
  final String listTitle;

  /// Display style (Boldonse) for [listTitle].
  final TextStyle titleStyle;

  /// Translucent card / pill / circle-button fill.
  final Color glassFill;
  final Color glassBorder;

  /// Received message bubble (dark glass in dark mode).
  final Color incomingBubble;

  /// Sent message bubble and the text on it.
  final Color ownBubble;
  final Color onOwnBubble;

  /// Unread marker in the chat list.
  final Color unreadDot;

  /// Opaque fill for sheets, dialogs and avatars-in-lists. The scaffold itself
  /// is transparent so the host's backdrop shows through, which is why the
  /// places FluffyChat fills with `scaffoldBackgroundColor` need this instead.
  final Color surface;

  final double bubbleRadius;
  final double cardRadius;

  /// The design when the chat runs embedded in Vent, else null (stock look).
  static VentChatDesign? of(BuildContext context) => VentIntegration.embedded
      ? Theme.of(context).extension<VentChatDesign>()
      : null;

  @override
  VentChatDesign copyWith({String? listTitle}) => VentChatDesign(
    listTitle: listTitle ?? this.listTitle,
    titleStyle: titleStyle,
    glassFill: glassFill,
    glassBorder: glassBorder,
    incomingBubble: incomingBubble,
    ownBubble: ownBubble,
    onOwnBubble: onOwnBubble,
    unreadDot: unreadDot,
    surface: surface,
    bubbleRadius: bubbleRadius,
    cardRadius: cardRadius,
  );

  @override
  VentChatDesign lerp(ThemeExtension<VentChatDesign>? other, double t) =>
      other is VentChatDesign && t >= 0.5 ? other : this;
}

/// A round glass button (back, compose, search).
class VentGlassCircleButton extends StatelessWidget {
  const VentGlassCircleButton({
    super.key,
    required this.design,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 38,
  });

  final VentChatDesign design;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: design.glassFill,
      shape: CircleBorder(side: BorderSide(color: design.glassBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}

/// Frosted background for the conversation's app bar and composer.
class VentGlassBlur extends StatelessWidget {
  const VentGlassBlur({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.zero,
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: child,
    ),
  );
}

/// "4 Oct · Today · Sunday": the day separator in the conversation.
///
/// [relative] is the host-localized day word FluffyChat already produces
/// (`localizedDate`: Today / Yesterday / weekday / date).
String ventDaySeparator(BuildContext context, DateTime time, String relative) {
  final lang = Localizations.localeOf(context).languageCode;
  final day = VentIntegration.formatDate(
    time,
    VentDateStyle.monthDay,
    () => DateFormat.MMMd(lang).format(time),
  );
  final weekday = VentIntegration.formatDate(
    time,
    VentDateStyle.weekdayLong,
    () => DateFormat.EEEE(lang).format(time),
  );
  final today = DateTime.now();
  final diff = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(time.year, time.month, time.day)).inDays;
  if (diff == 0 || diff == 1) return '$day · $relative · $weekday';
  return relative == weekday ? '$day · $weekday' : relative;
}
