import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'login.dart';

Future showDevelopingToast() async {
  await Fluttertoast.cancel();
  await Fluttertoast.showToast(
    msg: "알림 설정은 개발중입니다!",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.pink,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');
  final firestore = FirebaseFirestore.instance;
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String? idToken;

  Future<Map<dynamic, dynamic>> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/timetables/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTimetable();
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        centerTitle: true,
      ),
      body: Container(
        child: ListView(
          physics:
          BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('일반'),
                ),
                Expanded(child: Divider())
              ],
            ),
            ListTile(
              title: Text('로그아웃'),
              subtitle: Text(
                '현재 계정에서 로그아웃하고, 로그인 화면으로 이동합니다.',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text('로그아웃할까요?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('계속하기'),
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
                          child: Text('취소'),
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
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('알림'),
                ),
                Expanded(child: Divider())
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Transform.translate(
                offset: Offset(8, 0),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: true,
                  onChanged: (value) {
                    showDevelopingToast();
                    // TODO: 알림 설정
                  },
                ),
              ),
              title: Text(
                '새 과제 등록시 알림',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                showDevelopingToast();
                // TODO: 알림 설정
              },
            ),
            Divider(height: 0),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Transform.translate(
                offset: Offset(8, 0),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: true,
                  onChanged: (value) {
                    showDevelopingToast();
                    // TODO: 알림 설정
                  },
                ),
              ),
              title: Text(
                '과제 마감 24시간 전에 알림',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                showDevelopingToast();
                // TODO: 알림 설정
              },
            ),
            Divider(height: 0),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Transform.translate(
                offset: Offset(8, 0),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: true,
                  onChanged: (value) {
                    showDevelopingToast();
                    // TODO: 알림 설정
                  },
                ),
              ),
              title: Text(
                '내가 등록한 과제에 댓글 등록시 알림',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                showDevelopingToast();
                // TODO: 알림 설정
              },
            ),
            Divider(height: 0),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Transform.translate(
                offset: Offset(8, 0),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: true,
                  onChanged: (value) {
                    showDevelopingToast();
                    // TODO: 알림 설정
                  },
                ),
              ),
              title: Text(
                '내가 등록한 과제에 좋아요가 달렸을 때 알림',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                showDevelopingToast();
                // TODO: 알림 설정
              },
            ),
            Divider(height: 0),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              dense: true,
              leading: Transform.translate(
                offset: Offset(8, 0),
                child: Checkbox(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: false,
                  onChanged: (value) {
                    showDevelopingToast();
                    // TODO: 알림 설정
                  },
                ),
              ),
              title: Text(
                '점심시간 1시간 전에 급식 메뉴 알림',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                showDevelopingToast();
                // TODO: 알림 설정
              },
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
