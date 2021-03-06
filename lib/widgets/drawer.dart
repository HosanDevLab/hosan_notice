import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/pages/assignments.dart';
import 'package:hosan_notice/pages/calendar.dart';
import 'package:hosan_notice/pages/dev_tools.dart';
import 'package:hosan_notice/pages/features_guide.dart';
import 'package:hosan_notice/pages/home.dart';
import 'package:hosan_notice/pages/meal_info.dart';
import 'package:hosan_notice/pages/my_attend.dart';
import 'package:hosan_notice/pages/myclass.dart';
import 'package:hosan_notice/pages/navigation.dart';
import 'package:hosan_notice/pages/settings.dart';
import 'package:hosan_notice/pages/subjects.dart';
import 'package:hosan_notice/pages/teachers.dart';
import 'package:localstorage/localstorage.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/login.dart';

class MainDrawer extends StatefulWidget {
  final BuildContext parentContext;

  MainDrawer({Key? key, required this.parentContext}) : super(key: key);

  _MainDrawerState createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final remoteConfig = FirebaseRemoteConfig.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final storage = new LocalStorage('auth.json');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(NetworkImage(user.photoURL ?? ''), context);
  }

  @override
  Widget build(BuildContext context) {
    final devs = jsonDecode(remoteConfig.getString('DEVELOPERS')) as List;
    final isDev = devs.contains(user.uid);

    return Drawer(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(user.photoURL ?? ''),
              backgroundColor: Colors.transparent,
            ),
            accountEmail: Text((user.email ?? '') + '\n'),
            accountName: Text(user.displayName ?? ''),
            decoration: BoxDecoration(
              color: Colors.deepPurple[400],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              Divider(height: 0),
              ListTile(
                title: Text('??????'),
                dense: true,
                leading: Icon(Icons.home),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => HomePage(),
                    ),
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('?????? ??? ????????????'),
                dense: true,
                leading: Icon(Icons.assignment),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => AssignmentsPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('??? ??????'),
                dense: true,
                leading: Icon(Icons.school),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => MyClassPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('?????? ??????'),
                dense: true,
                leading: Icon(Icons.subject),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => SubjectsPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('????????? ?????? ?????????'),
                dense: true,
                leading: Icon(Icons.event_note),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => CalendarPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('?????? ??????'),
                dense: true,
                leading: Icon(Icons.dining),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => MealInfoPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('????????? ??????'),
                dense: true,
                leading: Icon(Icons.person_search),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => TeachersPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('????????? ??? ?????? (?????????)'),
                enabled: kDebugMode || isDev,
                dense: true,
                leading: Icon(Icons.library_books_outlined),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => MyAttendancePage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              ...(isDev
                  ? [
                      Divider(height: 0),
                      ListTile(
                        title: Text('????????? ??????'),
                        dense: true,
                        leading: Icon(Icons.adb),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            widget.parentContext,
                            MaterialPageRoute(
                              builder: (context) => DevtoolsPage(),
                            ),
                            (route) => route.isFirst,
                          );
                        },
                      )
                    ]
                  : []),
              Divider(height: 0),
              ListTile(
                title: Text('??????'),
                dense: true,
                leading: Icon(Icons.settings),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    widget.parentContext,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                    ),
                    (route) => route.isFirst,
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('?????? ???????????? ????????????'),
                dense: true,
                leading: Icon(Icons.chat),
                onTap: () {
                  launchUrl(
                    Uri.parse(remoteConfig.getString('OPENCHAT_URL')),
                    mode: LaunchMode.externalApplication,
                  );
                },
                textColor: Colors.orange,
                iconColor: Colors.orange,
              ),
              Divider(height: 0),
              ListTile(
                title: Text('????????????', style: TextStyle(color: Colors.red)),
                dense: true,
                leading: Icon(Icons.logout, color: Colors.red),
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Text('??????????????????????'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('????????????'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await FirebaseAuth.instance.signOut();
                              await GoogleSignIn().signOut();

                              await storage.deleteItem('AUTH_TOKEN');
                              await storage.deleteItem('REFRESH_TOKEN');

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                          TextButton(
                            child: Text('??????'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('??? ?????? ?????? ??? ?????????'),
                dense: true,
                leading: Icon(Icons.question_mark),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FeaturesGuidePage(),
                    ),
                  );
                },
              ),
              Divider(height: 0),
              ListTile(
                title: Text('????????? ??? ??????'),
                dense: true,
                leading: Icon(Icons.info),
                onTap: () async {
                  PackageInfo packageInfo = await PackageInfo.fromPlatform();
                  showAboutDialog(
                    context: context,
                    applicationName: "?????????\n?????????",
                    applicationIcon: GestureDetector(
                      onTap: () {
                        Fluttertoast.showToast(
                          msg: "????????? ?????????",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      },
                      child: Image.asset(
                        'assets/hosan.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                    applicationVersion:
                        '${packageInfo.version}\n(???????????? ${packageInfo.buildNumber})',
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .apply(
                                        fontSizeDelta: 1, fontWeightDelta: 2),
                                text: '???8??? ???????????? SW ?????? ????????? ?????? ????????? ?????????\n\n',
                              ),
                              TextSpan(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                text: '???/?????? ??????: ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.black),
                                text: '????????? (2022 2?????? 8???) ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.blue),
                                text: '(21181@hosan.hs.kr)',
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(
                                      Uri.parse(
                                        'mailto:${remoteConfig.getString('SUPPORT_EMAIL')}',
                                      ),
                                    );
                                  },
                              ),
                              TextSpan(
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                text: '\n???????????? ??????/??????: ',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.black),
                                text: '??????, ????????? (2022 2?????? 8???)',
                              ),
                              TextSpan(
                                style: TextStyle(color: Colors.black),
                                text: '\n\n* ??? ????????? ????????? ??????????????? ??????????????? '
                                    '?????? ????????? ????????? ????????? ????????? ?????? '
                                    '????????? ???????????? ?????????????????? ????????????????????? '
                                    '?????? ?????? ?????? ????????? ?????? ?????????????????? ????????????.',
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        )
      ],
    ));
  }
}
