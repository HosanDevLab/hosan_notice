import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/main.dart';
import 'package:hosan_notice/register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoggingIn = false;
  bool isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

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
          SizedBox(height: 5),
          Text('학업 알림 및 휴지 현황 시스템'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (isLoggingIn) return;
                    if (!isDisposed) {
                      setState(() {
                        isLoggingIn = true;
                      });
                    }

                    try {
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();

                      final GoogleSignInAccount? googleSignInAccount =
                          await GoogleSignIn().signIn();
                      final GoogleSignInAuthentication
                          googleSignInAuthentication =
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
                                title: Text("호산고 계정이 아닙니다."),
                                content: Text(
                                    "호산고등학교에서 발급한 Google 계정 (숫자@hosan.hs.kr)으로 로그인하세요!\n\n계정을 잊어버리셨다면 선생님께 문의해주세요."),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text("닫기"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            });
                        return;
                      }

                      CollectionReference students =
                          firestore.collection('students');

                      DocumentSnapshot me =
                          await students.doc(signInData.user!.uid).get();

                      if (me.exists) {
                        await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()));
                      } else {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Register()));
                      }
                    } catch (e) {
                      throw e;
                    } finally {
                      if (!isDisposed) {
                        setState(() {
                          isLoggingIn = false;
                        });
                      }
                    }
                  },
                  icon: Icon(Icons.login, size: 18),
                  label: Text(isLoggingIn ? "로그인 중..." : "호산고등학교 구글 계정으로 로그인"),
                ),
              )
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [TextButton(onPressed: () {}, child: Text('교직원 로그인'))],
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
