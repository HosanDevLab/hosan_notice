import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'assignment.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _assignments,
      _subjects;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAssignments() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('assignments').orderBy('deadline').get();
    final ls = data.docs.toList();
    ls.sort((a, b) => a.data()['deadline'] == null ? 1 : 0);
    return ls;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchSubjects() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('subjects').orderBy('order').get();
    final ls = data.docs.toList();
    return ls;
  }

  @override
  void initState() {
    super.initState();
    _assignments = fetchAssignments();
    _subjects = fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('한눈에 보는 일정표'),
          centerTitle: true,
        ),
        body: Container(
          height: double.infinity,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: FutureBuilder(
              future: Future.wait([_assignments, _subjects]),
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
                      ]));
                }

                Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>
                    _getEventsDay(DateTime day) {
                  return snapshot.data[0].where((e) {
                    if (e.data()['deadline'] == null) return false;

                    DateTime deadline = e.data()['deadline'].toDate();

                    return deadline.year == day.year &&
                        deadline.month == day.month &&
                        deadline.day == day.day;
                  });
                }

                final eventsDay = _getEventsDay(_selectedDay);

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
                                final data = e.data();
                                final DateTime? deadline =
                                    data['deadline'] == null
                                        ? null
                                        : data['deadline'].toDate();

                                final deadlineStr = deadline == null
                                    ? '기한 없음'
                                    : DateFormat('a hh:mm 까지')
                                        .format(deadline)
                                        .replaceAll('AM', '오전')
                                        .replaceAll('PM', '오후');

                                return Card(
                                  child: ListTile(
                                    title: Text(data['title']),
                                    subtitle: Text((snapshot.data[1] as List)
                                            .firstWhere((e) =>
                                                data['subject'].id ==
                                                e.id)['name'] +
                                        ' ${data['teacher'] ?? ''} | ' +
                                        deadlineStr),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AssignmentPage(
                                              assignmentId: e.id),
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
                                  child: Text('이날 마감되는 과제가 없습니다!',
                                      style:
                                          TextStyle(color: Colors.grey[700]))),
                            ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
