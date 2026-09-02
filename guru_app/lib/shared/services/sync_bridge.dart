import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'log_service.dart';

/// Lightweight local cross-app synchronization bridge
/// Ensures Guru App & Trainer App communicate in real time locally without requiring a remote cloud backend.
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
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _stateFile = File('${appDir.path}/wtf_local_state.json');

      if (await _stateFile!.exists()) {
        await _loadFromFile();
      } else {
        _seedDefaultData();
        await _saveToFile();
      }

      // Start reactive polling (every 250ms) to detect cross-process changes immediately
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) => _checkForExternalChanges());

      _isInitialized = true;
      _logger.logAuth('SyncBridge initialized successfully', meta: {'path': _stateFile?.path});
    } catch (e) {
      _logger.logAuth('SyncBridge local fallback initialization', meta: {'error': e.toString()});
      _seedDefaultData();
      _notifyAll();
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
    if (_stateFile == null || !await _stateFile!.exists()) return;

    try {
      final stat = await _stateFile!.stat();
      _lastModified = stat.modified;

      final content = await _stateFile!.readAsString();
      if (content.trim().isEmpty) return;

      final data = json.decode(content) as Map<String, dynamic>;

      if (data['users'] != null) {
        _users.clear();
        for (final item in data['users'] as List) {
          _users.add(User.fromMap(item as Map<String, dynamic>));
        }
      }

      if (data['messages'] != null) {
        _messages.clear();
        for (final item in data['messages'] as List) {
          _messages.add(Message.fromMap(item as Map<String, dynamic>));
        }
      }

      if (data['callRequests'] != null) {
        _callRequests.clear();
        for (final item in data['callRequests'] as List) {
          _callRequests.add(CallRequest.fromMap(item as Map<String, dynamic>));
        }
      }

      if (data['sessionLogs'] != null) {
        _sessionLogs.clear();
        for (final item in data['sessionLogs'] as List) {
          _sessionLogs.add(SessionLog.fromMap(item as Map<String, dynamic>));
        }
      }

      if (data['typing'] != null) {
        _typingStatus.clear();
        final typingMap = data['typing'] as Map<String, dynamic>;
        typingMap.forEach((key, value) {
          _typingStatus[key] = value as bool;
        });
      }

      _notifyAll();
    } catch (e) {
      debugPrint('SyncBridge load error: $e');
    }
  }

  Future<void> _saveToFile() async {
    if (_stateFile == null) return;

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
      _notifyAll();
    } catch (e) {
      debugPrint('SyncBridge save error: $e');
    }
  }

  Future<void> _checkForExternalChanges() async {
    if (_stateFile == null || !await _stateFile!.exists()) return;

    try {
      final stat = await _stateFile!.stat();
      if (stat.modified.isAfter(_lastModified)) {
        await _loadFromFile();
      }
    } catch (e) {
      // Ignored for resilience
    }
  }

  void _notifyAll() {
    _usersController.add(List.unmodifiable(_users));
    _messagesController.add(List.unmodifiable(_messages));
    _callRequestsController.add(List.unmodifiable(_callRequests));
    _sessionLogsController.add(List.unmodifiable(_sessionLogs));
    _typingController.add(Map.unmodifiable(_typingStatus));
  }

  // --- CRUD Mutations with instant save & broadcast ---

  Future<void> saveUser(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    await _saveToFile();
  }

  Future<void> addMessage(Message message) async {
    _messages.add(message);
    await _saveToFile();
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(status: status);
      await _saveToFile();
    }
  }

  Future<void> markMessagesAsRead({required String chatId, required String currentUserId}) async {
    bool hasChanges = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].chatId == chatId &&
          _messages[i].receiverId == currentUserId &&
          _messages[i].status != MessageStatus.read) {
        _messages[i] = _messages[i].copyWith(status: MessageStatus.read);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      await _saveToFile();
    }
  }

  Future<void> setTypingStatus(String userId, bool isTyping) async {
    _typingStatus[userId] = isTyping;
    await _saveToFile();
  }

  Future<void> addCallRequest(CallRequest request) async {
    _callRequests.add(request);
    await _saveToFile();
  }

  Future<void> updateCallRequest(CallRequest request) async {
    final index = _callRequests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      _callRequests[index] = request;
      await _saveToFile();
    }
  }

  Future<void> addSessionLog(SessionLog log) async {
    _sessionLogs.insert(0, log); // latest on top
    await _saveToFile();
  }

  Future<void> updateSessionLog(SessionLog log) async {
    final index = _sessionLogs.indexWhere((s) => s.id == log.id);
    if (index >= 0) {
      _sessionLogs[index] = log;
      await _saveToFile();
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
