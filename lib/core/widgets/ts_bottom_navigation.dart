import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// 04 · ĐIỀU HƯỚNG — Thanh điều hướng dưới · Một mục đang chọn tại một thời điểm.
///
/// Mỗi mục có vùng chạm ≥ 48 × 48 px · Luôn hiển thị nhãn cùng biểu tượng.
/// Mục đang chọn được đánh dấu bằng pill nền tím nhạt.
class TsBottomNavigation extends StatefulWidget {
  const TsBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<TsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  State<TsBottomNavigation> createState() => _TsBottomNavigationState();
}

class _TsBottomNavigationState extends State<TsBottomNavigation> {
  late int _index = widget.currentIndex;

  @override
  void didUpdateWidget(covariant TsBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _index) _index = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < widget.items.length; i++)
                Expanded(
                  child: _TsNavItemButton(
                    item: widget.items[i],
                    isSelected: i == _index,
                    onTap: () {
                      if (i == _index) return;
                      setState(() => _index = i);
                      widget.onChanged(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một mục điều hướng.
class TsNavItem {
  const TsNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TsNavItemButton extends StatelessWidget {
  const _TsNavItemButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final TsNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.secondaryText;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.softPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(item.icon, size: 22, color: color),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                item.label,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
