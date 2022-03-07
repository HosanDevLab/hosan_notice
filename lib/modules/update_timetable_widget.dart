import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hosan_notice/modules/refresh_token.dart';
import 'package:http/http.dart' as http;

Future fetchAndUpdateTimetableWidget(String authToken) async {
  final remoteConfig = RemoteConfig.instance;
  final user = FirebaseAuth.instance.currentUser;

  print(await user?.getIdToken(true));
  print(authToken);

  Future<Map<dynamic, dynamic>> fetchTimetable() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

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
      await refreshToken();
      return await fetchTimetable();
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Failed to load post');
    }
  }

  final timetable = await fetchTimetable();

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
    ...List.generate(7, (i) => i + 1).map((e) {
      final data = filteredTable.firstWhere(
            (o) => o['period'] == e,
        orElse: () => null,
      );

      return HomeWidget.saveWidgetData<String>(
        'p${e}',
        data?['subject']['short_name'] ?? data?['subject']['name'] ?? '',
      );
    }),
    ...(filteredTable.isNotEmpty
        ? [HomeWidget.saveWidgetData<bool>('visibility', true)]
        : [
      HomeWidget.saveWidgetData<String>(
          'centerMessage', '시간표 정보가 없습니다.'),
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
