import '../../imports/imports.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
    this.onPressed,
    this.isTransparent = false,
    this.showbackbutton = true,
    this.leading,
    this.bottom,
  });

  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onPressed;
  final bool? centerTitle;
  final bool isTransparent;
  final bool showbackbutton;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    // Check if we can pop
    final bool canPop = context.canPop();

    void handleBack() {
      if (onPressed != null) {
        onPressed!();
      } else if (canPop) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }

    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      backgroundColor: isTransparent ? Colors.transparent : null,
      shadowColor: Colors.transparent,
      title: titleWidget ??
          Text(
            title,
          ),
      leadingWidth: 40.w,
      leading: leading ??
          (showbackbutton
              ? BackButton(
                  onPressed: handleBack,
                )
              : null),
      iconTheme: theme.iconTheme,
      actions: actions ?? [],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
