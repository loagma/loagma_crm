import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../models/live_tracking/location_models.dart';

/// Service class for handling Firebase authentication and user management
/// Provides email/password authentication with role-based access control
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for authentication state management
  final StreamController<TrackingUser?> _userController =
      StreamController<TrackingUser?>.broadcast();
  TrackingUser? _currentTrackingUser;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current tracking user with role information
  TrackingUser? get currentTrackingUser => _currentTrackingUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of tracking user changes (includes role information)
  Stream<TrackingUser?> get trackingUserChanges => _userController.stream;

  /// Initialize authentication service and set up listeners
  Future<void> initialize() async {
    // Listen to auth state changes and update tracking user accordingly
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        final trackingUser = await getUserData(user.uid);
        _currentTrackingUser = trackingUser;
        _userController.add(trackingUser);
      } else {
        _currentTrackingUser = null;
        _userController.add(null);
      }
    });

    // Initialize current user if already signed in
    if (_auth.currentUser != null) {
      _currentTrackingUser = await getUserData(_auth.currentUser!.uid);
      _userController.add(_currentTrackingUser);
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Load user data after successful sign in
      if (credential.user != null) {
        final trackingUser = await getUserData(credential.user!.uid);
        _currentTrackingUser = trackingUser;
        _userController.add(trackingUser);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred during sign in');
    }
  }

  /// Register new user with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        await createUserDocument(
          userId: credential.user!.uid,
          email: email,
          name: name,
          role: role,
        );

        // Update display name
        await credential.user!.updateDisplayName(name);

        // Load the created user data
        final trackingUser = await getUserData(credential.user!.uid);
        _currentTrackingUser = trackingUser;
        _userController.add(trackingUser);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred during registration');
    }
  }

  /// Create user document in Firestore
  Future<void> createUserDocument({
    required String userId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      final userData = {
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'active': true,
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      throw AuthException('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Update user's last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'last_login': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for last login update failure
      // This is not critical for authentication flow
    }
  }

  /// Get user data from Firestore
  Future<TrackingUser?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = userId;

        // Handle Firestore timestamp
        if (data['created_at'] is Timestamp) {
          data['created_at'] =
              (data['created_at'] as Timestamp).millisecondsSinceEpoch;
        }

        return TrackingUser.fromJson(data);
      }
      return null;
    } catch (e) {
      throw AuthException('Failed to load user data: ${e.toString()}');
    }
  }

  /// Update user active status
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'active': isActive,
        'last_activity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to update user status: ${e.toString()}');
    }
  }

  /// Check if current user has admin role
  Future<bool> isCurrentUserAdmin() async {
    if (_currentTrackingUser != null) {
      return _currentTrackingUser!.role == UserRole.admin;
    }

    final user = currentUser;
    if (user == null) return false;

    final userData = await getUserData(user.uid);
    return userData?.role == UserRole.admin;
  }

  /// Check if current user has salesman role
  Future<bool> isCurrentUserSalesman() async {
    if (_currentTrackingUser != null) {
      return _currentTrackingUser!.role == UserRole.salesman;
    }

    final user = currentUser;
    if (user == null) return false;

    final userData = await getUserData(user.uid);
    return userData?.role == UserRole.salesman;
  }

  /// Check if user has specific role
  Future<bool> hasRole(UserRole role) async {
    if (_currentTrackingUser != null) {
      return _currentTrackingUser!.role == role;
    }

    final user = currentUser;
    if (user == null) return false;

    final userData = await getUserData(user.uid);
    return userData?.role == role;
  }

  /// Require admin role - throws exception if not admin
  Future<void> requireAdminRole() async {
    if (!await isCurrentUserAdmin()) {
      throw AuthException('Admin access required');
    }
  }

  /// Require salesman role - throws exception if not salesman
  Future<void> requireSalesmanRole() async {
    if (!await isCurrentUserSalesman()) {
      throw AuthException('Salesman access required');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Update user status to inactive before signing out
      if (_auth.currentUser != null) {
        await updateUserActiveStatus(_auth.currentUser!.uid, false);
      }

      await _auth.signOut();
      _currentTrackingUser = null;
      _userController.add(null);
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException('No user signed in');

    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        // Also update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'name': displayName,
        });
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Refresh current tracking user data
      _currentTrackingUser = await getUserData(user.uid);
      _userController.add(_currentTrackingUser);
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException(
        'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Change user password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = currentUser;
    if (user == null) throw AuthException('No user signed in');

    try {
      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Failed to change password: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String password) async {
    final user = currentUser;
    if (user == null) throw AuthException('No user signed in');

    try {
      // Re-authenticate user before deleting account
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete the user account
      await user.delete();

      _currentTrackingUser = null;
      _userController.add(null);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Failed to delete account: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions and convert to custom exceptions
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found with this email address');
      case 'wrong-password':
        return AuthException('Incorrect password');
      case 'email-already-in-use':
        return AuthException(
          'An account already exists with this email address',
        );
      case 'weak-password':
        return AuthException('Password is too weak');
      case 'invalid-email':
        return AuthException('Invalid email address');
      case 'user-disabled':
        return AuthException('This account has been disabled');
      case 'too-many-requests':
        return AuthException(
          'Too many failed attempts. Please try again later',
        );
      case 'requires-recent-login':
        return AuthException('Please sign in again to complete this action');
      default:
        return AuthException(e.message ?? 'Authentication failed');
    }
  }

  /// Dispose resources
  void dispose() {
    _userController.close();
  }
}

/// Custom authentication exception class
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
