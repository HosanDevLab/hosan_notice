import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hosan_notice/modules/get_device_id.dart';
import 'package:hosan_notice/widgets/drawer.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;

class MealInfoPage extends StatefulWidget {
  @override
  _MealInfoPageState createState() => _MealInfoPageState();
}

class _MealInfoPageState extends State<MealInfoPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final storage = new LocalStorage('auth.json');
  final firestore = FirebaseFirestore.instance;
  final remoteConfig = RemoteConfig.instance;
  final refreshKey = GlobalKey<RefreshIndicatorState>();

  final _scrollController = ScrollController();
  final _pageController = PageController(viewportFraction: 0.95);

  late Future<Map<dynamic, dynamic>> _mealInfo;

  Future<Map<dynamic, dynamic>> fetchMealInfo() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/meal-info'),
        headers: {
          'ID-Token': await user.getIdToken(true),
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      final response = await http.get(
          Uri.parse(
              '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/auth/refresh'),
          headers: {
            'ID-Token': await user.getIdToken(true),
            'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
            'Refresh-Token': storage.getItem('REFRESH_TOKEN') ?? '',
            'Device-ID': await getDeviceId() ?? ''
          });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.setItem('AUTH_TOKEN', data['token']);
        await storage.setItem('REFRESH_TOKEN', data['refreshToken']);
        return await fetchMealInfo();
      } else {
        throw Exception('Failed to refresh token');
      }
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  void initState() {
    super.initState();
    _mealInfo = fetchMealInfo();
  }

  Widget mealCard(BuildContext context, dynamic data) {
    final String rawDt = data['MLSV_YMD'];
    final dt = DateTime(int.parse(rawDt.substring(0, 4)),
        int.parse(rawDt.substring(4, 6)), int.parse(rawDt.substring(6, 8)));

    final now = DateTime.now();
    final diffDays =
        dt.difference(DateTime(now.year, now.month, now.day)).inDays;

    final dayofWeek = ['월', '화', '수', '목', '금', '토', ' 일'][dt.weekday - 1];

    return Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                    diffDays == 0
                        ? '오늘'
                        : diffDays == 1
                            ? '내일'
                            : diffDays == 2
                                ? '모레'
                                : '${dt.month}월 ${dt.day}일 ($dayofWeek)',
                    style: TextStyle(fontSize: 22)),
                SizedBox(height: 24, child: Divider()),
                Expanded(
                    child: Scrollbar(
                  isAlwaysShown: true,
                  controller: _scrollController,
                  child: ListView(
                    physics: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    children:
                        (data['DDISH_NM'] as String).split('<br/>').map((e) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Text(e.replaceAll(RegExp(r'\d+\.'), ''),
                            style: TextStyle(fontSize: 26),
                            textAlign: TextAlign.center),
                      );
                    }).toList(),
                  ),
                )),
                SizedBox(height: 28, child: Divider()),
                Text(data['CAL_INFO'], style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text((data['NTR_INFO'] as String).replaceAll('<br/>', ', '),
                    style: TextStyle(color: Colors.grey[600]))
              ],
            ),
          ),
          onTap: () {},
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('급식 메뉴'),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: FutureBuilder(
            future: _mealInfo,
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

              final mealRows =
                  snapshot.data['mealServiceDietInfo'][1]['row'] as List;
              final selectableDtsList = mealRows.map((e) {
                final String rawDt = e['MLSV_YMD'];
                final dt = DateTime(
                    int.parse(rawDt.substring(0, 4)),
                    int.parse(rawDt.substring(4, 6)),
                    int.parse(rawDt.substring(6, 8)));
                return dt;
              }).toList();
              final selectableDts = selectableDtsList.toSet();

              final mainWidget = Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                            onPressed: () {
                              _pageController.animateToPage(0,
                                  duration: Duration(seconds: 1),
                                  curve: Curves.easeOutExpo);
                            },
                            icon: Icon(Icons.restore),
                            label: Text('최근으로')),
                        SizedBox(width: 10),
                        OutlinedButton(
                            style:
                                TextButton.styleFrom(minimumSize: Size(0, 35)),
                            onPressed: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectableDts.first,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2050),
                                  selectableDayPredicate: (datetime) =>
                                      selectableDts
                                          .where((e) => datetime == e)
                                          .length >
                                      0);

                              if (date == null) return;

                              _pageController.animateToPage(
                                  selectableDtsList
                                      .indexWhere((e) => date == e),
                                  duration: Duration(seconds: 1),
                                  curve: Curves.easeOutExpo);
                            },
                            child: Icon(Icons.event_note)),
                        Expanded(
                          child: Container(),
                        ),
                        TextButton(
                            style:
                                TextButton.styleFrom(minimumSize: Size(0, 0)),
                            onPressed: () {
                              if (_pageController.page! < 0.5) return;
                              _pageController.previousPage(
                                  duration: Duration(seconds: 1),
                                  curve: Curves.easeOutExpo);
                            },
                            child: Icon(Icons.arrow_back)),
                        TextButton(
                            style:
                                TextButton.styleFrom(minimumSize: Size(0, 0)),
                            onPressed: () {
                              if (_pageController.page! > mealRows.length - 1.5)
                                return;
                              _pageController.nextPage(
                                  duration: Duration(seconds: 1),
                                  curve: Curves.easeOutExpo);
                            },
                            child: Icon(Icons.arrow_forward))
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      physics: BouncingScrollPhysics(),
                      controller: _pageController,
                      onPageChanged: (index) {},
                      children: mealRows
                          .map((e) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 5),
                              child: mealCard(context, e)))
                          .toList(),
                    ),
                  )
                ],
              );

              return RefreshIndicator(
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        return SingleChildScrollView(
                          controller: _scrollController,
                          physics: BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          child: ConstrainedBox(
                              constraints: BoxConstraints.tightFor(
                                  height: max(500, constraints.maxHeight)),
                              child: mainWidget),
                        );
                      },
                    ),
                  ),
                  onRefresh: () async {
                    final fetchMealInfoFuture = fetchMealInfo();
                    setState(() {
                      _mealInfo = fetchMealInfoFuture;
                    });
                    await _mealInfo;
                  });
            },
          ),
        ),
      ),
      drawer: MainDrawer(parentContext: context),
    );
  }
}
