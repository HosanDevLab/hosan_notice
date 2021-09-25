import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/widgets/drawer.dart';

class ToiletPaperStatusPage extends StatefulWidget {
  @override
  _ToiletPaperStatusPageState createState() => _ToiletPaperStatusPageState();
}

class _ToiletPaperStatusPageState extends State<ToiletPaperStatusPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  late Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _toiletPapers;

  Future<Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>>
      fetchToiletPapers() async {
    QuerySnapshot<Map<String, dynamic>> data =
        await firestore.collection('toilet_paper').get();
    return data.docs;
  }

  @override
  void initState() {
    _toiletPapers = fetchToiletPapers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
      message: '뒤로가기를 한번 더 누르면 종료합니다.',
      child: Scaffold(
        appBar: AppBar(
          title: Text('화장실 휴지 현황'),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: _toiletPapers,
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

            return RefreshIndicator(
              child: Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('화장실 휴지 현황',
                            style: Theme.of(context).textTheme.headline6),
                        SizedBox(height: 6),
                        Text(
                            '신성한 화장실에서, 대자연의 순환에 영속되기 위해서는 휴지라는 매개체가 필수적입니다. 자연과 하나가 될 수 있도록 도와드리겠습니다.'),
                        Divider(height: 24),
                        Column(
                          children: (snapshot.data as List).map((e) {
                            final data = e.data();
                            final manPercent = data['man'];
                            final womanPercent = data['woman'];

                            final manStatus = manPercent >= 60 ? "양호" : manPercent >= 30 ? "보통" : "부족" ;
                            final womanStatus = womanPercent >= 60 ? "양호" : womanPercent >= 30 ? "보통" : "부족" ;

                            final manColor = manPercent >= 60 ? Colors.green[600] : manPercent >= 30 ? Colors.orange : Colors.red ;
                            final womanColor = womanPercent >= 60 ? Colors.green[600] : womanPercent >= 30 ? Colors.orange : Colors.red ;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('1학년 후편 화장실 (6반~8반)',
                                        style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(width: 8),
                                    Icon(Icons.male),
                                    Text('남자화장실',
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1),
                                    SizedBox(width: 6),
                                    Text(manStatus,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .apply(
                                                color: manColor,
                                                fontWeightDelta: 100)),
                                    SizedBox(width: 5),
                                    Text('($manPercent%)')
                                  ],
                                ),
                                SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(width: 8),
                                    Icon(Icons.female),
                                    Text('여자화장실',
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1),
                                    SizedBox(width: 6),
                                    Text(womanStatus,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .apply(
                                                color: womanColor,
                                                fontWeightDelta: 100)),
                                    SizedBox(width: 5),
                                    Text('($womanPercent%)')
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        Divider(height: 24),
                        Text('현재 이 기능은 테스트 중입니다. 1학년 6반~8반 화장실만 확인할 수 있습니다.',
                            style: Theme.of(context).textTheme.caption)
                      ],
                    ),
                  ),
                ),
              ),
              onRefresh: () async {
                final fetchFuture = fetchToiletPapers();
                setState(() {
                  _toiletPapers = fetchFuture;
                });
                await Future.wait([fetchFuture]);
              },
            );
          },
        ),
        drawer: MainDrawer(parentContext: context),
      ),
    );
  }
}
