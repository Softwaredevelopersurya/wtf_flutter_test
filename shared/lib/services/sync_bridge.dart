import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../utils/app_config.dart';
import 'log_service.dart';

/// Lightweight cross-app synchronization bridge
/// Ensures Guru App & Trainer App communicate in real time locally and across devices/emulators via shared file & HTTP sync.
class SyncBridge {
  static final SyncBridge _instance = SyncBridge._internal();
  factory SyncBridge() => _instance;
  SyncBridge._internal();

  final LogService _logger = LogService();
  File? _stateFile;
  Timer? _pollingTimer;

  // In-memory state cache
  final List<User> _users = [];
  final List<Message> _messages = [];
  final List<CallRequest> _callRequests = [];
  final List<SessionLog> _sessionLogs = [];
  final Map<String, bool> _typingStatus = {}; // userId -> isTyping

  // Reactive Stream Controllers
  final _messagesController = StreamController<List<Message>>.broadcast();
  final _callRequestsController = StreamController<List<CallRequest>>.broadcast();
  final _sessionLogsController = StreamController<List<SessionLog>>.broadcast();
  final _typingController = StreamController<Map<String, bool>>.broadcast();
  final _usersController = StreamController<List<User>>.broadcast();

  Stream<List<Message>> get messagesStream => _messagesController.stream;
  Stream<List<CallRequest>> get callRequestsStream => _callRequestsController.stream;
  Stream<List<SessionLog>> get sessionLogsStream => _sessionLogsController.stream;
  Stream<Map<String, bool>> get typingStream => _typingController.stream;
  Stream<List<User>> get usersStream => _usersController.stream;

  List<Message> get messages => List.unmodifiable(_messages);
  List<CallRequest> get callRequests => List.unmodifiable(_callRequests);
  List<SessionLog> get sessionLogs => List.unmodifiable(_sessionLogs);
  List<User> get users => List.unmodifiable(_users);
  Map<String, bool> get typingStatus => Map.unmodifiable(_typingStatus);

  DateTime _lastModified = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastServerVersion = 0;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _seedDefaultData();

      // 1. Resolve shared state file path across desktop/mobile processes
      if (!kIsWeb) {
        try {
          String? dirPath;
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            dirPath = Directory.systemTemp.path;
          } else {
            final appDir = await getApplicationDocumentsDirectory();
            dirPath = appDir.path;
          }

          _stateFile = File('$dirPath/wtf_local_state.json');

          if (await _stateFile!.exists()) {
            await _loadFromFile();
          } else {
            await _saveToFile();
          }
        } catch (e) {
          debugPrint('SyncBridge file storage init notice: $e');
        }
      }

      // 2. Fetch initial state from Token/Sync Server if reachable
      await _syncWithServer();

      // 3. Start reactive polling (every 400ms) on all platforms (Web, Desktop, Mobile)
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _checkForExternalChanges());

      _isInitialized = true;
      _logger.logAuth('SyncBridge initialized successfully', meta: {
        'isWeb': kIsWeb,
        'path': _stateFile?.path,
      });
    } catch (e) {
      _logger.logAuth('SyncBridge initialization fallback', meta: {'error': e.toString()});
      _seedDefaultData();
      _notifyAll();

      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _checkForExternalChanges());
      _isInitialized = true;
    }
  }

  void _seedDefaultData() {
    _users.clear();
    _users.addAll([
      const User(
        id: 'user_trainer_aarav',
        role: UserRole.trainer,
        name: 'Aarav (Lead Trainer)',
        email: 'aarav.trainer@wtf.fitness',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ),
      const User(
        id: 'user_member_dk',
        role: UserRole.member,
        name: 'DK',
        email: 'dk.member@wtf.fitness',
        assignedTrainerId: 'user_trainer_aarav',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      ),
    ]);
  }

  Future<void> _loadFromFile() async {
    if (kIsWeb || _stateFile == null) return;

    try {
      if (!await _stateFile!.exists()) return;

      final stat = await _stateFile!.stat();
      _lastModified = stat.modified;

      final content = await _stateFile!.readAsString();
      if (content.trim().isEmpty) return;

      final data = json.decode(content) as Map<String, dynamic>;
      _parseAndApplyState(data);
    } catch (e) {
      debugPrint('SyncBridge load error: $e');
    }
  }

  void _parseAndApplyState(Map<String, dynamic> data) {
    bool hasChanges = false;

    if (data['users'] != null) {
      final incomingUsers = (data['users'] as List)
          .map((item) => User.fromMap(item as Map<String, dynamic>))
          .toList();
      for (final user in incomingUsers) {
        final idx = _users.indexWhere((u) => u.id == user.id);
        if (idx >= 0) {
          _users[idx] = user;
        } else {
          _users.add(user);
        }
      }
      hasChanges = true;
    }

    if (data['messages'] != null) {
      final incomingMsgs = (data['messages'] as List)
          .map((item) => Message.fromMap(item as Map<String, dynamic>))
          .toList();
      for (final msg in incomingMsgs) {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx >= 0) {
          _messages[idx] = msg;
        } else {
          _messages.add(msg);
        }
      }
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      hasChanges = true;
    }

    if (data['callRequests'] != null) {
      final incomingCalls = (data['callRequests'] as List)
          .map((item) => CallRequest.fromMap(item as Map<String, dynamic>))
          .toList();
      for (final req in incomingCalls) {
        final idx = _callRequests.indexWhere((r) => r.id == req.id);
        if (idx >= 0) {
          _callRequests[idx] = req;
        } else {
          _callRequests.add(req);
        }
      }
      hasChanges = true;
    }

    if (data['sessionLogs'] != null) {
      final incomingLogs = (data['sessionLogs'] as List)
          .map((item) => SessionLog.fromMap(item as Map<String, dynamic>))
          .toList();
      for (final log in incomingLogs) {
        final idx = _sessionLogs.indexWhere((s) => s.id == log.id);
        if (idx >= 0) {
          _sessionLogs[idx] = log;
        } else {
          _sessionLogs.add(log);
        }
      }
      hasChanges = true;
    }

    if (data['typing'] != null) {
      final typingMap = data['typing'] as Map<String, dynamic>;
      typingMap.forEach((key, value) {
        _typingStatus[key] = value as bool;
      });
      hasChanges = true;
    }

    if (hasChanges) {
      _notifyAll();
    }
  }

  Future<void> _saveToFile() async {
    _notifyAll();
    if (kIsWeb || _stateFile == null) return;

    try {
      final data = {
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'users': _users.map((u) => u.toMap()).toList(),
        'messages': _messages.map((m) => m.toMap()).toList(),
        'callRequests': _callRequests.map((c) => c.toMap()).toList(),
        'sessionLogs': _sessionLogs.map((s) => s.toMap()).toList(),
        'typing': _typingStatus,
      };

      await _stateFile!.writeAsString(json.encode(data), flush: true);
      final stat = await _stateFile!.stat();
      _lastModified = stat.modified;
    } catch (e) {
      debugPrint('SyncBridge save error: $e');
    }
  }

  Future<void> _syncWithServer() async {
    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync');
      final response = await http.get(uri).timeout(const Duration(seconds: 1));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final serverVer = data['version'] as int? ?? 0;
        final serverMsgCount = (data['messages'] as List?)?.length ?? 0;
        final serverCallCount = (data['callRequests'] as List?)?.length ?? 0;
        final serverLogCount = (data['sessionLogs'] as List?)?.length ?? 0;

        if (serverVer != _lastServerVersion ||
            serverMsgCount != _messages.length ||
            serverCallCount != _callRequests.length ||
            serverLogCount != _sessionLogs.length ||
            _messages.isEmpty) {
          _lastServerVersion = serverVer;
          _parseAndApplyState(data);
          await _saveToFile();
        }
      }
    } catch (_) {
      // Server offline - purely local mode continues seamlessly
    }
  }

  Future<void> _checkForExternalChanges() async {
    // 1. Check local file modification (native desktop/mobile only)
    if (!kIsWeb && _stateFile != null) {
      try {
        if (await _stateFile!.exists()) {
          final stat = await _stateFile!.stat();
          if (stat.modified.isAfter(_lastModified)) {
            await _loadFromFile();
          }
        }
      } catch (_) {}
    }

    // 2. Periodic HTTP sync with Token Server (all platforms including Chrome/Web)
    await _syncWithServer();
  }

  void _notifyAll() {
    _usersController.add(List.unmodifiable(_users));
    _messagesController.add(List.unmodifiable(_messages));
    _callRequestsController.add(List.unmodifiable(_callRequests));
    _sessionLogsController.add(List.unmodifiable(_sessionLogs));
    _typingController.add(Map.unmodifiable(_typingStatus));
  }

  // --- CRUD Mutations with instant save & broadcast & server sync ---

  Future<void> saveUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    await _saveToFile();

    // Async push user to server
    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/user');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: user.toJson(),
      ).timeout(const Duration(milliseconds: 800)).ignore();
    } catch (_) {}
  }

  Future<void> addMessage(Message message) async {
    _messages.add(message);
    _notifyAll();
    await _saveToFile();

    // Async push to server
    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/message');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: message.toJson(),
      ).then((res) {
        if (res.statusCode == 200) {
          try {
            final data = json.decode(res.body) as Map<String, dynamic>;
            if (data['version'] != null) {
              _lastServerVersion = data['version'] as int;
            }
          } catch (_) {}
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(status: status);
      await _saveToFile();
    }
  }

  Future<void> markMessagesAsRead({required String chatId, required String currentUserId, String? otherUserId}) async {
    bool hasChanges = false;
    for (int i = 0; i < _messages.length; i++) {
      final matchesChat = _messages[i].chatId == chatId ||
          (otherUserId != null &&
              ((_messages[i].senderId == currentUserId && _messages[i].receiverId == otherUserId) ||
                  (_messages[i].senderId == otherUserId && _messages[i].receiverId == currentUserId)));
      if (matchesChat &&
          _messages[i].receiverId == currentUserId &&
          _messages[i].status != MessageStatus.read) {
        _messages[i] = _messages[i].copyWith(status: MessageStatus.read);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      await _saveToFile();

      try {
        final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/read');
        http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'chatId': chatId,
            'currentUserId': currentUserId,
            if (otherUserId != null) 'otherUserId': otherUserId,
          }),
        ).timeout(const Duration(milliseconds: 800)).ignore();
      } catch (_) {}
    }
  }

  Future<void> setTypingStatus(String userId, bool isTyping) async {
    _typingStatus[userId] = isTyping;
    _typingController.add(Map.unmodifiable(_typingStatus));

    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/typing');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'isTyping': isTyping}),
      ).timeout(const Duration(milliseconds: 800)).ignore();
    } catch (_) {}
  }

  Future<void> addCallRequest(CallRequest request) async {
    _callRequests.add(request);
    await _saveToFile();

    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/call_request');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: request.toJson(),
      ).timeout(const Duration(milliseconds: 800)).ignore();
    } catch (_) {}
  }

  Future<void> updateCallRequest(CallRequest request) async {
    final index = _callRequests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      _callRequests[index] = request;
      await _saveToFile();

      try {
        final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/call_request');
        http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: request.toJson(),
        ).timeout(const Duration(milliseconds: 800)).ignore();
      } catch (_) {}
    }
  }

  Future<void> addSessionLog(SessionLog log) async {
    _sessionLogs.insert(0, log);
    await _saveToFile();

    try {
      final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/session_log');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: log.toJson(),
      ).timeout(const Duration(milliseconds: 800)).ignore();
    } catch (_) {}
  }

  Future<void> updateSessionLog(SessionLog log) async {
    final index = _sessionLogs.indexWhere((s) => s.id == log.id);
    if (index >= 0) {
      _sessionLogs[index] = log;
      await _saveToFile();

      try {
        final uri = Uri.parse('${AppConfig.tokenServerUrl}/api/sync/session_log');
        http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: log.toJson(),
        ).timeout(const Duration(milliseconds: 800)).ignore();
      } catch (_) {}
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _messagesController.close();
    _callRequestsController.close();
    _sessionLogsController.close();
    _typingController.close();
    _usersController.close();
  }
}
