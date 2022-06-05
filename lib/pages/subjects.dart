import 'dart:convert';

import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import '../widgets/drawer.dart';

class SubjectsPage extends StatefulWidget {
  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage>
    with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  late TabController _tabController;

  late Future<List<Map<dynamic, dynamic>>> _assignments;
  late Future<Map<dynamic, dynamic>> _me;

  Future<Map<dynamic, dynamic>> fetchStudentsMe() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      (data['subjects']['1st'] as List).sort((a, b) => a['order'] - b['order']);
      (data['subjects']['2nd'] as List).sort((a, b) => a['order'] - b['order']);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchStudentsMe();
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _me = fetchStudentsMe();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('내 수강 과목'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: '1학기',
              ),
              Tab(
                text: '2학기'
              ),
            ],
          ),
        ),
        body: FutureBuilder(
          future: _me,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurple),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('불러오는 중', textAlign: TextAlign.center),
                    )
                  ],
                ),
              );
            }

            final student = snapshot.data;

            return RefreshIndicator(
              child: Container(
                height: double.infinity,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Center(
                      child: Text("ㅁㄴㅇㄹ"),
                    ),
                    Center(
                      child: Text("asdf"),
                    ),
                  ],
                ),
              ),
              onRefresh: () async {
                final fetchStudentMeFuture = fetchStudentsMe();
                setState(() {
                  _me = fetchStudentsMe();
                });
                await fetchStudentMeFuture;
              },
            );
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
