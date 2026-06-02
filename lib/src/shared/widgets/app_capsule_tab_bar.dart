import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'dart:ui';
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

  double _getLeftEdge(double value, double tabWidth) {
    final int current = value.floor();
    final double fraction = value - current;
    // Delay movement when going right to stretch, hurry when going left
    return (current + Curves.easeIn.transform(fraction)) * tabWidth;
  }

  double _getRightEdge(double value, double tabWidth) {
    final int current = value.floor();
    final double fraction = value - current;
    // Hurry movement when going right to stretch, delay when going left
    return (current + Curves.easeOut.transform(fraction) + 1) * tabWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: widget.margin,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: cs.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / widget.tabs.length;
                // Use controller.animation.value for smooth sliding during swipe,
                // fallback to currentIndex if animation is null.
                final double animationValue =
                    widget.controller.animation?.value ??
                        _currentIndex.toDouble();
                final double leftEdge = _getLeftEdge(animationValue, tabWidth);
                final double rightEdge =
                    _getRightEdge(animationValue, tabWidth);
                final double activeWidth = rightEdge - leftEdge;

                return Stack(
                  children: [
                    // Active Indicator Capsule
                    Positioned(
                      left: leftEdge,
                      top: 0,
                      bottom: 0,
                      width: activeWidth,
                      child: Padding(
                        padding: EdgeInsets.all(4.h),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.04),
                                blurRadius: 2,
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
                        final proximity =
                            (animationValue - index).abs().clamp(0.0, 1.0);

                        // Interpolate between active and inactive text color
                        final activeColor = cs.onSurface;
                        final inactiveColor = cs.onSurfaceVariant;
                        final currentColor =
                            Color.lerp(activeColor, inactiveColor, proximity);

                        // Interpolate font weight
                        final currentWeight =
                            proximity < 0.5 ? FontWeight.w600 : FontWeight.w500;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              widget.controller.animateTo(
                                index,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
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
          ),
        ),
      ),
    );
  }
}
