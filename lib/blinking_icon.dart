import 'package:flutter/material.dart';

class BlinkingIconOverlay extends StatefulWidget {
  final ValueNotifier<bool> isActive;

  const BlinkingIconOverlay({Key? key, required this.isActive}) : super(key: key);

  @override
  State<BlinkingIconOverlay> createState() => _BlinkingIconOverlayState();
}

class _BlinkingIconOverlayState extends State<BlinkingIconOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Blinking effect
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isActive,
      builder: (context, isActive, child) {
        if (!isActive) return const SizedBox.shrink(); // Hide if not active

        return Positioned(
          right: 20,
          bottom: 80, // Adjust position as needed
          child: FadeTransition(
            opacity: _animationController,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Colors.red,
              child: const Icon(Icons.warning, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
