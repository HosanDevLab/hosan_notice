import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';

class NavigationPage extends StatefulWidget {
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  int? floor;
  String roomName = '';

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _rooms;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchRooms() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('rooms').orderBy('name').get();
    return data.docs;
  }

  @override
  void initState() {
    super.initState();
    _rooms = fetchRooms();
  }

  Widget build(BuildContext context) {
    return DoubleBack(
        message: '뒤로가기를 한번 더 누르면 종료합니다.',
        child: Scaffold(
          appBar: AppBar(
            title: Text('교내 네비게이션'),
            centerTitle: true,
          ),
          body: FutureBuilder(
            future: _rooms,
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

              final rooms = snapshot.data
                  as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

              return RefreshIndicator(
                child: Container(
                    padding: EdgeInsets.all(8),
                    height: MediaQuery.of(context).size.height,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return SingleChildScrollView(
                          physics: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints.tightFor(
                                height: max(500, constraints.maxHeight)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 10),
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        Text(
                                          '현재 위치',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '1학년 8반',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(height: 24),
                                Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Text(
                                    '시설물 및 교실 찾기',
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 5),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: DropdownButtonFormField<int?>(
                                            autofocus: false,
                                            value: floor,
                                            onChanged: (newValue) {
                                              print(newValue);
                                              setState(() {
                                                floor = newValue;
                                              });
                                            },
                                            items: [
                                                  DropdownMenuItem<int?>(
                                                    child: Text('모든 층'),
                                                    value: null,
                                                  )
                                                ] +
                                                List.generate(5, (i) => i + 1)
                                                    .map((i) {
                                                  return DropdownMenuItem(
                                                      child: Text('$i층'),
                                                      value: i);
                                                }).toList(),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            keyboardType: TextInputType.text,
                                            autofocus: false,
                                            onChanged: (text) {
                                              roomName = text;
                                            },
                                            onFieldSubmitted: (text) {
                                              roomName = text;
                                            },
                                            decoration: InputDecoration(
                                              labelText: '시설 또는 교실 이름',
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Colors.deepPurple),
                                              ),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.red)),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                Expanded(
                                    child: ListView(
                                  physics: BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  children: rooms
                                      .where((e) =>
                                          (floor == null
                                              ? true
                                              : e.data()['floor'] == floor) &&
                                          (roomName.isEmpty
                                              ? true
                                              : (e.data()['name'] as String)
                                                  .contains(roomName)))
                                      .map((e) {
                                    final data = e.data();

                                    late String type;
                                    switch (data['type']) {
                                      case 'classroom':
                                        type = '교실';
                                        break;
                                    }

                                    return Card(
                                      child: ListTile(
                                        title: Text(data['name']),
                                        subtitle:
                                            Text("$type | ${data['floor']}층"),
                                        leading: Icon(
                                          Icons.class_,
                                        ),
                                        onTap: () {},
                                        minLeadingWidth: 0,
                                      ),
                                    );
                                  }).toList(),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
                onRefresh: () async {
                  final fetchFuture = fetchRooms();
                  setState(() {
                    _rooms = fetchFuture;
                  });
                  await fetchFuture;
                },
              );
            },
          ),
          drawer: MainDrawer(parentContext: context),
        ));
  }
}
