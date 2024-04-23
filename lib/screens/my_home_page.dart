import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/widgets/Settings.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // number of tabs
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const TabBar(
            tabs: [
              Tab(text: 'Main'),
              Tab(text: 'Monitor'),
              Tab(text: 'Customize'),
              Tab(text: 'Setup'),
            ],
          ),
        ),
        endDrawer: SettingsDrawer(),
        body: const TabBarView(
          children: [
            Center(
              child: Text('Main'),
            ),
            Center(
              child: Text('Content for Tab 1'),
            ),
            Center(
              child: Text('Content for Tab 2'),
            ),
            Center(
              child: Text('Content for Tab 3'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
