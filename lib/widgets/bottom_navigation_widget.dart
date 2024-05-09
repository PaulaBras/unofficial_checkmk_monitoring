import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onItemTapped;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Main',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Monitor',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Customize',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Setup',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: Colors.amber[800],
      onTap: onItemTapped,
    );
  }
}