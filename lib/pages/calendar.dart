import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:intl/intl.dart';
import 'package:localstorage/localstorage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import '../modules/refresh_token.dart';
import 'assignment.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final remoteConfig = FirebaseRemoteConfig.instance;
  final storage = new LocalStorage('auth.json');

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late Future<List<Map<dynamic, dynamic>>> _assignments, _teachers;

  Future<List<Map<dynamic, dynamic>>> fetchAssignments() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/assignments'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      data.sort((a, b) => a['deadline'] == null ? 1 : 0);
      return List.from(data);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchAssignments();
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

  @override
  void initState() {
    super.initState();
    _assignments = fetchAssignments();
    _teachers = fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('한눈에 보는 일정표'),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: FutureBuilder(
            future: Future.wait([_assignments, _teachers]),
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

              Iterable<Map> _getEventsDay(DateTime day) {
                return snapshot.data[0].where((e) {
                  if (e['deadline'] == null) return false;

                  final deadline = DateTime.parse(e['deadline']);

                  return deadline.year == day.year &&
                      deadline.month == day.month &&
                      deadline.day == day.day;
                });
              }

              final eventsDay = _getEventsDay(_selectedDay);

              final teachers = snapshot.data[1];

              return Column(
                children: <Widget>[
                  SizedBox(
                    height: 350,
                    child: TableCalendar(
                      headerStyle: HeaderStyle(formatButtonVisible: false),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        weekendTextStyle:
                            TextStyle().copyWith(color: Colors.red),
                        holidayTextStyle:
                            TextStyle().copyWith(color: Colors.blue[800]),
                      ),
                      eventLoader: (day) {
                        return _getEventsDay(day).toList();
                      },
                      shouldFillViewport: true,
                      locale: 'ko_KR',
                      focusedDay: _focusedDay,
                      firstDay: DateTime(2010),
                      lastDay: DateTime(2050),
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDay),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: eventsDay.length > 0
                        ? ListView(
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            children: eventsDay.map((e) {
                              final DateTime? deadline = e['deadline'] == null
                                  ? null
                                  : DateTime.parse(e['deadline']);

                              final deadlineStr = deadline == null
                                  ? '기한 없음'
                                  : DateFormat('a hh:mm 까지')
                                      .format(deadline)
                                      .replaceAll('AM', '오전')
                                      .replaceAll('PM', '오후');

                              return Card(
                                child: ListTile(
                                  title: Text(e['title']),
                                  subtitle: Text(e['subject']['name'] +
                                      ' ' +
                                      (teachers.firstWhere(
                                            (t) => t['_id'] == e['teacher'],
                                            orElse: () => {},
                                          )['name'] ??
                                          '') +
                                      ' | ' +
                                      deadlineStr),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AssignmentPage(
                                            assignmentId: e['_id']),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          )
                        : Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: EdgeInsets.only(bottom: 20),
                              child: Text(
                                '이날 마감되는 과제가 없습니다!',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                  )
                ],
              );
            },
          ),
        ),
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
