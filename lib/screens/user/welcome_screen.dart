import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Hero(
                  tag: 'logo',
                  child: Image(
                    image: AssetImage('images/checkmk-logo-white.png'),
                    height: 60.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48.0),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'login_screen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              child: const Text('Log In'),
            ),
          ],
        ),
      ),
    );
  }
}
