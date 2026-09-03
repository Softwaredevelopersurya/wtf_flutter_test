import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'log_service.dart';
import 'sync_bridge.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LogService _logger = LogService();
  final SyncBridge _syncBridge = SyncBridge();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  static const String _keyMemberOnboarded = 'key_member_onboarded';
  static const String _keySavedUserId = 'key_saved_user_id';
  static const String _keySavedUserRole = 'key_saved_user_role';

  /// Initializes authentication state from local preferences
  Future<User?> loadSession(UserRole expectedRole) async {
    await _syncBridge.initialize();
    final prefs = await SharedPreferences.getInstance();

    final savedUserId = prefs.getString('${_keySavedUserId}_${expectedRole.name}');
    if (savedUserId != null) {
      final user = _syncBridge.users.firstWhere(
        (u) => u.id == savedUserId,
        orElse: () => _getDefaultUser(expectedRole),
      );
      _currentUser = user;
      _logger.logAuth('Restored session for ${user.name} (${user.role.name})');
      return user;
    }

    // Default seeded fallback for seamless review testing
    if (expectedRole == UserRole.trainer) {
      final trainer = _getDefaultUser(UserRole.trainer);
      await saveSession(trainer);
      return trainer;
    }

    return null;
  }

  /// Checks if member onboarding is completed
  Future<bool> isMemberOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMemberOnboarded) ?? false;
  }

  /// Completes member onboarding and saves profile
  Future<User> completeMemberOnboarding({
    required String name,
    required String email,
    required String assignedTrainerId,
    String? avatarUrl,
  }) async {
    final isDkPersona = name.trim().toUpperCase() == 'DK' ||
        email.trim().toLowerCase().contains('dk.member') ||
        email.trim().toLowerCase() == 'dk@wtf.fitness';

    final sanitizedName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final memberId = isDkPersona
        ? 'user_member_dk'
        : 'user_member_${sanitizedName.isNotEmpty ? sanitizedName : DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final user = User(
      id: memberId,
      role: UserRole.member,
      name: name,
      email: email,
      assignedTrainerId: assignedTrainerId,
      avatarUrl: avatarUrl ?? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
    );

    await _syncBridge.saveUser(user);
    await saveSession(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMemberOnboarded, true);

    _logger.logAuth('Completed member onboarding for ${user.name} (ID: ${user.id}), assigned to trainer: $assignedTrainerId');
    return user;
  }

  /// Saves active user session to preferences
  Future<void> saveSession(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_keySavedUserId}_${user.role.name}', user.id);
    await prefs.setString('${_keySavedUserRole}_${user.role.name}', user.role.name);
    _logger.logAuth('Saved session for ${user.name}');
  }

  /// Reset session for testing onboarding from scratch
  Future<void> resetSession(UserRole role) async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keySavedUserId}_${role.name}');
    await prefs.remove('${_keySavedUserRole}_${role.name}');
    if (role == UserRole.member) {
      await prefs.remove(_keyMemberOnboarded);
    }
    _logger.logAuth('Session reset for $role');
  }

  User _getDefaultUser(UserRole role) {
    if (role == UserRole.trainer) {
      return const User(
        id: 'user_trainer_aarav',
        role: UserRole.trainer,
        name: 'Aarav (Lead Trainer)',
        email: 'aarav.trainer@wtf.fitness',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      );
    } else {
      return const User(
        id: 'user_member_dk',
        role: UserRole.member,
        name: 'DK',
        email: 'dk.member@wtf.fitness',
        assignedTrainerId: 'user_trainer_aarav',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      );
    }
  }
}
