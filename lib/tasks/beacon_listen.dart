import 'package:hosan_notice/messages.dart';

final api = Api();

Future beaconListen() async {
  while (true) {
    print(await api.getScannedBeacons().toString());
    await Future.delayed(Duration(seconds: 5));
  }
}