import 'package:area_connect/src/imports/core_imports.dart';
import 'package:area_connect/src/imports/packages_imports.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class AppCapsuleTabBar extends StatefulWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;
  final double height;
  final EdgeInsetsGeometry margin;
  final bool isScrollable;
  final TabAlignment? tabAlignment;

  const AppCapsuleTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.height = 44.0,
    this.isScrollable = false,
    this.tabAlignment = TabAlignment.center,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<AppCapsuleTabBar> createState() => _AppCapsuleTabBarState();

  @override
  Size get preferredSize => Size.fromHeight(height + margin.vertical);
}

class _AppCapsuleTabBarState extends State<AppCapsuleTabBar> {
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
            child: TabBar(
              controller: widget.controller,
              isScrollable: widget.isScrollable,
              tabAlignment: widget.isScrollable
                  ? (widget.tabAlignment ?? TabAlignment.start)
                  : null,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(4.h),
              indicator: BoxDecoration(
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
              labelColor: cs.onSurface,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              unselectedLabelStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
              tabs: widget.tabs,
            ),
          ),
        ),
      ),
    );
  }
}
