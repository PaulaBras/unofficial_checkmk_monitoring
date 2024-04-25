import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/widgets/Settings.dart';

class MyHomePage extends StatefulWidget {
  static const String id = 'my_home_page';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final _pageController = PageController();

  static const List<Widget> _widgetOptions = <Widget>[
    Center(child: Text('Main')),
    Center(child: Text('Content for Tab 1')),
    Center(child: Text('Content for Tab 2')),
    Center(child: Text('Content for Tab 3')),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 0;
            });
            _pageController.jumpToPage(0); // Navigate to 'Main' page
          }, // Open the end drawer when the image is tapped
          child: Container(
            margin: EdgeInsets.all(10.0), // Add margin around the image
            child: Image.asset(
              'images/checkmk-icon-white.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
      endDrawer: SettingsDrawer(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
