import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendMonitorPage extends StatefulWidget {
  final String uid, name;
  final int grade, classNum, numberInClass;

  AttendMonitorPage({
    Key? key,
    required this.uid,
    required this.grade,
    required this.classNum,
    required this.numberInClass,
    required this.name,
  }) : super(key: key);

  @override
  _AttendMonitorPageState createState() => _AttendMonitorPageState();
}

class _AttendMonitorPageState extends State<AttendMonitorPage> {
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  late Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _attendances, _activities, _rooms;

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAttendances() async {
    QuerySnapshot<Map<String, dynamic>> data = await firestore
        .collection('attendance')
        .where('uid', isEqualTo: widget.uid)
        .get();

    final ls = data.docs;
    ls.sort((a, b) => (a.data()['attendedAt'].toDate() as DateTime)
        .difference(b.data()['attendedAt'].toDate() as DateTime)
        .inMicroseconds);
    return data.docs;
  }

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchActivities() async {
    QuerySnapshot<Map<String, dynamic>> data = await firestore
        .collection('activities')
        .where('uid', isEqualTo: widget.uid)
        .get();

    final ls = data.docs;
    ls.sort((a, b) => (a.data()['didAt'].toDate() as DateTime)
        .difference(b.data()['didAt'].toDate() as DateTime)
        .inMicroseconds);
    return ls;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchRooms() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('rooms').orderBy('name').get();
    return data.docs;
  }

  @override
  void initState() {
    super.initState();
    _attendances = fetchAttendances();
    _activities = fetchActivities();
    _rooms = fetchRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출결 및 활동'),
            Text(
                '${widget.grade}학년 ${widget.classNum}반 ${widget.numberInClass}번 ${widget.name}',
                style: Theme.of(context)
                    .textTheme
                    .subtitle2!
                    .apply(color: Colors.white))
          ],
        ),
        toolbarHeight: 70,
      ),
      body: Container(
        height: double.infinity,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: FutureBuilder(
            future: Future.wait([_attendances, _activities, _rooms]),
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

              List<QueryDocumentSnapshot<Map<String, dynamic>>> _getEventsDay(
                  DateTime day) {
                return snapshot.data[0].where((e) {
                  if (e.data()['attendedAt'] == null) return false;

                  DateTime attendedAt = e.data()['attendedAt'].toDate();

                  return attendedAt.year == day.year &&
                      attendedAt.month == day.month &&
                      attendedAt.day == day.day;
                }).toList();
              }

              final eventsDay = _getEventsDay(_selectedDay);
              final activities = snapshot.data[1]
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
              final rooms = snapshot.data[2]
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

              return RefreshIndicator(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          height: 300,
                          child: TableCalendar(
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                            ),
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
                        eventsDay.isNotEmpty
                            ? Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 5),
                                    child: Text(
                                      '활동 타임라인',
                                      style:
                                          Theme.of(context).textTheme.headline6,
                                    ),
                                  ),
                                  eventsDay.map<Widget>((e) {
                                    final data = e.data();
                                    final DateTime attendedAt =
                                        data['attendedAt'].toDate();

                                    final attendedAtStr = DateFormat('a hh:mm')
                                        .format(attendedAt)
                                        .replaceAll('AM', '오전')
                                        .replaceAll('PM', '오후');

                                    return Card(
                                      child: ListTile(
                                        title: Text(
                                          '출석',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle:
                                            Text(attendedAtStr + '에 교문 통과'),
                                        onTap: () {},
                                      ),
                                    );
                                  }).first,
                                  ...activities.where((e) {
                                    final didAt =
                                        e.data()['didAt'].toDate() as DateTime;

                                    return _selectedDay.year == didAt.year &&
                                        _selectedDay.month == didAt.month &&
                                        _selectedDay.day == didAt.day;
                                  }).map<Widget>((e) {
                                    final activity = e.data();
                                    final activityRoom = rooms.firstWhere((e) =>
                                        e.id ==
                                        (activity['room'] as DocumentReference<
                                                Map<String, dynamic>>)
                                            .id);

                                    final data = e.data();
                                    final DateTime didAt =
                                        data['didAt'].toDate();

                                    final didAtStr = DateFormat('a hh:mm')
                                        .format(didAt)
                                        .replaceAll('AM', '오전')
                                        .replaceAll('PM', '오후');

                                    return Card(
                                      child: ListTile(
                                        leading: Icon(
                                          activity['type'] == 'in'
                                              ? Icons.login
                                              : Icons.logout,
                                          color: activity['type'] == 'in'
                                              ? Colors.lightBlue
                                              : Colors.deepOrange,
                                        ),
                                        horizontalTitleGap: 0,
                                        title: Text(activityRoom['name']),
                                        subtitle: Text(
                                          didAtStr +
                                              ' | ' +
                                              (activity['type'] == 'in'
                                                  ? '입실'
                                                  : '퇴실'),
                                        ),
                                        onTap: () {},
                                      ),
                                    );
                                  }),
                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Text(
                                      '* 사용자 네트워크 상황에 따라 출결 또는 활동 내역이 기록되지 않을 수 있음에 유의하십시오.',
                                      style:
                                          Theme.of(context).textTheme.caption,
                                    ),
                                  )
                                ],
                              )
                            : Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Text(
                                    '이날 출석 정보가 없습니다!',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  onRefresh: () async {
                    final fetchAttendancesFuture = fetchAttendances();
                    final fetchRoomsFuture = fetchRooms();
                    final fetchActivitiesFuture = fetchActivities();
                    setState(() {
                      _attendances = fetchAttendancesFuture;
                      _rooms = fetchRoomsFuture;
                      _activities = fetchActivitiesFuture;
                    });

                    await Future.wait([
                      fetchAttendancesFuture,
                      fetchRoomsFuture,
                      fetchActivitiesFuture
                    ]);
                  });
            },
          ),
        ),
      ),
    );
  }
}
