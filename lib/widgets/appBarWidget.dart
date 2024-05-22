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
      backgroundColor: Theme.of(context).colorScheme.background,
      leading: GestureDetector(
        onTap: () {
          onTapLogo();
          Navigator.pushNamed(
              context, 'home_screen'); // Navigate to the main screen
        },
        child: Container(
          margin: const EdgeInsets.all(10.0),
          child: Image.asset(
            'images/checkmk-icon-green.png',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
