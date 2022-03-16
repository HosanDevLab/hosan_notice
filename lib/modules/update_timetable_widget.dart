import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hosan_notice/modules/refresh_token.dart' as r;
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:workmanager/workmanager.dart';

Future fetchAndUpdateTimetableWidget(
    String authToken, String refreshToken) async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  final user = FirebaseAuth.instance.currentUser;

  print('asdf');
  print(await user?.getIdToken(true));
  print(authToken);

  Future<Map<dynamic, dynamic>?> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());
    final storage = new LocalStorage('auth.json');

    await storage.ready;

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/timetables/me'),
        headers: {
          'ID-Token': await user?.getIdToken(true) ?? '',
          'Authorization': 'Bearer ${authToken}',
        });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      final re = await r.refreshToken(
          authToken: authToken, refreshToken: refreshToken);

      await storage.setItem('AUTH_TOKEN', re[0]);
      await storage.setItem('REFRESH_TOKEN', re[1]);

      await Workmanager().cancelByUniqueName('1');
      await Workmanager().registerPeriodicTask(
        '1',
        'widgetBackgroundUpdate',
        inputData: {'authToken': re[0], 'refreshToken': re[1]},
        frequency: Duration(minutes: 15),
      );

      return null;
    } else {
      print(response.statusCode);
      print(response.body);
      print('failed to refresh timetable widget');
    }
    return null;
  }

  final timetable = await fetchTimetable();

  if (timetable == null) return;

  final dow = DateTime.now().weekday;
  final tod = TimeOfDay.now();
  final inMin = tod.hour * 60 + tod.minute;

  int period = 0;
  if (inMin < 8 * 60 + 20) {
    period = 0;
  } else if (8 * 60 + 20 <= inMin && inMin < 9 * 60 + 20) {
    period = 1;
  } else if (9 * 60 + 20 <= inMin && inMin < 10 * 60 + 20) {
    period = 2;
  } else if (10 * 60 + 20 <= inMin && inMin < 11 * 60 + 20) {
    period = 3;
  } else if (11 * 60 + 20 <= inMin && inMin < 12 * 60 + 20) {
    period = 4;
  } else if (12 * 60 + 20 <= inMin && inMin < 13 * 60 + 20) {
    period = 0;
  } else if (13 * 60 + 20 <= inMin && inMin < 14 * 60 + 20) {
    period = 5;
  } else if (14 * 60 + 20 <= inMin && inMin < 15 * 60 + 20) {
    period = 6;
  } else if (15 * 60 + 20 <= inMin && inMin < 16 * 60 + 20) {
    period = 7;
  }

  final filteredTable =
      (timetable['table'] as List).where((e) => e['dow'] == dow).toList();
  filteredTable.sort((a, b) => a['period'] - b['period']);

  await Future.wait([
    ...(filteredTable.isNotEmpty
        ? [
            ...List.generate(7, (i) => i + 1).map((e) {
              final data = filteredTable.firstWhere(
                (o) => o['period'] == e,
                orElse: () => null,
              );

              return HomeWidget.saveWidgetData<String>(
                'p${e}',
                data?['subject']?['short_name'] ??
                    data?['subject']?['name'] ??
                    '',
              );
            }),
            HomeWidget.saveWidgetData<bool>('visibility', true)
          ]
        : [
            HomeWidget.saveWidgetData<String>('centerMessage', '시간표 정보가 없습니다.'),
            HomeWidget.saveWidgetData<bool>('visibility', false)
          ]),
    HomeWidget.saveWidgetData<int>('currentDow', dow),
    HomeWidget.saveWidgetData<int>('currentPeriod', period),
    HomeWidget.updateWidget(
      name: 'TimetableWidgetProvider',
      iOSName: 'homeWidget',
    )
  ]);
}
