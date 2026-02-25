import 'package:flutter/material.dart';
import 'package:the_reminder_app/ui/theme/app_gradients.dart';

class GradientPageShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry? contentPadding;

  const GradientPageShell({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    required this.child,
    this.headerPadding = const EdgeInsets.fromLTRB(32, 32, 32, 0),
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    double heightFactor = MediaQuery.of(context).size.height / 800;
    double widthFactor = MediaQuery.of(context).size.width / 360;
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (leading != null) Positioned(top: 20 * heightFactor, left: 20 * widthFactor, child: leading!),
            Column(
              children: [
                Padding(
                  padding: headerPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.all(20),
                      //   decoration: BoxDecoration(
                      //     color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   child: Icon(icon, size: 48, color: Colors.white),
                      // ),
                      // const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withAlpha((0.8 * 255).toInt()),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: contentPadding != null
                          ? Padding(padding: contentPadding!, child: child)
                          : child,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GradientHeaderButton extends StatelessWidget {
  const GradientHeaderButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha((0.15 * 255).toInt()),
      borderRadius: BorderRadius.circular(12),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.white,
      ),
    );
  }
}
