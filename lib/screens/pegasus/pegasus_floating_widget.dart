import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/glass_container.dart';
import '../../providers/ui_provider.dart';
import 'widgets/pegasus_chat_view.dart';

class PegasusFloatingWidget extends StatelessWidget {
  const PegasusFloatingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.read<UIProvider>();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 380,
        maxHeight: 520,
      ),
      child: GlassContainer(
        enableGlow: true,
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            const PegasusChatView(compact: true),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => ui.setPegasusFloating(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
