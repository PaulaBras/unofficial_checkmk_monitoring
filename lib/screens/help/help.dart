import 'package:flutter/material.dart';
import 'package:ptp_4_monitoring_app/screens/my_home_page.dart';
import 'package:ptp_4_monitoring_app/widgets/app_bar_widget.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    final myHomePageLogic = MyHomePageLogic();

    return Scaffold(
      appBar: AppBarWidget(
        onTapLogo: () => myHomePageLogic.navigateToMain(),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
              title: Text(
            'Learning Checkmk',
            style: TextStyle(fontSize: 20),
          )),
          // Headline
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'beginnersGuideScreenId'),
            child: ListTile(title: Text('Beginners Guide')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'userManualScreenId'),
            child: ListTile(title: Text('User manual')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'videoTutorialsScreenId'),
            child: ListTile(title: Text('Video Tutorials')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'communityForumScreenId'),
            child: ListTile(title: Text('Community Forum')),
          ),
          ListTile(
              title: Text(
            'Developer resources',
            style: TextStyle(fontSize: 20),
          )),
          // Headline
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, 'checkPluginApiIntroScreenId'),
            child: ListTile(title: Text('Check plugin API introduction')),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, 'checkPluginApiRefScreenId'),
            child: ListTile(title: Text('Check plugin API reference')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'restApiIntroScreenId'),
            child: ListTile(title: Text('REST API introduction')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'restApiDocScreenId'),
            child: ListTile(title: Text('REST API documentation')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'restApiGuiScreenId'),
            child: ListTile(title: Text('REST API interactive GUI')),
          ),
          ListTile(
              title: Text(
            'About Checkmk',
            style: TextStyle(fontSize: 20),
          )),
          // Headline
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'infoScreenId'),
            child: ListTile(title: Text('Info')),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'changeLogScreenId'),
            child: ListTile(title: Text('Change Log (Werks)')),
          ),
        ],
      ),
    );
  }
}
