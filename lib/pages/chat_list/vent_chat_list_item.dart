// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/vent_chat_design.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

/// [vent] The chat list row in the Vent design: a glass card with the avatar,
/// the name, "last message · time" on one line and a small accent dot when
/// there is something unread.
///
/// Used by `ChatListItem` only when `VentChatDesign.of(context)` is non-null,
/// so the standalone build never reaches it.
class VentChatListItem extends StatelessWidget {
  const VentChatListItem({
    super.key,
    required this.room,
    required this.design,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.activeChat = false,
    this.filter,
  });

  final Room room;
  final VentChatDesign design;
  final VoidCallback onTap;
  final void Function(BuildContext context)? onLongPress;

  /// Replaces the unread dot (the invite-decline button).
  final Widget? trailing;
  final bool activeChat;
  final String? filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locals = MatrixLocals(L10n.of(context));
    final displayname = room.getLocalizedDisplayname(locals);
    final filter = this.filter;
    if (filter != null && !displayname.toLowerCase().contains(filter)) {
      return const SizedBox.shrink();
    }

    final lastEvent = room.lastEvent;
    final typingText = room.getLocalizedTypingText(context);
    final directChatMatrixId = room.directChatMatrixID;
    final isDirectChat = directChatMatrixId != null;
    final isInvite = room.membership == Membership.invite;
    final unread =
        room.isUnread || room.notificationCount > 0 || room.markedUnread;
    final needLastEventSender =
        lastEvent != null &&
        room.getState(EventTypes.RoomMember, lastEvent.senderId) == null;
    final withSender =
        !isDirectChat || directChatMatrixId != room.lastEvent?.senderId;

    return FutureBuilder(
      future: room.name.isEmpty ? room.loadHeroUsers() : null,
      builder: (context, _) => VentChatCard(
        design: design,
        onTap: onTap,
        onLongPress: onLongPress == null ? null : () => onLongPress!(context),
        selected: activeChat,
        unread: unread,
        trailing: trailing,
        avatar: Avatar(
          mxContent: room.avatar,
          name: displayname,
          size: 40,
          onTap: () => onLongPress?.call(context),
        ),
        name: displayname,
        muted: room.pushRuleState != PushRuleState.notify,
        pinned: room.isFavourite,
        time: !room.isSpace && !isInvite
            ? room.latestEventReceivedTime.localizedTimeShort(context)
            : null,
        subtitle: (style) => typingText.isNotEmpty
            ? Text(
                typingText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: theme.colorScheme.primary),
              )
            : FutureBuilder(
                key: ValueKey(
                  '${lastEvent?.eventId}_${lastEvent?.type}_${lastEvent?.redacted}',
                ),
                future: needLastEventSender
                    ? lastEvent.calcLocalizedBody(
                        locals,
                        hideReply: true,
                        hideEdit: true,
                        plaintextBody: true,
                        removeMarkdown: true,
                        withSenderNamePrefix: withSender,
                      )
                    : null,
                initialData: lastEvent?.calcLocalizedBodyFallback(
                  locals,
                  hideReply: true,
                  hideEdit: true,
                  plaintextBody: true,
                  removeMarkdown: true,
                  withSenderNamePrefix: withSender,
                ),
                builder: (context, snapshot) => Text(
                  isInvite
                      ? room
                                .getState(
                                  EventTypes.RoomMember,
                                  room.client.userID!,
                                )
                                ?.content
                                .tryGet<String>('reason') ??
                            (isDirectChat
                                ? L10n.of(context).newChatRequest
                                : L10n.of(context).inviteGroupChat)
                      : room.isSpace
                      ? L10n.of(context).countChats(room.spaceChildren.length)
                      : snapshot.data ?? L10n.of(context).noMessagesYet,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
      ),
    );
  }
}

/// The visual shell of a chat row, free of any Matrix state so it can be
/// rendered on its own.
class VentChatCard extends StatelessWidget {
  const VentChatCard({
    super.key,
    required this.design,
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.time,
    this.unread = false,
    this.selected = false,
    this.muted = false,
    this.pinned = false,
    this.trailing,
  });

  final VentChatDesign design;
  final Widget avatar;
  final String name;

  /// Builds the last-message text with the style the row wants.
  final Widget Function(TextStyle style) subtitle;
  final String? time;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool unread;
  final bool selected;
  final bool muted;
  final bool pinned;

  /// Replaces the unread dot (the invite-decline button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final muteColor = theme.colorScheme.onSurfaceVariant;
    final subtitleStyle = TextStyle(
      fontSize: 14,
      color: unread ? onSurface : muteColor,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
      child: Material(
        color: selected ? design.glassBorder : design.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(design.cardRadius),
          side: BorderSide(color: design.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 14, 16, 14),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: onSurface,
                              ),
                            ),
                          ),
                          if (muted)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 14,
                                color: muteColor,
                              ),
                            ),
                          if (pinned)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                              ),
                              child: Icon(
                                Icons.push_pin_outlined,
                                size: 14,
                                color: muteColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(child: subtitle(subtitleStyle)),
                          if (time != null) ...[
                            Text(' · ', style: subtitleStyle),
                            Text(
                              time!,
                              maxLines: 1,
                              style: subtitleStyle.copyWith(color: muteColor),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (unread)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: design.unreadDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
