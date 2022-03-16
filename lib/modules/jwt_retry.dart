import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hosan_notice/modules/get_device_id.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:localstorage/localstorage.dart';

final jwtRetryClient = () {
  final storage = new LocalStorage('auth.json');
  
  return RetryClient(
    http.Client(),
    retries: 1,
    delay: (_) => Duration(milliseconds: 500),
    when: (response) {
      return response.statusCode == 401 ? true : false;
    },
    onRetry: (req, res, retryCount) async {
      print('retry=========================================================================');
      final user = FirebaseAuth.instance.currentUser!;
      final remoteConfig = FirebaseRemoteConfig.instance;

      var rawData = remoteConfig.getAll()['BACKEND_HOST'];
      var cfgs = jsonDecode(rawData!.asString());

      if (retryCount == 0 && res?.statusCode == 401) {
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
          print('done');
        } else {
          print(response.statusCode);
          print(response.body);
        }
      }
    },
  );
};
