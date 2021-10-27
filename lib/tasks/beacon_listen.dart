import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hosan_notice/messages.dart';

final api = Api();
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future beaconListen() async {
  await api.startScan();
  Timer.periodic(Duration(seconds: 5), (timer) async {
    print(DateTime.now().toString());
    print((await api.getScannedBeacons()).toString());

    var androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high);

    var iosPlatformChannelSpecifics =
    IOSNotificationDetails(sound: 'slow_spring.board.aiff');
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      '테스트 알림',
      '이것은 Flutter 노티피케이션!',
      platformChannelSpecifics,
      payload: 'Hello Flutter',
    );
  });
}