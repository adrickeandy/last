import 'package:flutter/material.dart';
import '../../core/widgets/glass_container.dart';
import 'widgets/pegasus_chat_view.dart';

class PegasusScreen extends StatelessWidget {
  const PegasusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: const GlassContainer(
            padding: EdgeInsets.zero,
            child: PegasusChatView(),
          ),
        ),
      ),
    );
  }
}
