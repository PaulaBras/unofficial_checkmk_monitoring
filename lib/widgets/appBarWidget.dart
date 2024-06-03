import 'package:flutter/material.dart';

import '../screens/myHomePage.dart';

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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
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
