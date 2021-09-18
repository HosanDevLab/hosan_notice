import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '호산고등학교 알리미',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('호산고 알리미'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text('Second Page'),
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
                backgroundImage: NetworkImage(user.photoURL!),
                backgroundColor: Colors.transparent,
              ),
              accountEmail: Text(user.email!),
              accountName: Text(user.displayName!),
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
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ListTile(
                  title: Text('설정'),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
