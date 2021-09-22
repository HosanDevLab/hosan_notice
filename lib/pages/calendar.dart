import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:table_calendar/table_calendar.dart';

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

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _assignments;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchAssignments() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('assignments').orderBy('deadline').get();
    final ls = data.docs.toList();
    ls.sort((a, b) => a.data()['deadline'] == null ? 1 : 0);
    return ls;
  }

  @override
  void initState() {
    super.initState();
    _assignments = fetchAssignments();
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
        body: RefreshIndicator(
          child: Container(
            height: double.infinity,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: FutureBuilder(
                  future: _assignments,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    print('asd');
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    return Column(
                      children: <Widget>[
                        TableCalendar(
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
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          onRefresh: () async {
            final fetchFuture = fetchAssignments();
            setState(() {
              _assignments = fetchFuture;
            });
            await Future.wait([fetchFuture]);
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
