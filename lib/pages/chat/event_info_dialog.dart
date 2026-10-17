// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/vent_integration.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension EventInfoDialogExtension on Event {
  void showInfoDialog(BuildContext context) => showAdaptiveBottomSheet(
    context: context,
    builder: (context) => EventInfoDialog(l10n: L10n.of(context), event: this),
  );
}

class EventInfoDialog extends StatelessWidget {
  final Event event;
  final L10n l10n;

  const EventInfoDialog({required this.event, required this.l10n, super.key});

  String prettyJson(MatrixEvent event) {
    const decoder = JsonDecoder();
    const encoder = JsonEncoder.withIndent('    ');
    final object = decoder.convert(jsonEncode(event.toJson()));
    return encoder.convert(object);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originalSource = event.originalSource;
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).messageInfo),
        leading: CloseButton(
          onPressed: Navigator.of(context, rootNavigator: false).pop,
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Avatar(
              mxContent: event.senderFromMemoryOrFallback.avatarUrl,
              name: event.senderFromMemoryOrFallback.calcDisplayname(),
              client: event.room.client,
              presenceUserId: event.senderId,
            ),
            title: Text(L10n.of(context).sender),
            // [vent] Embedded chat ids are never shown.
            subtitle: Text(
              VentIntegration.embedded
                  ? event.senderFromMemoryOrFallback.calcDisplayname()
                  : '${event.senderFromMemoryOrFallback.calcDisplayname()} [${event.senderId}]',
            ),
          ),
          ListTile(
            title: Text('${L10n.of(context).time}:'),
            subtitle: Text(event.originServerTs.localizedTime(context)),
          ),
          ListTile(
            title: Text('${L10n.of(context).status}:'),
            subtitle: Text(event.status.name),
          ),
          // [vent] The raw event source is a developer tool, not product UI.
          if (!VentIntegration.embedded) ...[
            ListTile(title: Text('${L10n.of(context).sourceCode}:')),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Material(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                color: theme.colorScheme.surfaceContainer,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    prettyJson(MatrixEvent.fromJson(event.toJson())),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ],
          if (!VentIntegration.embedded &&
              event.messageType != MessageTypes.BadEncrypted &&
              originalSource != null) ...[
            ListTile(title: Text('${L10n.of(context).encrypted}:')),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Material(
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                color: theme.colorScheme.surfaceContainer,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    prettyJson(originalSource),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
