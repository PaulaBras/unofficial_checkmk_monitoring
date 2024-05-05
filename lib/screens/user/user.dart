import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ptp_4_monitoring_app/screens/my_home_page.dart';
import 'package:ptp_4_monitoring_app/widgets/app_bar_widget.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
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
              'User interface',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: SvgPicture.asset(
              'images/icon_topic_user_interface.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
            ),
          ),
          // Headline
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Color theme')),
          ),
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Sidebar position')),
          ),
          ListTile(
            title: Text(
              'User profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: Image.asset(
              'images/icon_topic_profile.png',
              width: 30,
              height: 30,
            ),
          ),
          // Headline
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Edit profile')),
          ),
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Notification rules')),
          ),
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Change password')),
          ),
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Two-factor authentication')),
          ),
          GestureDetector(
            onTap: () => RouteInformation(),
            child: ListTile(title: Text('Logout')),
          ),
        ],
      ),
    );
  }
}
