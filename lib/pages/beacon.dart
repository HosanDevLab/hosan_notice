import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:double_back_to_close/double_back_to_close.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:hosan_notice/widgets/drawer.dart';

import '../messages.dart';

class BeaconScanPage extends StatefulWidget {
  _BeaconScanPageState createState() => _BeaconScanPageState();
}

class _BeaconScanPageState extends State<BeaconScanPage> {
  final flutterBlue = FlutterBlue.instance;
  final api = Api();
  late Future<List<MinewBeaconData?>> _scannedBeacons;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scannedBeacons = api.getScannedBeacons();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _scannedBeacons = api.getScannedBeacons();
      });
    });
    () async {
      final intent = AndroidIntent(
          action: "android.bluetooth.adapter.action.REQUEST_ENABLE");
      await intent.launch();
      await api.startScan();
    }();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBack(
        message: '뒤로가기를 한번 더 누르면 종료합니다.',
        child: Scaffold(
          appBar: AppBar(
            title: Text('비콘 스캔'),
            centerTitle: true,
          ),
          body: FutureBuilder(
            future: _scannedBeacons,
            builder: (BuildContext context,
                AsyncSnapshot<List<MinewBeaconData?>> snapshot) {
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
                  child: SizedBox(
                    height: double.infinity,
                    child: ListView(
                      physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      children: snapshot.data!.map<Widget>((e) {
                        return Card(
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            onTap: () {},
                            title: Text(e!.name!),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                Text(e.uuid!),
                                SizedBox(height: 5),
                                Text(
                                  'MAC 주소: ${e.mac}',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'MAJOR: ${e.major} / MINOR: ${e.minor}',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  'RSSI: ${e.rssi}dBm',
                                  style: TextStyle(fontSize: 13),
                                ),
                                Text(
                                  '배터리: ${e.batteryLevel}%',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  onRefresh: () async {
                    final fetchFuture = api.getScannedBeacons();
                    setState(() {
                      _scannedBeacons = fetchFuture;
                    });
                    await _scannedBeacons;
                  });
            },
          ),
          drawer: MainDrawer(parentContext: context),
        ));
  }
}
