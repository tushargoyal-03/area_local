import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'package:flutter/material.dart';

class AppCapsuleTabBar extends StatefulWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;
  final double height;
  final EdgeInsetsGeometry margin;

  const AppCapsuleTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 44.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<AppCapsuleTabBar> createState() => _AppCapsuleTabBarState();

  @override
  Size get preferredSize => Size.fromHeight(height + margin.vertical);
}

class _AppCapsuleTabBarState extends State<AppCapsuleTabBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    widget.controller.animation?.addListener(_handleAnimation);
    widget.controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.controller.animation?.removeListener(_handleAnimation);
    widget.controller.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleAnimation() {
    if (mounted) setState(() {});
  }

  void _handleTabChange() {
    if (mounted && widget.controller.index != _currentIndex) {
      setState(() {
        _currentIndex = widget.controller.index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: widget.margin,
      height: widget.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / widget.tabs.length;
          // Use controller.animation.value for smooth sliding during swipe,
          // fallback to currentIndex if animation is null.
          final offset = (widget.controller.animation?.value ?? _currentIndex.toDouble()) * tabWidth;

          return Stack(
            children: [
              // Active Indicator Capsule
              Positioned(
                left: offset,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.05),
                          blurRadius: 1,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tab Labels
              Row(
                children: List.generate(widget.tabs.length, (index) {
                  // For fluid color transition matching the position:
                  final animationValue = widget.controller.animation?.value ?? _currentIndex.toDouble();
                  final proximity = (animationValue - index).abs().clamp(0.0, 1.0);
                  
                  // Interpolate between active and inactive text color
                  final activeColor = cs.onSurface;
                  final inactiveColor = cs.onSurfaceVariant;
                  final currentColor = Color.lerp(activeColor, inactiveColor, proximity);

                  // Interpolate font weight
                  final currentWeight = proximity < 0.5 ? FontWeight.w600 : FontWeight.w500;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.controller.animateTo(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Center(
                        child: Text(
                          widget.tabs[index],
                          style: textTheme.labelLarge?.copyWith(
                            color: currentColor,
                            fontWeight: currentWeight,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
