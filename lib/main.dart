import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:home_widget/home_widget_callback_dispatcher.dart';
import 'package:hosan_notice/pages/home.dart';
import 'package:hosan_notice/pages/login.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'messages.dart';
import 'modules/refresh_token.dart';
import 'modules/update_timetable_widget.dart';

final storage = new LocalStorage('auth.json');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await storage.ready;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );
  await Workmanager().cancelByUniqueName('1');
  await Workmanager().registerPeriodicTask(
    '1',
    'widgetBackgroundUpdate',
    inputData: {
      'authToken': storage.getItem('AUTH_TOKEN') ?? '',
      'refreshToken': storage.getItem('REFRESH_TOKEN') ?? ''
    },
    frequency: Duration(minutes: 15),
  );

  final remoteConfig = RemoteConfig.instance;

  remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: Duration(seconds: 10),
      minimumFetchInterval: Duration(minutes: 1),
    ),
  );
  remoteConfig.fetchAndActivate();

  final messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  await messaging.subscribeToTopic('assignmentPosted');

  await FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'foreground',
      channelName: '포어그라운드 알림',
      channelDescription: '포어그라운드 서비스가 실행 중일때 표시됩니다.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      iconData: NotificationIconData(
        resType: ResourceType.drawable,
        resPrefix: ResourcePrefix.ic,
        name: 'stat_app_icon',
      ),
    ),
    iosNotificationOptions: IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      interval: 5000,
      autoRunOnBoot: true,
    ),
    // printDevLog: true,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_app_icon');
  final initializationSettingsIOS = IOSInitializationSettings();
  final initializationSettingsMacOS = MacOSInitializationSettings();
  final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (payload) {
    print('noti payload $payload');
  });

  final channel = AndroidNotificationChannel(
    'fcm',
    '푸시 알림',
    description: '호산고 알리미의 공지 사항, 기타 알림이 전송됩니다.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    BigPictureStyleInformation? bigPictureStyleInformation;

    if (android?.imageUrl != null) {
      final response = await http.get(Uri.parse(android!.imageUrl!));

      final bigPicture = ByteArrayAndroidBitmap(response.bodyBytes);

      bigPictureStyleInformation = BigPictureStyleInformation(bigPicture);
    }

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'ic_stat_app_icon',
            importance: Importance.max,
            styleInformation: bigPictureStyleInformation,
          ),
        ),
      );
    }
  });

  runApp(App());
}

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if ((inputData?['authToken'] ?? '') == '') {
      throw Exception('authToken not provided');
    }

    await Firebase.initializeApp();

    try {
      return await fetchAndUpdateTimetableWidget(
        inputData!['authToken'],
        inputData['refreshToken'],
      ).then((value) {
        return Future.value(true);
      });
    } catch (e) {
      print(e);
      throw e;
    }
  });
}

/// Called when Doing Background Work initiated from Widget
void backgroundCallback(Uri data) async {
  print(data);

  if (data.host == 'titleclicked') {
    await HomeWidget.saveWidgetData<String>('p1', '안녕하세요');
    await HomeWidget.updateWidget(
        name: 'TimetableWidgetProvider', iOSName: 'homeWidget');
  }
}

void startCallback() {
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundTaskHandler implements TaskHandler {
  @override
  onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  onEvent(DateTime timestamp, SendPort? sendPort) async {
    sendPort?.send(null);
  }

  @override
  void onButtonPressed(String id) async {}

  @override
  onDestroy(DateTime timestamp) async {
    await FlutterForegroundTask.clearAllData();
  }
}

void initAndBeginForeground() async {
  late ReceivePort? receivePort;
  if (await FlutterForegroundTask.isRunningService) {
    receivePort = await FlutterForegroundTask.restartService();
  } else {
    receivePort = await FlutterForegroundTask.startService(
      notificationTitle: '자동 출결 시스템 동작중',
      notificationText: '시작 중...',
      callback: startCallback,
    );
  }

  final api = Api();
  await api.startScan();

  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final beacons = (await firestore.collection('beacons').get()).docs;

  QueryDocumentSnapshot<Map<String, dynamic>>? prevBeaconFBData;

  receivePort?.listen((message) async {
    final scannedBeacons = await api.getScannedBeacons();

    final notiText = "디버그 모드에서 실행 중: " +
        "비콘 ${beacons.length}개 로드됨 | " +
        "${scannedBeacons.length}개 스캔됨";

    FlutterForegroundTask.updateService(notificationText: notiText);

    final now = DateTime.now();

    final user = FirebaseAuth.instance.currentUser;

    // 교내 비콘이 감지될 경우, 즉 사용자가 학교 내에 있는 경우 출석 인정
    if (beacons.any((e) => scannedBeacons.map((e) => e!.uuid).contains(e.id))) {
      final attendAny = await firestore
          .collection('attendance')
          .where(
            'attendedAt',
            isGreaterThanOrEqualTo: DateTime(now.year, now.month, now.day),
          )
          .limit(1)
          .get();

      // 오늘 출석 내역 없는 경우 출석 등록
      if (attendAny.size == 0) {
        await firestore
            .collection('attendance')
            .add({'uid': user!.uid, 'attendedAt': now});

        final androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'attendance', '출결 알림',
            channelDescription: '자동 출석이 완료되었을 때 알림 표시',
            importance: Importance.low,
            priority: Priority.low);

        final iosPlatformChannelSpecifics =
            IOSNotificationDetails(sound: 'slow_spring.board.aiff');
        var platformChannelSpecifics = NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iosPlatformChannelSpecifics);

        final flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        await flutterLocalNotificationsPlugin.show(
          0,
          '출석이 체크되었습니다!',
          '${now.toString().split('.')[0]}에 교문을 통과했습니다.',
          platformChannelSpecifics,
        );
      }
    }

    // 실시간 위치 기록
    final beaconUUIDs = beacons.map((e) => e.id);
    final currentBeacons =
        scannedBeacons.where((e) => beaconUUIDs.contains(e!.uuid)).toList();
    currentBeacons.sort((a, b) => a!.rssi! - b!.rssi!);

    final currentBeacon =
        currentBeacons.isNotEmpty ? currentBeacons.first : null;

    final currentBeaconFBData = currentBeacons.isNotEmpty
        ? beacons.firstWhere((e) => e.id == currentBeacon!.uuid)
        : null;

    if (prevBeaconFBData?.id != currentBeaconFBData?.id) {
      if (currentBeaconFBData != null) {
        // 입실
        await firestore.collection('activities').add({
          'room': currentBeaconFBData.data()['room'],
          'type': 'in',
          'didAt': now,
          'uid': user!.uid
        });
      } else if (prevBeaconFBData != null) {
        // 퇴실
        await firestore.collection('activities').add({
          'room': prevBeaconFBData!.data()['room'],
          'type': 'out',
          'didAt': now,
          'uid': user!.uid
        });
      }

      prevBeaconFBData = currentBeaconFBData;
    }
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final remoteConfig = RemoteConfig.instance;
  final user = FirebaseAuth.instance.currentUser;
  final storage = new LocalStorage('auth.json');

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    HomeWidget.registerBackgroundCallback((uri) => backgroundCallback(
        uri ?? Uri.parse("TimetableWidgetProvider://message?message=asdf")));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    () async {
      await storage.ready;
      await fetchAndUpdateTimetableWidget(
        storage.getItem('AUTH_TOKEN'),
        storage.getItem('REFRESH_TOKEN'),
      );

      await Workmanager().registerPeriodicTask(
        '1',
        'widgetBackgroundUpdate',
        inputData: {
          'authToken': storage.getItem('AUTH_TOKEN') ?? '',
          'refreshToken': storage.getItem('REFRESH_TOKEN') ?? ''
        },
        frequency: Duration(minutes: 15),
      );
    }();
  }

  Future<Map<dynamic, dynamic>> fetchStudentsMe() async {
    var rawData = remoteConfig.getAll()['BACKEND_HOST'];
    var cfgs = jsonDecode(rawData!.asString());

    final response = await http.get(
        Uri.parse(
            '${kReleaseMode ? cfgs['release'] : cfgs['debug']}/students/me'),
        headers: {
          'ID-Token': await user?.getIdToken(true) ?? '',
          'Authorization': 'Bearer ${storage.getItem('AUTH_TOKEN')}',
        });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 &&
        jsonDecode(response.body)['code'] == 40100) {
      await refreshToken();
      return await fetchStudentsMe();
    } else {
      throw Exception('Failed to load post');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: '호산고등학교 알리미',
      theme:
          ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Pretendard'),
      home: FutureBuilder(
        future: Future.wait([
          () async {
            if (user == null) return null;
            CollectionReference students =
                FirebaseFirestore.instance.collection('students');

            return await students.doc(user.uid).get();
          }(),
          () async {
            await storage.ready;
            final authToken = await storage.getItem('AUTH_TOKEN');
            final refreshToken = await storage.getItem('REFRESH_TOKEN');
            return [authToken, refreshToken];
          }(),
          () async {
            await storage.ready;

            try {
              await fetchStudentsMe();
              return true;
            } catch (e) {
              return false;
            }
          }()
        ]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (user != null && !snapshot.hasData) {
            return Scaffold(
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('불러오는 중', textAlign: TextAlign.center),
                  )
                ])));
          }

          final isLoggedIn = user != null &&
              snapshot.data[0].exists &&
              !(snapshot.data[1] as List).contains(null) &&
              snapshot.data[2];

          if (isLoggedIn) {
            initAndBeginForeground();
            return HomePage();
          } else {
            return LoginPage();
          }
        },
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: [
        Locale('ko', 'KR'),
        // include country code too
      ],
    );
  }
}
