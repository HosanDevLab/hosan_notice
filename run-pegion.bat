flutter pub run pigeon --input pigeon/messages.dart ^
  --dart_out lib/messages.dart ^
  --objc_header_out ios/Runner/pigeon.h ^
  --objc_source_out ios/Runner/pigeon.m ^
  --objc_prefix BK ^
  --java_out ./android/app/src/main/kotlin/com/hosandevlab/hosan_notice/pigeon/Pigeon.java ^
  --java_package "com.hosandevlab.hosan_notice.pigeon"