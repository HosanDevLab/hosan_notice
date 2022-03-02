import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../messages.dart';
import 'path_search.dart';

class NavigationPage extends StatefulWidget {
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  final api = Api();
  late Future<List<MinewBeaconData?>> _scannedBeacons;
  late Timer _timer;

  int? floor;
  String roomName = '';

  late Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _rooms,
      _beacons;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchRooms() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('rooms').orderBy('name').get();
    return data.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchBeacons() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('beacons').get();
    return data.docs;
  }

  @override
  void initState() {
    super.initState();
    _rooms = fetchRooms();
    _beacons = fetchBeacons();

    _scannedBeacons = api.getScannedBeacons();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _scannedBeacons = api.getScannedBeacons();
      });
    });
    () async {
      await Permission.location.request();
      await api.startScan();
    }();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('교내 내비게이션'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Future.wait([_rooms, _beacons, _scannedBeacons]),
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

          final rooms = snapshot.data[0]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
          final beacons = snapshot.data[1]
              as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
          final beaconUUIDs = beacons.map((e) => e.id);
          final scannedBeacons = snapshot.data[2] as List<MinewBeaconData?>;
          final currentBeacons = scannedBeacons
              .where((e) => beaconUUIDs.contains(e!.uuid))
              .toList();
          currentBeacons.sort((a, b) => a!.rssi! - b!.rssi!);

          final currentBeaconFBData = currentBeacons.length > 0
              ? beacons.firstWhere((e) => e.id == currentBeacons.first!.uuid)
              : null;

          final navigateListBody = (currentBeaconFBData != null
              ? [
                  Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 5),
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
                                  List.generate(5, (i) => i + 1).map((i) {
                                    return DropdownMenuItem(
                                        child: Text('$i층'), value: i);
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
                                  borderSide:
                                      BorderSide(color: Colors.deepPurple),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(color: Colors.red)),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
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
                                    .contains(roomName)) &&
                            (['stairs'].contains(e.data()['type']) != true))
                        .map((e) {
                      final data = e.data();

                      late String type;
                      late Icon? icon;
                      switch (data['type']) {
                        case 'classroom':
                          type = '교실';
                          icon = Icon(Icons.class_);
                          break;
                        case 'stairs':
                          type = '계단';
                          icon = Icon(Icons.stairs);
                          break;
                        case 'office':
                          type = '교무실/사무실';
                          icon = Icon(Icons.business);
                          break;
                        case 'multimedia':
                          type = "컴퓨터실";
                          icon = Icon(Icons.monitor);
                          break;
                        case 'library':
                          type = '도서관';
                          icon = Icon(Icons.library_books);
                          break;
                        case 'lecture':
                          type = '강당';
                          icon = Icon(Icons.sports_volleyball);
                          break;
                        case 'broadcasting':
                          type = '방송';
                          icon = Icon(Icons.podcasts);
                          break;
                        default:
                          type = '';
                          icon = null;
                      }

                      final startRoomId = currentBeaconFBData.data()['room'].id;

                      return Card(
                        child: ListTile(
                          title: Text(
                            '${data['name']} ${startRoomId == e.id ? "(현재 위치)" : ""}',
                            style: TextStyle(
                              color:
                                  startRoomId == e.id ? Colors.grey[500] : null,
                            ),
                          ),
                          subtitle: Text(
                            "$type | ${data['floor']}층",
                          ),
                          leading: icon != null ? icon : null,
                          onTap: () {
                            if (startRoomId == e.id) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PathSearchPage(
                                  startRoomId: startRoomId,
                                  destRoomId: e.id,
                                  rooms: rooms,
                                ),
                              ),
                            );
                          },
                          minLeadingWidth: 0,
                        ),
                      );
                    }).toList(),
                  )),
                ]
              : [
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Text(
                      '내비게이션 기능을 사용하려면 먼저 현재 위치가 감지되어야 합니다.',
                    ),
                  )
                ]);

          return RefreshIndicator(
            child: Container(
                padding: EdgeInsets.all(8),
                height: MediaQuery.of(context).size.height,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return SingleChildScrollView(
                      physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints.tightFor(
                          height: max(500, constraints.maxHeight),
                        ),
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
                                    currentBeaconFBData != null
                                        ? Text(
                                            currentBeaconFBData.data()['name'],
                                            style: TextStyle(fontSize: 28),
                                          )
                                        : Column(
                                            children: [
                                              Text(
                                                '감지되지 않음',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                '* 학교 건물 밖이거나 비콘 신호 사각지대일 수 있습니다.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .caption,
                                              ),
                                            ],
                                          )
                                  ],
                                ),
                              ),
                            ),
                            Divider(height: 24),
                            Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                '시설물 및 교실 찾기',
                                style: Theme.of(context).textTheme.headline5,
                              ),
                            ),
                            SizedBox(height: 5),
                            ...navigateListBody
                          ],
                        ),
                      ),
                    );
                  },
                )),
            onRefresh: () async {
              final fetchRoomsFuture = fetchRooms();
              final fetchBeaconsFuture = fetchBeacons();
              setState(() {
                _rooms = fetchRoomsFuture;
                _beacons = fetchBeaconsFuture;
              });
              await Future.wait([fetchBeaconsFuture, fetchRoomsFuture]);
            },
          );
        },
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
