import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/ts_motion.dart';

/// Hiệu ứng "sóng" nhỏ — đại diện cho việc dữ liệu đang đồng bộ.
///
/// Ba thanh nhấp nháy liên tục với độ trễ lệch nhau, tạo cảm giác sống.
class TsWaveIndicator extends StatefulWidget {
  const TsWaveIndicator({
    super.key,
    this.color = AppColors.live,
    this.barWidth = 2.5,
    this.gap = 3,
    this.height = 12,
  });

  final Color color;
  final double barWidth;
  final double gap;
  final double height;

  @override
  State<TsWaveIndicator> createState() => _TsWaveIndicatorState();
}

class _TsWaveIndicatorState extends State<TsWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (TsMotion.enabled) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.height,
          width: widget.barWidth * 3 + widget.gap * 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_controller.value + i * 0.22) % 1;
              final wave = math.sin(phase * math.pi * 2);
              final scale = 0.35 + (wave + 1) / 2 * 0.65;
              return Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : widget.gap),
                child: Transform.scale(
                  scaleY: scale,
                  child: Container(
                    width: widget.barWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.45 + scale * 0.55),
                      borderRadius: BorderRadius.circular(widget.barWidth),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
