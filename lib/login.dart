import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/hosan.png', width: 50),
              Container(
                padding: EdgeInsets.only(left: 15, bottom: 5),
                child: Text(
                  '호산고등학교',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
            ],
          ),
          Text('학업 알림 및 휴지 현황 시스템'),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: () async {
                  final GoogleSignInAccount? googleSignInAccount = await GoogleSignIn().signIn();
                  final GoogleSignInAuthentication googleSignInAuthentication =
                  await googleSignInAccount!.authentication;

                  final AuthCredential credential = GoogleAuthProvider.credential(
                    accessToken: googleSignInAuthentication.accessToken,
                    idToken: googleSignInAuthentication.idToken,
                  );

                  final a = await FirebaseAuth.instance.signInWithCredential(credential);


                  Navigator.pop(context);
                },
                icon: Icon(Icons.login, size: 18),
                label: Text("호산고등학교 구글 계정으로 로그인"),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await GoogleSignIn().signOut();
                  },
                  child: Text('로그아웃'))
            ],
          )
        ]),
      ),
    );
  }
}