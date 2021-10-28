import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class MyAttendancePage extends StatefulWidget {
  @override
  _MyAttendancePageState createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _attendances;

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAttendances() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('attendance').get();
    return data.docs;
  }

  @override
  void initState() {
    super.initState();
    _attendances = fetchAttendances();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('내 출결 및 활동'),
          centerTitle: true,
        ),
        body: Container(
          height: double.infinity,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: FutureBuilder(
              future: _attendances,
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
                  return snapshot.data.where((e) {
                    if (e.data()['attendedAt'] == null) return false;

                    DateTime attendedAt = e.data()['attendedAt'].toDate();

                    return attendedAt.year == day.year &&
                        attendedAt.month == day.month &&
                        attendedAt.day == day.day;
                  });
                }

                final eventsDay = _getEventsDay(_selectedDay);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(8, 16, 8, 5),
                      child: Text(
                          '나의 출석 상황과 학교내 대략적인 위치가 실시간으로 기록됩니다. 다른 학생에게 공개되지 않으니 안심하세요!'),
                    ),
                    Divider(),
                    SizedBox(
                      height: 300,
                      child: TableCalendar(
                        headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            headerPadding: EdgeInsets.zero),
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
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                  child: Text(
                                    '활동 타임라인',
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                ),
                                ...eventsDay.map<Widget>((e) {
                                  final data = e.data();
                                  final DateTime attendedAt =
                                      data['attendedAt'].toDate();

                                  final deadlineStr = DateFormat('a hh:mm')
                                      .format(attendedAt)
                                      .replaceAll('AM', '오전')
                                      .replaceAll('PM', '오후');

                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          '${attendedAt.month}월 ${attendedAt.day}일'),
                                      subtitle: Text(deadlineStr + '에 교문 통과'),
                                      onTap: () {},
                                    ),
                                  );
                                }),
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text(
                                    '* 사용자 네트워크 상황에 따라 출결 또는 활동 내역이 기록되지 않을 수 있음에 유의하십시오.',
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                )
                              ],
                            )
                          : Align(
                              alignment: Alignment.center,
                              child: Container(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text('이날 출석 정보가 없습니다!',
                                      style:
                                          TextStyle(color: Colors.grey[700]))),
                            ),
                    ),
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
