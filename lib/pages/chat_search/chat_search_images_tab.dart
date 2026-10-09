// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/vent_integration.dart';
import 'package:fluffychat/pages/chat/events/video_player.dart';
import 'package:fluffychat/pages/chat_search/search_footer.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart';

class ChatSearchImagesTab extends StatelessWidget {
  final Room room;
  final List<Event> events;
  final void Function() onStartSearch;
  final bool endReached, isLoading;
  final DateTime? searchedUntil;

  const ChatSearchImagesTab({
    required this.room,
    required this.events,
    required this.onStartSearch,
    required this.endReached,
    required this.isLoading,
    super.key,
    required this.searchedUntil,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppConfig.borderRadius / 2);
    final theme = Theme.of(context);

    // [vent] Grouped by the label shown, so the host's calendar (Jalali
    // months do not line up with Gregorian ones) never splits or merges a
    // header. Without a host the label is one per Gregorian month, as before.
    String monthLabel(DateTime month) => VentIntegration.formatDate(
      month,
      VentDateStyle.yearMonth,
      () => DateFormat.yMMMM(
        Localizations.localeOf(context).languageCode,
      ).format(month),
    );
    final eventsByMonth = <String, List<Event>>{};
    for (final event in events) {
      final label = monthLabel(event.originServerTs);
      eventsByMonth[label] ??= [];
      eventsByMonth[label]!.add(event);
    }
    final eventsByMonthList = eventsByMonth.entries.toList();

    const padding = 8.0;

    return ListView.builder(
      itemCount: eventsByMonth.length + 1,
      itemBuilder: (context, i) {
        if (i == eventsByMonth.length) {
          return SearchFooter(
            searchedUntil: searchedUntil,
            endReached: endReached,
            isLoading: isLoading,
            onStartSearch: onStartSearch,
          );
        }

        final monthEvents = eventsByMonthList[i].value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: theme.dividerColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    eventsByMonthList[i].key,
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: theme.dividerColor),
                ),
              ],
            ),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              mainAxisSpacing: padding,
              crossAxisSpacing: padding,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(padding),
              crossAxisCount: 3,
              children: monthEvents.map((event) {
                if (event.messageType == MessageTypes.Video) {
                  return Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: borderRadius,
                    child: EventVideoPlayer(event),
                  );
                }
                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => ImageViewer(event, outerContext: context),
                  ),
                  borderRadius: borderRadius,
                  child: Material(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: borderRadius,
                    child: MxcImage(
                      event: event,
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                      animated: true,
                      isThumbnail: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
