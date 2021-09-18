import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/login.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      title: '호산고등학교 알리미',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: user != null ? HomePage() : LoginPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메인'),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Text('현재 할당된 과제', style: Theme.of(context).textTheme.headline5)
              ],
            )
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(user.photoURL ?? ''),
                backgroundColor: Colors.transparent,
              ),
              accountEmail: Text(user.email ?? ''),
              accountName: Text(user.displayName ?? ''),
              decoration: BoxDecoration(
                color: Colors.deepPurple[400],
              ),
            ),
            Divider(height: 0),
            ListTile(
              title: Text('메인'),
              leading: Icon(Icons.home),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('과제 및 수행평가'),
              leading: Icon(Icons.assignment),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('내 학반'),
              leading: Icon(Icons.school),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('급식 메뉴'),
              leading: Icon(Icons.dining),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('화장실 휴지 현황'),
              leading: Icon(Icons.data_usage),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: Align(alignment: Alignment.bottomCenter),
            ),
            Divider(height: 0),
            ListTile(
              title: Text('로그아웃', style: TextStyle(color: Colors.red)),
              dense: true,
              leading: Icon(Icons.logout, color: Colors.red),
              onTap: () async {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('로그아웃'),
                        content: Text('로그아웃할까요?'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('계속하기'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await FirebaseAuth.instance.signOut();
                              await GoogleSignIn().signOut();
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                      fullscreenDialog: true));
                            },
                          ),
                          TextButton(
                            child: Text('취소'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('설정'),
              dense: true,
              leading: Icon(Icons.settings),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(height: 0),
            ListTile(
              title: Text('개발자 및 정보'),
              dense: true,
              leading: Icon(Icons.info),
              onTap: () async {
                PackageInfo packageInfo = await PackageInfo.fromPlatform();
                showAboutDialog(
                    context: context,
                    applicationName: packageInfo.appName,
                    applicationIcon:
                        Image.asset('assets/hosan.png', width: 70, height: 70),
                    applicationVersion: packageInfo.version,
                    applicationLegalese: '호산고 제3기 로봇공학반 교내 피지컬 컴퓨팅 대회 출품작',
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: RichText(
                            text: TextSpan(children: [
                          TextSpan(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            text: '앱/서버 개발: ',
                          ),
                          TextSpan(
                            style: TextStyle(color: Colors.black),
                            text: '황부연 ',
                          ),
                          TextSpan(
                            style: TextStyle(color: Colors.blue),
                            text: '(21181@hosan.hs.kr)',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch('21181@hosan.hs.kr');
                              },
                          ),
                          TextSpan(
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            text: '\n하드웨어 개발/설계: ',
                          ),
                          TextSpan(
                            style: TextStyle(color: Colors.black),
                            text: '강해, 이승민',
                          ),
                        ])),
                      )
                    ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
