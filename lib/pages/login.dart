import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/modules/get_device_id.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:package_info/package_info.dart';

import 'home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

final showLoginErrorDialog = (BuildContext context, http.Response response) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final msg = jsonDecode(response.body)['message'];

      return AlertDialog(
        title: Text('로그인에 실패했습니다.'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오류 메시지:'),
            SizedBox(height: 12),
            Text(
              msg,
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 12),
            Text(
              '문제가 지속될 경우 21181@hosan.hs.kr로 문의해주십시오. 위 오류 메시지를 같이 알려주시면 해결에 도움이 됩니다.',
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('닫기'),
          )
        ],
      );
    },
  );
};

class _LoginPageState extends State<LoginPage> {
  final remoteConfig = RemoteConfig.instance;
  final storage = new LocalStorage('auth.json');
  bool isLoggingIn = false;
  bool isDisposed = false;

  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }

  Future<void> doLogin() async {
    if (isLoggingIn) return;
    if (!isDisposed) {
      setState(() {
        isLoggingIn = true;
      });
    }

    try {
      // 로그인 전 초기화
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      await storage.deleteItem('AUTH_TOKEN');
      await storage.deleteItem('REFRESH_TOKEN');

      // 구글 로그인 창 표시
      final googleSignInAccount = await GoogleSignIn().signIn();

      if (googleSignInAccount == null) {
        print('Login canceled');
        return;
      }

      final googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      var rawData = remoteConfig.getAll()['BACKEND_HOST'];
      var cfgs = jsonDecode(rawData!.asString());

      final signInData =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (signInData.user == null) return;

      if (signInData.user!.email!.split('@').last != 'hosan.hs.kr') {
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

      // 디바이스 고유 식별자 불러오기
      final deviceId = await getDeviceId();
      late String? deviceName;

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName =
            '${androidInfo.brand} ${androidInfo.device} (${androidInfo.model})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }

      if (deviceId == null || deviceId.isEmpty) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('로그인 보안 오류'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '부정이용 방지를 위한 디바이스 고유 식별자(ID)를 불러오는 데 실패했습니다.',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '문제가 지속될 경우 21181@hosan.hs.kr로 문의해주십시오. 위 오류 메시지를 같이 알려주시면 해결에 도움이 됩니다.',
                      style: Theme.of(context).textTheme.caption,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('닫기'),
                  )
                ],
              );
            });
      }

      // 로그인 토큰 불러오는 엔드포인트
      final getToken = () async {
        return await http.get(
            Uri.parse(
                '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/auth/token'),
            headers: {
              'ID-Token': await signInData.user!.getIdToken(true),
              'Device-ID': deviceId ?? '',
              'Device-Name': deviceName ?? ''
            }).timeout(
          Duration(seconds: 20),
          onTimeout: () => http.Response(
            '{"message":"연결 시간 초과"}',
            403,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            },
          ),
        );
      };

      final response = await getToken();

      // 로그인 최종 진행
      final continueLogin = () async {
        final rsp = await http.get(
            Uri.parse(
                '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
            headers: {
              'ID-Token': await signInData.user!.getIdToken(true),
              'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
            });

        if (rsp.statusCode == 200) {
          await Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        } else if (rsp.statusCode == 404) {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RegisterPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        } else {
          throw Exception('Failed to load post');
        }
      };

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        storage.setItem('AUTH_TOKEN', data['token']);
        storage.setItem('REFRESH_TOKEN', data['refreshToken']);
        continueLogin();
      } else if (response.statusCode == 403 && data['code'] == 40300) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이미 로그인된 기기가 존재해요.\n이 기기로 계속할까요?',
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  SizedBox(height: 20),
                  Text(data['deviceName']),
                  Divider(height: 36),
                  Text(
                    '주의! 부정이용 방지를 위해, 계속하면 기존에 로그인된 기기는 로그아웃하고 이 기기로 로그인됩니다.',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 16),
                                child: Text("처리하는 중입니다..."),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    final respLogoutOther = await http.post(
                        Uri.parse(
                            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/auth/logout-other'),
                        headers: {
                          'ID-Token': await signInData.user!.getIdToken(true),
                        }).timeout(
                      Duration(seconds: 20),
                      onTimeout: () => http.Response(
                        '{"message":"연결 시간 초과"}',
                        403,
                        headers: {
                          HttpHeaders.contentTypeHeader:
                              'application/json; charset=utf-8',
                        },
                      ),
                    );

                    if (respLogoutOther.statusCode != 200) {
                      showLoginErrorDialog(context, respLogoutOther);
                      await FirebaseAuth.instance.signOut();
                      await GoogleSignIn().signOut();
                      return;
                    }

                    final respToken = await getToken();

                    final data = json.decode(respToken.body);
                    storage.setItem('AUTH_TOKEN', data['token']);
                    storage.setItem('REFRESH_TOKEN', data['refreshToken']);

                    continueLogin();
                  },
                  child: Text('계속하기'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('취소'),
                )
              ],
            );
          },
        );
      } else {
        showLoginErrorDialog(context, response);
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
    } finally {
      if (!isDisposed) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
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
          Text('학업 관리, 자동 출결, 내비게이션 시스템'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: doLogin,
                  icon: Icon(Icons.login, size: 18),
                  label: Text(isLoggingIn ? "로그인 중..." : "호산고등학교 구글 계정으로 로그인"),
                ),
              )
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: Text('교직원 로그인'),
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Text('개발중'),
                        );
                      });
                  return;

                  /*
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

                    DocumentSnapshot me = await firestore
                        .collection('teachers')
                        .doc(signInData.user!.uid)
                        .get();

                    if (me.exists) {
                      await Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    } else {
                      AlertDialog(
                        title: Text("존재하지 않는 교직원 계정입니다."),
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

                   */
                },
              )
            ],
          ),
          Expanded(
            child: Container(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Text('개발 및 운영: HosanDevLab\n제3기 로봇공학반 강해 이승민 황부연',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        ?.apply(fontSizeDelta: -2)),
                SizedBox(height: 4),
                FutureBuilder(
                    future: PackageInfo.fromPlatform(),
                    builder: (BuildContext context,
                        AsyncSnapshot<PackageInfo> snapshot) {
                      final data = snapshot.data;

                      return Text(
                        snapshot.hasData
                            ? '버전 ${data?.version}  |   빌드 번호 ${data?.buildNumber}'
                            : '',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .caption
                            ?.apply(fontSizeDelta: -2),
                      );
                    })
              ],
            ),
          )
        ]),
      ),
    );
  }
}
