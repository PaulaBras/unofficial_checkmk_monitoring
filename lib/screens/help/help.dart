import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '/screens/help/InfoPage.dart';
import '/screens/myHomePage.dart';
import '/widgets/appBarWidget.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  void _launchURL(String url) async {
    var parsedUrl = Uri.parse(url);
    if (await canLaunchUrl(parsedUrl)) {
      await launchUrl(parsedUrl, mode: LaunchMode.platformDefault);
    } else {
      throw 'Could not launch $url';
    }
  }

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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: SvgPicture.asset(
              'images/icon_learning_checkmk.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.surface, BlendMode.srcIn),
            ),
          ),
          // Headline
          GestureDetector(
            onTap: () =>
                _launchURL('https://docs.checkmk.com/2.2.0/en/welcome.html'),
            child: ListTile(title: Text('Beginners Guide')),
          ),
          GestureDetector(
            onTap: () => _launchURL('https://docs.checkmk.com/2.2.0/en/'),
            child: ListTile(title: Text('User manual')),
          ),
          GestureDetector(
            onTap: () => _launchURL(
                'https://www.youtube.com/playlist?list=PL8DfRO2DvOK1slgjfTu0hMOnepf1F7ssh'),
            child: ListTile(title: Text('Video Tutorials')),
          ),
          GestureDetector(
            onTap: () => _launchURL('https://forum.checkmk.com/'),
            child: ListTile(title: Text('Community Forum')),
          ),
          ListTile(
            title: Text(
              'Developer resources',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: SvgPicture.asset(
              'images/icon_developer_resources.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.surface, BlendMode.srcIn),
            ),
          ),
          // Headline
          GestureDetector(
            onTap: () => _launchURL(
                'https://docs.checkmk.com/2.2.0/en/devel_check_plugins.html'),
            child: ListTile(title: Text('Check plugin API introduction')),
          ),
          GestureDetector(
            onTap: () =>
                _launchURL('https://docs.checkmk.com/2.2.0/en/rest_api.html'),
            child: ListTile(title: Text('REST API introduction')),
          ),
          ListTile(
            title: Text(
              'About Checkmk',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: SvgPicture.asset(
              'images/icon_about_checkmk.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.surface, BlendMode.srcIn),
            ),
          ),
          // Headline
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => InfoPage()),
            ),
            child: ListTile(title: Text('Info')),
          ),
        ],
      ),
    );
  }
}
