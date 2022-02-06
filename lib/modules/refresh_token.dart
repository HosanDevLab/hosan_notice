import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';

import 'get_device_id.dart';

final storage = new LocalStorage('auth.json');
final remoteConfig = RemoteConfig.instance;

final refreshToken = () async {
  final user = FirebaseAuth.instance.currentUser!;
  var rawData = remoteConfig.getAll()['BACKEND_HOST'];
  var cfgs = jsonDecode(rawData!.asString());

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
  } else {
    throw Exception('Failed to refresh token');
  }
};