import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'classes.dart';

class MyClassPage extends StatefulWidget {
  final String? classId;

  MyClassPage({Key? key, this.classId}) : super(key: key);

  _MyClassPageState createState() => _MyClassPageState();
}

class _MyClassPageState extends State<MyClassPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  late Future<List<Map<dynamic, dynamic>>> _assignments, _classes;
  late Future<Map<dynamic, dynamic>> _me, _class, _timetable;

  late Timer _timer;

  int _currentIndex = 0;

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

  Future<List<Map<dynamic, dynamic>>> fetchClasses() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/classes/all'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchClasses();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> fetchClass() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/classes/${widget.classId ?? 'me'}'),
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
      return await fetchClass();
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<Map<dynamic, dynamic>> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final addr = widget.classId != null
        ? 'classes/${widget.classId}/timetables'
        : 'timetables/me';
    final response = await http.get(
        Uri.parse('${kReleaseMode ? cfgs['release'] : cfgs['debug']}/${addr}'),
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

  late Image image;
  int timeTableMode = 0;

  @override
  void initState() {
    super.initState();
    _me = fetchStudentsMe();
    _class = fetchClass();
    _classes = fetchClasses();
    _timetable = fetchTimetable();

    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {});
    });

    image = Image.asset('assets/class_bg_empty.jpeg',
        fit: BoxFit.fill, height: 300);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(image.image, context);
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final _pages = [
      FutureBuilder(
        future: Future.wait([_me, _class, _timetable]),
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

          final student = snapshot.data[0];
          final classroom = snapshot.data[1] as Map;
          final timetable = snapshot.data[2] as Map;

          final dow = DateTime.now().weekday;

          final tod = TimeOfDay.now();
          final inMin = tod.hour * 60 + tod.minute;

          late String currentPeriod;
          int period = 0;
          if (inMin < 8 * 60 + 20) {
            currentPeriod = '일과시간 전';
          } else if (8 * 60 + 20 <= inMin && inMin < 9 * 60 + 20) {
            period = 1;
            currentPeriod = '현재 1교시';
          } else if (9 * 60 + 20 <= inMin && inMin < 10 * 60 + 20) {
            period = 2;
            currentPeriod = '현재 2교시';
          } else if (10 * 60 + 20 <= inMin && inMin < 11 * 60 + 20) {
            period = 3;
            currentPeriod = '현재 3교시';
          } else if (11 * 60 + 20 <= inMin && inMin < 12 * 60 + 20) {
            period = 4;
            currentPeriod = '현재 4교시';
          } else if (12 * 60 + 20 <= inMin && inMin < 13 * 60 + 20) {
            currentPeriod = '점심시간';
          } else if (13 * 60 + 20 <= inMin && inMin < 14 * 60 + 20) {
            period = 5;
            currentPeriod = '현재 5교시';
          } else if (14 * 60 + 20 <= inMin && inMin < 15 * 60 + 20) {
            period = 6;
            currentPeriod = '현재 6교시';
          } else if (15 * 60 + 20 <= inMin && inMin < 16 * 60 + 20) {
            period = 7;
            currentPeriod = '현재 7교시';
          } else {
            if (dow == 6 || dow == 7) {
              currentPeriod = '';
            } else {
              currentPeriod = '일과시간 끝';
            }
          }

          final filteredTable = (timetable['table'] as List)
              .where((e) => e['dow'] == dow)
              .toList();

          return RefreshIndicator(
            edgeOffset: AppBar().preferredSize.height,
            child: Container(
              height: double.infinity,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      semanticContainer: true,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: image,
                      shape: RoundedRectangleBorder(),
                      margin: EdgeInsets.zero,
                      elevation: 6,
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${classroom['grade']}학년 ${classroom['classNum']}반',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text.rich(TextSpan(
                            children: [
                              TextSpan(
                                text: classroom['teacher']['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' 선생님 담임'),
                            ],
                            style: Theme.of(context).textTheme.caption,
                          )),
                          SizedBox(height: 8),
                          Divider(thickness: 1),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '시간표',
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              SizedBox(width: 10),
                              Text(
                                currentPeriod,
                                style: Theme.of(context).textTheme.caption,
                              ),
                              Expanded(child: Container()),
                              ToggleButtons(
                                children: [
                                  Text('오늘'),
                                  Text('전체'),
                                ],
                                onPressed: (val) {
                                  setState(() {
                                    timeTableMode = val;
                                  });
                                },
                                isSelected: [
                                  timeTableMode == 0,
                                  timeTableMode == 1
                                ],
                                borderRadius: BorderRadius.circular(10),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                constraints: BoxConstraints(
                                  minHeight: 30,
                                  minWidth: 50,
                                ),
                                textStyle: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          timeTableMode == 0
                              ? filteredTable.isNotEmpty
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ...(filteredTable
                                              ..sort((a, b) =>
                                                  a['period'] - b['period']))
                                            .map(
                                          (a) => TextButton(
                                            onPressed: () {},
                                            child: Text(
                                              a['subject']?['short_name'] ??
                                                  a['subject']?['name'] ??
                                                  '',
                                              style: period == a['period']
                                                  ? TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    )
                                                  : Theme.of(context)
                                                      .textTheme
                                                      .caption,
                                              textAlign: TextAlign.center,
                                            ),
                                            style: TextButton.styleFrom(
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        )
                                      ],
                                    )
                                  : Center(
                                      child: Text(
                                        '오늘 시간표 정보 없음',
                                        style:
                                            Theme.of(context).textTheme.caption,
                                      ),
                                    )
                              : Table(
                                  border: TableBorder.all(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.black12,
                                      width: 0.5),
                                  children: [
                                    TableRow(children: [
                                      ...['월', '화', '수', '목', '금'].map(
                                        (e) => TableCell(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: Text(
                                              e,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ]),
                                    ...List.generate(7, (i) => i + 1,
                                            growable: true)
                                        .map((e) {
                                      return TableRow(
                                        children: ((timetable['table'] as List)
                                                .where((r) => r['period'] == e)
                                                .toList()
                                              ..sort((a, b) =>
                                                  a['dow'] - b['dow']))
                                            .map(
                                              (f) => TableCell(
                                                child: InkWell(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      vertical: 8,
                                                    ),
                                                    child: Text(
                                                      f['subject']
                                                              ?['short_name'] ??
                                                          f['subject']
                                                              ?['name'] ??
                                                          '',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  onTap: () {},
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      );
                                    })
                                  ],
                                ),
                          Divider(height: 30),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '우리반 게시글',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              title: Text(
                                '테스트 게시글',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '개발중',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              dense: true,
                              onTap: () {},
                            ),
                          ),
                          Divider(height: 30),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '다가오는 생일',
                            style: Theme.of(context).textTheme.subtitle1,
                          ),
                          SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              title: Text(
                                '개발중',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '3월 18일, D${DateTime.now().difference(new DateTime(2022, 3, 18)).inDays}',
                                style: Theme.of(context).textTheme.caption,
                              ),
                              dense: true,
                              onTap: () {},
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            onRefresh: () async {
              final fetchStudentMeFuture = fetchStudentsMe();
              final fetchClassFuture = fetchClass();
              final fetchClassesFuture = fetchClasses();
              final fetchTimetableFuture = fetchTimetable();

              setState(() {
                _me = fetchStudentMeFuture;
                _class = fetchClassFuture;
                _classes = fetchClassesFuture;
                _timetable = fetchTimetableFuture;
              });

              await Future.wait([
                fetchStudentMeFuture,
                fetchClassFuture,
                fetchClassesFuture,
                fetchTimetableFuture
              ]);
            },
          );
        },
      ),
      Container(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        child: Container(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: AppBar(
                title: Text('내 학반'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
        preferredSize: Size(
          MediaQuery.of(context).size.width,
          AppBar().preferredSize.height,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _pages[_currentIndex],
      drawer: MainDrawer(parentContext: context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.format_list_bulleted),
        tooltip: '다른 반으로 이동',
        onPressed: () async {
          final classes = await _classes;
          print(classes);
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ClassesPage(context, classes: classes),
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
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '학반',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '학생',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
