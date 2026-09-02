import 'dart:async';
import 'package:flutter/foundation.dart';

enum LogTag {
  chat('CHAT'),
  rtc('RTC'),
  schedule('SCHEDULE'),
  auth('AUTH');

  final String label;
  const LogTag(this.label);
}

class LogEntry {
  final String id;
  final LogTag tag;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? meta;
  final bool isError;

  const LogEntry({
    required this.id,
    required this.tag,
    required this.message,
    required this.timestamp,
    this.meta,
    this.isError = false,
  });

  String get formatted {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}";
    return "[$timeStr] [${tag.label}] $message";
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 50;

  final _logStreamController = StreamController<List<LogEntry>>.broadcast();
  Stream<List<LogEntry>> get logStream => _logStreamController.stream;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void log(LogTag tag, String message, {Map<String, dynamic>? meta, bool isError = false}) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tag: tag,
      message: _maskSecrets(message),
      timestamp: DateTime.now(),
      meta: meta,
      isError: isError,
    );

    _logs.insert(0, entry);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }

    if (kDebugMode) {
      debugPrint(entry.formatted);
    }

    _logStreamController.add(List.unmodifiable(_logs));
  }

  void logChat(String message, {Map<String, dynamic>? meta, bool isError = false}) => log(LogTag.chat, message, meta: meta, isError: isError);
  void logRtc(String message, {Map<String, dynamic>? meta, bool isError = false}) => log(LogTag.rtc, message, meta: meta, isError: isError);
  void logSchedule(String message, {Map<String, dynamic>? meta, bool isError = false}) => log(LogTag.schedule, message, meta: meta, isError: isError);
  void logAuth(String message, {Map<String, dynamic>? meta, bool isError = false}) => log(LogTag.auth, message, meta: meta, isError: isError);

  void clearLogs() {
    _logs.clear();
    _logStreamController.add([]);
  }

  String _maskSecrets(String input) {
    // Mask potential API keys or tokens
    final tokenRegex = RegExp(r'(eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,})');
    return input.replaceAllMapped(tokenRegex, (match) {
      final token = match.group(0) ?? '';
      if (token.length > 12) {
        return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
      }
      return '******';
    });
  }
}
