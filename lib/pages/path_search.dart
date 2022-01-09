import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PathSearchPage extends StatefulWidget {
  final String startRoomId;
  final String destRoomId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms;

  PathSearchPage(
      {Key? key,
      required this.startRoomId,
      required this.destRoomId,
      required this.rooms})
      : super(key: key);

  @override
  _PathSearchPageState createState() => _PathSearchPageState();
}

class _PathSearchPageState extends State<PathSearchPage> {
  late String startRoomId, destRoomId;

  @override
  void initState() {
    super.initState();
    setState(() {
      startRoomId = widget.startRoomId;
      destRoomId = widget.destRoomId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('시설 경로 탐색'),
      ),
      body: RefreshIndicator(
        child: Container(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
            height: MediaQuery.of(context).size.height,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final startRoom =
                    widget.rooms.where((e) => e.id == startRoomId);
                final destRoom = widget.rooms.where((e) => e.id == destRoomId);

                final Map<String, Map<String, int>> graph = {};

                // 노드 그래프 생성
                for (var room in widget.rooms) {
                  final List? connections = room.data()['connections'];
                  if (connections == null || connections.isEmpty) continue;

                  graph[room.id] = {};
                  for (var connection in room.data()['connections'] ?? []) {
                    final DocumentReference<Map<String, dynamic>> nodeRoomRef =
                        connection['node'];
                    final nodeRoomId = nodeRoomRef.id;
                    final nodeDistance = connection['distance'];

                    graph[room.id]![nodeRoomId] = nodeDistance;
                  }
                }

                var routing = {};
                for (var node in graph.keys) {
                  routing[node] = {
                    'shortestDist': 0,
                    'route': [],
                    'visited': 0
                  };
                }

                void visitNode(String node) {
                  routing[node]['visited'] = 1;
                  for (var oneGraph in graph[node]!.entries) {
                    final toGo = oneGraph.key;
                    final betweenDist = oneGraph.value;
                    print('$node -> $toGo');
                    final toDist = routing[node]['shortestDist'] + betweenDist;
                    if ((routing[toGo]['shortestDist'] >= toDist) ||
                        routing[toGo]['route'].isEmpty) {
                      routing[toGo]['shortestDist'] = toDist;
                      routing[toGo]['route'] =
                          List.from(routing[node]['route']);
                      routing[toGo]['route'].add(node);
                    }
                  }
                }

                visitNode(startRoomId);

                while (true) {
                  final routingShortestDists =
                      routing.values.map((e) => e['shortestDist']).toList();
                  routingShortestDists.sort((a, b) => b - a);
                  var minDist = routingShortestDists.first;
                  String? toVisit;

                  for (var oneRouting in routing.entries) {
                    final name = oneRouting.key;
                    final search = oneRouting.value;
                    if (0 < search['shortestDist'] &&
                        search['shortestDist'] <= minDist &&
                        search['visited'] == 0) {
                      minDist = search['shortestDist'];
                      toVisit = name;
                    }
                  }

                  if (toVisit == null) break;

                  visitNode(toVisit);
                }

                final trace = routing[destRoomId]['route'];
                print(trace);

                return FutureBuilder(future: () async {
                  await Future.delayed(Duration(milliseconds: 1000));
                  return true;
                }(), builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.deepPurple),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text('경로 탐색 중', textAlign: TextAlign.center),
                          )
                        ],
                      ),
                    );
                  }

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
                                  vertical: 16,
                                  horizontal: 12,
                                ),
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '다음과 같이 최단경로를 탐색합니다.',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Divider(height: 20),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '출발: ${startRoom.isNotEmpty ? startRoom.first.data()['name'] : ''}',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          '도착: ${destRoom.isNotEmpty ? destRoom.first.data()['name'] : ''}',
                                          style: TextStyle(fontSize: 18),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(),
                            Container(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "최단 경로",
                                style: Theme.of(context).textTheme.headline6,
                              ),
                            ),
                            Expanded(
                                child: Scrollbar(
                              isAlwaysShown: true,
                              child: ListView(
                                children: [
                                  Card(
                                    elevation: 1.5,
                                    child: ListTile(
                                      leading: RotationTransition(
                                        turns: AlwaysStoppedAnimation(90 / 360),
                                        child: Icon(Icons.play_arrow),
                                      ),
                                      horizontalTitleGap: 0,
                                      title: Text(
                                        "${startRoom.first.data()['name']} 출발",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...trace.sublist(1).map((e) {
                                    final room = widget.rooms
                                        .firstWhere((r) => r.id == e);
                                    return Card(
                                      elevation: 1.5,
                                      child: ListTile(
                                          leading: Icon(
                                            room['type'] == 'stairs'
                                                ? Icons.stairs
                                                : Icons.keyboard_arrow_down,
                                          ),
                                          horizontalTitleGap: 0,
                                          title: RichText(
                                            text: TextSpan(
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    text: room.data()['name'],
                                                  ),
                                                  TextSpan(text: ' 으(로) 이동하세요.')
                                                ]),
                                          )),
                                    );
                                  }),
                                  Card(
                                    elevation: 1.5,
                                    child: ListTile(
                                      leading: Icon(Icons.check_circle),
                                      horizontalTitleGap: 0,
                                      title: Text(
                                        "${destRoom.first.data()['name']} 도착",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ));
                });
              },
            )),
        onRefresh: () async {},
      ),
    );
  }
}
