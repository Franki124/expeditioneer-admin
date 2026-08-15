import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

/// Pulsing "LIVE" badge — ported from the player app's leaderboard indicator.
class LivePulseIndicator extends StatefulWidget {
  const LivePulseIndicator({super.key});

  @override
  State<LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<LivePulseIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text('LIVE', style: AppTypography.body(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.gold)),
      ],
    );
  }
}
