import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import '../widgets/drawer.dart';

class TeachersPage extends StatefulWidget {
  _TeachersPageState createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = RemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  final _scrollController = ScrollController();

  late Future<List<Map<dynamic, dynamic>>> _subjects, _teachers;

  Future<List<Map<dynamic, dynamic>>> fetchSubjects() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/subjects/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      data.sort((a, b) => a['order'] - b['order']);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchSubjects();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<Map<dynamic, dynamic>>> fetchTeachers() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/teachers/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchTeachers();
    } else {
      throw Exception('Failed to load post');
    }
  }

  int filterType = 0;
  String search = '';

  @override
  void initState() {
    super.initState();
    _subjects = fetchSubjects();
    _teachers = fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('선생님 찾기'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([_subjects, _teachers]),
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

          final subjects = snapshot.data[0] as List;
          final teachers = snapshot.data[1] as List;

          final filteredTeachers = teachers.where((e) {
            final searched = (e['name'] as String).contains(search);

            bool inGroup = true;
            switch (filterType) {
              case 1:
              case 2:
              case 3:
                inGroup = e['classroom']?['grade'] == filterType;
                break;
              case 4:
                inGroup = e['classroom'] == null;
                break;
              case 5:
                inGroup = e['isChief'] == true;
            }

            return searched && inGroup;
          });

          return RefreshIndicator(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Row(
                      children: [
                        DropdownButton<int>(
                          onChanged: (e) {
                            _scrollController.animateTo(
                              0,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn,
                            );
                            setState(() {
                              filterType = e!;
                            });
                          },
                          value: filterType,
                          items: [
                            DropdownMenuItem(value: 0, child: Text('전체')),
                            DropdownMenuItem(value: 1, child: Text('1학년')),
                            DropdownMenuItem(value: 2, child: Text('2학년')),
                            DropdownMenuItem(value: 3, child: Text('3학년')),
                            DropdownMenuItem(value: 4, child: Text('비담임')),
                            DropdownMenuItem(value: 5, child: Text('부장교사'))
                          ],
                          style: TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: TextStyle(fontSize: 15),
                            onChanged: (e) {
                              _scrollController.animateTo(
                                0,
                                duration: Duration(milliseconds: 500),
                                curve: Curves.fastOutSlowIn,
                              );
                              setState(() {
                                search = e;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: '선생님 검색...',
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.deepPurple),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: filteredTeachers.isNotEmpty
                      ? Scrollbar(
                          thickness: 6,
                          isAlwaysShown: true,
                          child: ListView(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            children: filteredTeachers.map((e) {
                              final cls = e['classroom'];

                              final clsStr = cls != null
                                  ? '${cls['grade']}학년 ${cls['classNum']}반 담임'
                                  : null;
                              final chiefStr = e['isChief'] ? '부장교사' : null;
                              final subjectsStr = subjects
                                  .where((s) => (e['subjects'] as List)
                                      .contains(s['_id']))
                                  .map((s) => s['name'])
                                  .toSet()
                                  .join(', ');

                              final descFirstRow = [clsStr, chiefStr]
                                  .where((e) => e != null)
                                  .join(' | ');

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    e['name'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 5),
                                      Text(
                                        descFirstRow.isNotEmpty
                                            ? descFirstRow + '\n' + subjectsStr
                                            : subjectsStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  minVerticalPadding: 10,
                                  onTap: () {},
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Align(
                          alignment: Alignment.center,
                          child: Text(
                            '검색 결과가 없습니다.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                ),
              ],
            ),
            onRefresh: () async {
              final fetchSubjectsFuture = fetchSubjects();
              final fetchTeachersFuture = fetchTeachers();
              setState(() {
                _subjects = fetchSubjectsFuture;
                _teachers = fetchTeachersFuture;
              });
              await fetchSubjectsFuture;
              await fetchTeachersFuture;
            },
          );
        },
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
