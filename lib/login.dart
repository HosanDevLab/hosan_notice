import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/main.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('호산고 알리미 로그인'),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: Container()),
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
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();

                  final GoogleSignInAccount? googleSignInAccount =
                      await GoogleSignIn().signIn();
                  final GoogleSignInAuthentication googleSignInAuthentication =
                      await googleSignInAccount!.authentication;

                  final AuthCredential credential =
                      GoogleAuthProvider.credential(
                    accessToken: googleSignInAuthentication.accessToken,
                    idToken: googleSignInAuthentication.idToken,
                  );

                  final signInData = await FirebaseAuth.instance
                      .signInWithCredential(credential);

                  if (signInData.user!.email!.split('@').last !=
                      'hosan.hs.kr') {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: new Text("호산고 계정이 아닙니다."),
                            content: new Text("호산고등학교에서 발급한 Google 계정\n(숫자@hosan.hs.kr)으로 로그인하세요!\n\n계정을 잊어버리셨다면 선생님께 문의해주세요."),
                            actions: <Widget>[
                              new TextButton(
                                child: new Text("닫기"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        });
                    return;
                  }

                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => HomePage()));
                },
                icon: Icon(Icons.login, size: 18),
                label: Text("호산고등학교 구글 계정으로 로그인"),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('개발 및 운영: 호산고 제3기 로봇공학반\n2021 강해 이승민 황부연',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.caption),
          )
        ]),
      ),
    );
  }
}
