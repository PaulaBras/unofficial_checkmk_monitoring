import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onTapLogo;

  const AppBarWidget({
    super.key,
    required this.onTapLogo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: GestureDetector(
        onTap: onTapLogo,
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Image.asset(
            'images/checkmk-icon-white.png',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
