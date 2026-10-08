// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:fluffychat/config/vent_chat_design.dart';
import 'package:fluffychat/config/vent_integration.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// [vent] The chat list's header in the Vent design: the display title with
/// round glass buttons for search and a new chat, in place of the search field
/// and the floating "New chat" button.
///
/// Search stays one tap away (the same host / stock search the search field
/// opened); the compose button runs the same journey as the stock FAB.
class VentChatListHeader extends StatelessWidget {
  const VentChatListHeader({
    super.key,
    required this.controller,
    required this.design,
  });

  final ChatListController controller;
  final VentChatDesign design;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                design.listTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: design.titleStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            VentGlassCircleButton(
              design: design,
              icon: Icons.search_rounded,
              tooltip: l10n.search,
              size: 40,
              onPressed: () {
                if (VentIntegration.handleSearch(context)) return;
                controller.startSearch();
              },
            ),
            const SizedBox(width: 8),
            VentGlassCircleButton(
              design: design,
              icon: Icons.edit_outlined,
              tooltip: l10n.newChat,
              size: 40,
              onPressed: () {
                if (VentIntegration.handleStartChat(context)) return;
                context.go('/rooms/newprivatechat');
              },
            ),
          ],
        ),
      ),
    );
  }
}
