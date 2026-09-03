import 'package:flutter/foundation.dart';

/// Agora RTC & Messaging and Application Environment Configuration
class AppConfig {
  /// Custom Remote / Vercel Cloud Server URL (can be passed via `--dart-define=TOKEN_SERVER_URL=https://tokenserver-tau.vercel.app`)
  static const String remoteTokenServerUrl = String.fromEnvironment(
    'TOKEN_SERVER_URL',
    defaultValue: '',
  );

  /// Agora App ID (from https://console.agora.io)
  static const String agoraAppId = '5f80f33fd1d74126a1a810b136401168';

  /// Agora App Certificate (from https://console.agora.io)
  static const String agoraAppCertificate = '3f98aba92ac3451dbc52bd9d2cd67b33';

  /// Agora Default Channel Name
  static const String agoraDefaultChannel = 'wtf_flutter_test';

  /// Agora Temporary Token for default channel (provided by user)
  static const String agoraTempToken =
      '007eJxTYIjbl1sul/OoJFKKo/GLnno010fdH4WqL19zv78lJfLzwgYFBtM0C4M0Y+O0FMMUcxNDI7NEw0QLQ4MkQ2MzEwNDQzMLReuZWQ2BjAyfHPazMDJAIIgvwFBekhafllNaUpJaFF+SWlzCwAAAoWYjlQ==';

  /// Token Server URL (supports Remote Vercel URL, Android emulator 10.0.2.2, and localhost)
  static String get tokenServerUrl {
    if (remoteTokenServerUrl.isNotEmpty) {
      return remoteTokenServerUrl;
    }
    return (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  // Backward compatibility helpers
  static const String hmsAppAccessKey = agoraAppId;
  static const String hmsAppSecret = agoraAppCertificate;
  static const String hmsDefaultRoomId = agoraDefaultChannel;
}
