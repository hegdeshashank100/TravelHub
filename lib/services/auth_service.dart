import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/email_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth change user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Enhanced network connectivity check
  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Internet connection: AVAILABLE');
        return true;
      }
    } on TimeoutException catch (e) {
      print('❌ Internet connection: TIMEOUT - $e');
    } on SocketException catch (e) {
      print('❌ Internet connection: SOCKET ERROR - $e');
    } catch (e) {
      print('❌ Internet connection: FAILED - $e');
    }
    return false;
  }

  // Test Firebase connection
  Future<bool> testFirebaseConnection() async {
    try {
      print('🔄 Testing Firebase connection...');

      // Test Firebase connection by attempting to read from a public collection
      // This doesn't require write permissions
      await _firestore
          .collection('users')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      print('✅ Firebase connection: SUCCESS');
      return true;
    } on TimeoutException catch (e) {
      print('❌ Firebase connection: TIMEOUT - $e');
    } on FirebaseException catch (e) {
      // Permission denied for read is still a successful connection test
      if (e.code == 'permission-denied') {
        print(
            '✅ Firebase connection: SUCCESS (permission-denied indicates server is reachable)');
        return true;
      }
      print(
          '❌ Firebase connection: FIREBASE ERROR - Code: ${e.code}, Message: ${e.message}');
    } catch (e) {
      print('❌ Firebase connection: FAILED - $e');
    }
    return false;
  }

  // Enhanced connectivity check - optimized to avoid permission issues
  Future<void> ensureConnectivity() async {
    print('🔄 Checking connectivity...');

    if (!await hasInternetConnection()) {
      throw 'No internet connection. Please check your network settings and try again.';
    }

    // For Firebase connection, we'll trust that authentication methods will handle their own connection errors
    print('✅ Internet connectivity confirmed');
  }

  // Check current authentication status with detailed logging
  bool checkAuthenticationStatus() {
    User? user = _auth.currentUser;
    if (user != null) {
      print('User is authenticated: ${user.email} (UID: ${user.uid})');
      return true;
    }
    print('No authenticated user found');
    return false;
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Attempting login with email: $email');

      // Check connectivity first
      await ensureConnectivity();

      UserCredential result = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 30));

      print('✅ Login successful for user: ${result.user?.email}');

      // Update last login time
      await updateLastLogin();

      return result;
    } on TimeoutException catch (e) {
      print('❌ Login timeout: $e');
      throw 'Login request timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      // Handle the PigeonUserDetails type cast error specifically
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type \'List<Object?>\'')) {
        print(
            '⚠️ PigeonUserDetails/type cast error detected - checking auth state...');

        // Wait a moment for auth state to update
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if user is actually authenticated despite the error
        User? user = _auth.currentUser;
        if (user != null) {
          print(
              '✅ User is authenticated despite type cast error: ${user.email}');

          // Update last login since authentication succeeded
          await updateLastLogin();

          // Return null to indicate we should use auth state stream
          return null;
        }
      }

      print('❌ Unexpected error during login: $e');
      throw e.toString();
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔄 Attempting registration with email: $email');

      // Check connectivity first
      await ensureConnectivity();

      UserCredential result = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 30));

      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
          'emailVerified': false,
          'profileComplete': false,
          'digitalId': null,
        }).timeout(const Duration(seconds: 30));

        // Send email verification
        await user.sendEmailVerification();

        print('✅ Registration successful for user: ${user.email}');
      }

      return result;
    } on TimeoutException catch (e) {
      print('❌ Registration timeout: $e');
      throw 'Registration request timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print(
          '❌ Firebase Auth Error during registration - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      // Handle the PigeonUserDetails type cast error specifically
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('type \'List<Object?>\'')) {
        print(
            '⚠️ PigeonUserDetails/type cast error during registration - checking auth state...');

        // Wait a moment for auth state to update
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if user is actually authenticated despite the error
        User? user = _auth.currentUser;
        if (user != null) {
          print(
              '✅ User registration succeeded despite type cast error: ${user.email}');

          // Try to create the user document since registration succeeded
          try {
            await user.updateDisplayName(name);
            await _firestore.collection('users').doc(user.uid).set({
              'uid': user.uid,
              'name': name.trim(),
              'email': email.trim(),
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'isActive': true,
              'emailVerified': false,
              'profileComplete': false,
              'digitalId': null,
            });

            // Send email verification
            await user.sendEmailVerification();
          } catch (firestoreError) {
            print(
                '❌ Error creating user document after successful registration: $firestoreError');
          }

          // Return null to indicate we should use auth state stream
          return null;
        }
      }

      print('❌ Unexpected error during registration: $e');
      throw e.toString();
    }
  }

  // Sign out with comprehensive cleanup
  Future<void> signOut() async {
    try {
      print('🔄 Starting sign out process...');

      // Clear any cached auth data first
      await clearAuthData();

      // Sign out from Firebase
      await _auth.signOut();

      // Verify signout was successful
      await Future.delayed(const Duration(milliseconds: 100));
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('✅ User signed out successfully');
      } else {
        print(
            '⚠️ Warning: User still appears to be signed in after signout attempt');
        // Force another signout attempt
        await _auth.signOut();
      }
    } catch (e) {
      print('❌ Error signing out: $e');
      throw 'Error signing out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('🔄 Sending password reset email to: $email');

      // Check connectivity first
      await ensureConnectivity();

      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(const Duration(seconds: 30));

      print('✅ Password reset email sent to: $email');
    } on TimeoutException catch (e) {
      print('❌ Password reset timeout: $e');
      throw 'Password reset request timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print(
          '❌ Firebase Auth Error during password reset - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during password reset: $e');
      throw e.toString();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      print('🔄 Updating user profile...');

      // Check connectivity first
      await ensureConnectivity();

      User? user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Update Firestore document
        Map<String, dynamic> updateData = {
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (displayName != null) updateData['name'] = displayName;
        if (photoURL != null) updateData['photoURL'] = photoURL;

        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(updateData)
            .timeout(const Duration(seconds: 30));

        print('✅ User profile updated successfully');
      }
    } on TimeoutException catch (e) {
      print('❌ Profile update timeout: $e');
      throw 'Profile update timed out. Please check your connection and try again.';
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw 'Error updating profile. Please try again.';
    }
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));

        print('✅ Last login updated for user: ${user.email}');
      }
    } catch (e) {
      // Silent fail for login time update
      print('⚠️ Error updating last login: $e');
    }
  }

  // Get user data from Firestore with enhanced error handling
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return null;
      }

      print('🔄 Getting user data for: ${user.uid}');

      // Skip connectivity check - let Firebase handle the connection
      // await ensureConnectivity();

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server)) // Force server fetch
          .timeout(const Duration(seconds: 30));

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>?;
        print('✅ User data retrieved successfully');
        return userData;
      } else {
        print('⚠️ User document does not exist, creating...');

        // Create user document if it doesn't exist
        final newUserData = {
          'uid': user.uid,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
          'emailVerified': user.emailVerified,
          'profileComplete': false,
          'digitalId': null,
        };

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUserData)
            .timeout(const Duration(seconds: 30));

        print('✅ User document created successfully');

        // Return the created data with current timestamp
        return {
          ...newUserData,
          'createdAt': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        };
      }
    } on TimeoutException catch (e) {
      print('❌ Get user data timeout: $e');
      throw 'Failed to load user data: Request timed out. Please check your connection and try again.';
    } on FirebaseException catch (e) {
      print(
          '❌ Firebase error getting user data: Code: ${e.code}, Message: ${e.message}');
      if (e.code == 'permission-denied') {
        throw 'Failed to load user data: Permission denied. Please check your Firestore security rules or contact support.';
      }
      throw 'Failed to load user data: ${e.message ?? 'Firebase error occurred'}';
    } catch (e) {
      print('❌ Error getting user data: $e');
      throw 'Failed to load user data: ${e.toString()}';
    }
  }

  // Update user digital ID with enhanced error handling and retry logic
  Future<void> updateUserDigitalId(Map<String, dynamic> digitalIdData) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        User? user = _auth.currentUser;
        if (user == null) {
          throw 'No authenticated user found. Please log in again.';
        }

        print(
            '🔄 Updating digital ID for user: ${user.uid} (Attempt ${retryCount + 1}/$maxRetries)');

        // Skip connectivity check - let Firebase handle the connection
        // await ensureConnectivity();

        // Encrypt sensitive data before storing
        final encryptedData = _encryptSensitiveData(digitalIdData);

        // Use WriteBatch for atomic operation
        WriteBatch batch = _firestore.batch();

        // Update main user document
        DocumentReference userRef =
            _firestore.collection('users').doc(user.uid);
        batch.update(userRef, {
          'digitalId': encryptedData,
          'profileComplete': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create/update separate digital ID document
        DocumentReference digitalIdRef =
            _firestore.collection('digitalIds').doc(user.uid);
        batch.set(
            digitalIdRef,
            {
              'userId': user.uid,
              'digitalId': encryptedData,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
              'isActive': true,
            },
            SetOptions(merge: true));

        // Commit the batch with timeout
        await batch.commit().timeout(const Duration(seconds: 60));

        print('✅ Digital ID updated successfully in Firebase');
        return; // Success, exit retry loop
      } on TimeoutException catch (e) {
        print('❌ Digital ID update timeout (Attempt ${retryCount + 1}): $e');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw 'Failed to save digital ID: Request timed out after $maxRetries attempts. Please check your connection and try again.';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on FirebaseException catch (e) {
        print(
            '❌ Firebase error updating digital ID: Code: ${e.code}, Message: ${e.message}');

        // Don't retry for certain errors
        if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
          throw 'Permission denied: ${e.message}. Please check your Firestore security rules or log out and log in again.';
        }

        retryCount++;
        if (retryCount >= maxRetries) {
          throw 'Failed to save digital ID: Firebase error (${e.code}). Please try again later.';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      } catch (e) {
        print('❌ Error updating digital ID: $e');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw 'Failed to save digital ID: ${e.toString()}';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  // Delete user digital ID with enhanced error handling
  Future<void> deleteUserDigitalId() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        User? user = _auth.currentUser;
        if (user == null) {
          throw 'No authenticated user found. Please log in again.';
        }

        print(
            '🗑️ Deleting digital ID for user: ${user.uid} (Attempt ${retryCount + 1}/$maxRetries)');

        // Use WriteBatch for atomic operation
        WriteBatch batch = _firestore.batch();

        // Update main user document to remove digital ID
        DocumentReference userRef =
            _firestore.collection('users').doc(user.uid);
        batch.update(userRef, {
          'digitalId': FieldValue.delete(),
          'profileComplete': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Delete the separate digital ID document
        DocumentReference digitalIdRef =
            _firestore.collection('digitalIds').doc(user.uid);
        batch.delete(digitalIdRef);

        // Commit the batch with timeout
        await batch.commit().timeout(const Duration(seconds: 60));

        print('✅ Digital ID deleted successfully from Firebase');

        // Delete the OTP for security purposes after successful deletion
        try {
          await deleteStoredOtp();
          print('🔒 OTP deleted for security after Digital ID deletion');
        } catch (otpError) {
          print(
              '⚠️ Warning: Could not delete OTP after Digital ID deletion: $otpError');
          // Don't throw here as the main operation (deletion) was successful
        }

        return; // Success, exit retry loop
      } on TimeoutException catch (e) {
        print('❌ Digital ID deletion timeout (Attempt ${retryCount + 1}): $e');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw 'Failed to delete digital ID: Request timed out after $maxRetries attempts. Please check your connection and try again.';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on FirebaseException catch (e) {
        print(
            '❌ Firebase error deleting digital ID: Code: ${e.code}, Message: ${e.message}');

        // Don't retry for certain errors
        if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
          throw 'Permission denied: ${e.message}. Please check your Firestore security rules or log out and log in again.';
        }

        retryCount++;
        if (retryCount >= maxRetries) {
          throw 'Failed to delete digital ID: Firebase error (${e.code}). Please try again later.';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      } catch (e) {
        print('❌ Error deleting digital ID: $e');
        retryCount++;

        if (retryCount >= maxRetries) {
          throw 'Failed to delete digital ID: ${e.toString()}';
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }

  // Get user's digital ID with enhanced error handling
  Future<Map<String, dynamic>?> getUserDigitalId() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return null;
      }

      print('🔄 Getting digital ID for user: ${user.uid}');

      // Skip connectivity check - let Firebase handle the connection
      // await ensureConnectivity();

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 30));

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>?;
        final digitalIdData = userData?['digitalId'];

        if (digitalIdData != null) {
          print('✅ Digital ID retrieved successfully');
          // Decrypt sensitive data before returning
          return _decryptSensitiveData(digitalIdData);
        } else {
          print('ℹ️ No digital ID found for user');
          return null;
        }
      } else {
        print('❌ User document does not exist');
        return null;
      }
    } on TimeoutException catch (e) {
      print('❌ Get digital ID timeout: $e');
      throw 'Failed to load digital ID: Request timed out. Please check your connection and try again.';
    } on FirebaseException catch (e) {
      print(
          '❌ Firebase error getting digital ID: Code: ${e.code}, Message: ${e.message}');
      if (e.code == 'permission-denied') {
        throw 'Failed to load digital ID: Permission denied. Please check your Firestore security rules or contact support.';
      }
      throw 'Failed to load digital ID: ${e.message ?? 'Firebase error occurred'}';
    } catch (e) {
      print('❌ Error getting digital ID: $e');
      throw 'Failed to load digital ID: ${e.toString()}';
    }
  }

  // Delete digital ID
  Future<void> deleteDigitalId() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No authenticated user found. Please log in again.';
      }

      print('🔄 Deleting digital ID for user: ${user.uid}');

      // Check connectivity first
      await ensureConnectivity();

      // Use WriteBatch for atomic operation
      WriteBatch batch = _firestore.batch();

      // Remove from users document
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);
      batch.update(userRef, {
        'digitalId': FieldValue.delete(),
        'profileComplete': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from digitalIds collection
      DocumentReference digitalIdRef =
          _firestore.collection('digitalIds').doc(user.uid);
      batch.delete(digitalIdRef);

      await batch.commit().timeout(const Duration(seconds: 30));

      print('✅ Digital ID deleted successfully');
    } on TimeoutException catch (e) {
      print('❌ Delete digital ID timeout: $e');
      throw 'Failed to delete digital ID: Request timed out. Please check your connection and try again.';
    } catch (e) {
      print('❌ Error deleting digital ID: $e');
      throw 'Error deleting digital ID. Please try again.';
    }
  }

  // Verify digital ID with QR code
  Future<Map<String, dynamic>?> verifyDigitalIdByQR(String qrData) async {
    try {
      print('🔄 Verifying digital ID with QR code...');

      // Check connectivity first
      await ensureConnectivity();

      // Decode QR data
      final qrJson = json.decode(qrData);
      final userId = qrJson['id']?.toString().replaceAll('TH', '');

      if (userId != null && userId.isNotEmpty) {
        DocumentSnapshot doc = await _firestore
            .collection('digitalIds')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 30));

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['isActive'] == true) {
            print('✅ Digital ID verified successfully');
            return {
              'valid': true,
              'name': data['digitalId']['officialName'],
              'verified': data['digitalId']['emailVerified'] ?? false,
              'issued': data['createdAt'],
            };
          }
        }
      }

      print('❌ Invalid or inactive digital ID');
      return {'valid': false, 'error': 'Invalid or inactive digital ID'};
    } on TimeoutException catch (e) {
      print('❌ QR verification timeout: $e');
      return {
        'valid': false,
        'error': 'Verification timed out. Please try again.'
      };
    } catch (e) {
      print('❌ Error verifying digital ID: $e');
      return {'valid': false, 'error': 'Verification failed: ${e.toString()}'};
    }
  }

  // Encrypt sensitive data
  Map<String, dynamic> _encryptSensitiveData(Map<String, dynamic> data) {
    final encryptedData = Map<String, dynamic>.from(data);

    // List of fields to encrypt
    final sensitiveFields = ['idNumber', 'address'];

    for (String field in sensitiveFields) {
      if (encryptedData[field] != null) {
        final originalValue = encryptedData[field].toString();
        final bytes = utf8.encode(originalValue);
        final digest = sha256.convert(bytes);

        // Store both encrypted hash and encrypted value (for demo purposes)
        encryptedData['${field}_hash'] = digest.toString();
        // In production, use proper encryption library like encrypt package
        encryptedData['${field}_encrypted'] = _simpleEncrypt(originalValue);
      }
    }

    // Add encryption metadata
    encryptedData['encrypted'] = true;
    encryptedData['encryptionVersion'] = '1.0';
    encryptedData['encryptedAt'] = DateTime.now().toIso8601String();

    return encryptedData;
  }

  // Decrypt sensitive data
  Map<String, dynamic> _decryptSensitiveData(Map<String, dynamic> data) {
    if (data['encrypted'] != true) {
      return data; // Not encrypted, return as is
    }

    final decryptedData = Map<String, dynamic>.from(data);

    // List of fields to decrypt
    final sensitiveFields = ['idNumber', 'address'];

    for (String field in sensitiveFields) {
      if (decryptedData['${field}_encrypted'] != null) {
        // In production, use proper decryption
        decryptedData[field] =
            _simpleDecrypt(decryptedData['${field}_encrypted']);
        // Remove encrypted versions from returned data
        decryptedData.remove('${field}_encrypted');
        decryptedData.remove('${field}_hash');
      }
    }

    return decryptedData;
  }

  // Simple encryption (replace with proper encryption in production)
  String _simpleEncrypt(String text) {
    final bytes = utf8.encode(text);
    final encoded = base64.encode(bytes);
    return encoded;
  }

  // Simple decryption (replace with proper decryption in production)
  String _simpleDecrypt(String encrypted) {
    try {
      final bytes = base64.decode(encrypted);
      return utf8.decode(bytes);
    } catch (e) {
      return encrypted; // Return as is if decryption fails
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      print('🔄 Checking if email exists: $email');

      // Check connectivity first
      await ensureConnectivity();

      final signInMethods = await _auth
          .fetchSignInMethodsForEmail(email.trim())
          .timeout(const Duration(seconds: 30));

      bool exists = signInMethods.isNotEmpty;
      print(exists ? '✅ Email exists' : 'ℹ️ Email does not exist');
      return exists;
    } on TimeoutException catch (e) {
      print('❌ Check email timeout: $e');
      return false;
    } catch (e) {
      print('❌ Error checking email existence: $e');
      return false;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'No authenticated user found. Please log in again.';
      }

      print('🔄 Deleting user account: ${user.uid}');

      // Check connectivity first
      await ensureConnectivity();

      // Use WriteBatch for atomic operation
      WriteBatch batch = _firestore.batch();

      // Delete user document from Firestore
      batch.delete(_firestore.collection('users').doc(user.uid));

      // Delete digital ID document if exists
      batch.delete(_firestore.collection('digitalIds').doc(user.uid));

      // Commit batch first
      await batch.commit().timeout(const Duration(seconds: 30));

      // Then delete the authentication account
      await user.delete().timeout(const Duration(seconds: 30));

      print('✅ User account deleted successfully');
    } on TimeoutException catch (e) {
      print('❌ Account deletion timeout: $e');
      throw 'Account deletion timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print(
          '❌ Firebase Auth Error during account deletion - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during account deletion: $e');
      throw 'Error deleting account. Please try again.';
    }
  }

  // Re-authenticate user (required for sensitive operations)
  Future<void> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Re-authenticating user...');

      // Check connectivity first
      await ensureConnectivity();

      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password.trim(),
        );

        await user
            .reauthenticateWithCredential(credential)
            .timeout(const Duration(seconds: 30));

        print('✅ User re-authenticated successfully');
      }
    } on TimeoutException catch (e) {
      print('❌ Re-authentication timeout: $e');
      throw 'Re-authentication timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print(
          '❌ Firebase Auth Error during re-authentication - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during re-authentication: $e');
      throw 'Re-authentication failed. Please try again.';
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      print('🔄 Changing password...');

      // Check connectivity first
      await ensureConnectivity();

      User? user = _auth.currentUser;
      if (user != null) {
        await user
            .updatePassword(newPassword)
            .timeout(const Duration(seconds: 30));

        // Update password change timestamp in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'passwordChangedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 30));

        print('✅ Password changed successfully');
      }
    } on TimeoutException catch (e) {
      print('❌ Password change timeout: $e');
      throw 'Password change timed out. Please check your connection and try again.';
    } on FirebaseAuthException catch (e) {
      print(
          '❌ Firebase Auth Error during password change - Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ Unexpected error during password change: $e');
      throw 'Error changing password. Please try again.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        print('🔄 Sending email verification to: ${user.email}');

        // Check connectivity first
        await ensureConnectivity();

        await user.sendEmailVerification().timeout(const Duration(seconds: 30));
        print('✅ Email verification sent to: ${user.email}');
      }
    } on TimeoutException catch (e) {
      print('❌ Send verification timeout: $e');
      throw 'Email verification request timed out. Please check your connection and try again.';
    } catch (e) {
      print('❌ Error sending email verification: $e');
      throw 'Error sending verification email. Please try again.';
    }
  }

  // Reload user to get updated info
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload().timeout(const Duration(seconds: 30));

        // Update email verification status in Firestore if changed
        User? reloadedUser = _auth.currentUser;
        if (reloadedUser != null) {
          await _firestore.collection('users').doc(reloadedUser.uid).update({
            'emailVerified': reloadedUser.emailVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 30));
        }
      }
    } catch (e) {
      print('⚠️ Error reloading user: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 30));

        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>?;

          return {
            'hasDigitalId': userData?['digitalId'] != null,
            'emailVerified': user.emailVerified,
            'profileComplete': userData?['profileComplete'] ?? false,
            'memberSince': userData?['createdAt'],
            'lastLogin': userData?['lastLogin'],
            'accountStatus':
                userData?['isActive'] == true ? 'Active' : 'Inactive',
          };
        }
      }
      return {};
    } catch (e) {
      print('❌ Error getting user statistics: $e');
      return {};
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'preferences': preferences,
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 30));

        print('✅ User preferences updated successfully');
      }
    } catch (e) {
      print('❌ Error updating preferences: $e');
      throw 'Error updating preferences. Please try again.';
    }
  }

  // Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 30));

        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>?;
          return userData?['preferences'];
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting user preferences: $e');
      return null;
    }
  }

  // Handle Firebase Auth exceptions with detailed logging
  String _handleAuthException(FirebaseAuthException e) {
    print('🔍 Handling Firebase Auth Exception: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please check your email or register.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'invalid-verification-id':
        return 'Invalid verification ID. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'permission-denied':
        return 'Permission denied. Please log out and log in again.';
      case 'unauthenticated':
        return 'Authentication required. Please log in again.';
      default:
        print('❌ Unhandled Firebase Auth Error: ${e.code} - ${e.message}');
        return 'Authentication failed: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  // Clear any cached auth data and perform cleanup
  Future<void> clearAuthData() async {
    try {
      print('🔄 Clearing authentication data...');

      // Clear any local cache or stored data if needed
      // This is where you'd clear SharedPreferences or other local storage

      print('✅ Authentication data cleared successfully');
    } catch (e) {
      print('❌ Error clearing auth data: $e');
    }
  }

  // Enhanced debug method with more details
  void debugAuthState() {
    User? user = _auth.currentUser;
    print('=== AUTH DEBUG INFO ===');
    print('Current User: ${user?.email ?? 'None'}');
    print('User ID: ${user?.uid ?? 'None'}');
    print('Email Verified: ${user?.emailVerified ?? 'N/A'}');
    print('Display Name: ${user?.displayName ?? 'None'}');
    print('Photo URL: ${user?.photoURL ?? 'None'}');
    print('Phone Number: ${user?.phoneNumber ?? 'None'}');
    print(
        'Provider Data: ${user?.providerData.map((e) => e.providerId).join(', ') ?? 'None'}');
    print('Is Anonymous: ${user?.isAnonymous ?? 'N/A'}');
    print('Creation Time: ${user?.metadata.creationTime ?? 'Unknown'}');
    print('Last Sign In Time: ${user?.metadata.lastSignInTime ?? 'Unknown'}');
    print('Tenant ID: ${user?.tenantId ?? 'None'}');
    print('=======================');
  }

  // Batch operations for admin or maintenance tasks
  Future<void> batchUpdateUserData(Map<String, dynamic> updates) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        print('🔄 Performing batch update...');

        // Check connectivity first
        await ensureConnectivity();

        WriteBatch batch = _firestore.batch();

        // Update main user document
        DocumentReference userRef =
            _firestore.collection('users').doc(user.uid);
        batch.update(userRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If digital ID exists, update it too
        if (updates.containsKey('digitalId')) {
          DocumentReference digitalIdRef =
              _firestore.collection('digitalIds').doc(user.uid);
          batch.update(digitalIdRef, {
            'digitalId': updates['digitalId'],
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit().timeout(const Duration(seconds: 60));
        print('✅ Batch update completed successfully');
      }
    } on TimeoutException catch (e) {
      print('❌ Batch update timeout: $e');
      throw 'Batch update timed out. Please check your connection and try again.';
    } catch (e) {
      print('❌ Error in batch update: $e');
      throw 'Error updating user data. Please try again.';
    }
  }

  // ==================== REAL EMAIL OTP SERVICE ====================

  // Generate and store OTP in Firebase
  Future<String> _generateAndStoreOtp(String email, String purpose) async {
    try {
      print('🔄 Generating OTP for $email for $purpose');

      // Generate secure 6-digit OTP
      final random = Random.secure();
      final otp = (100000 + random.nextInt(900000)).toString();

      // Store OTP in Firestore with expiration (5 minutes)
      await _firestore.collection('temp_otp').doc(currentUser?.uid).set({
        'otp': otp,
        'email': email,
        'purpose': purpose,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
        'used': false,
      });

      print('✅ OTP generated and stored: $otp');
      return otp;
    } catch (e) {
      print('❌ Error generating OTP: $e');
      throw 'Failed to generate verification code. Please try again.';
    }
  }

  // Send OTP via real SMTP email
  Future<bool> sendEmailOtp(String email, String purpose) async {
    try {
      print('� Sending real email OTP to $email');
      print('📧 Configuration status: ${EmailConfig.configurationStatus}');

      // Check if email is configured
      if (!EmailConfig.isConfigured) {
        print('❌ Email not configured - falling back to demo mode');
        return _sendDemoOtp(email, purpose);
      }

      // Generate and store OTP
      final otp = await _generateAndStoreOtp(email, purpose);

      // Configure SMTP server
      final smtpServer = SmtpServer(
        EmailConfig.smtpHost,
        port: EmailConfig.smtpPort,
        username: EmailConfig.senderEmail,
        password: EmailConfig.senderPassword,
        ignoreBadCertificate: false,
        ssl: false,
        allowInsecure: false,
      );

      // Create the email message
      final message = Message()
        ..from = Address(EmailConfig.senderEmail, EmailConfig.senderName)
        ..recipients.add(email)
        ..subject = '${EmailConfig.appName} - Verification Code'
        ..html = _generateEmailHtml(otp, purpose, email);

      // Send the email
      print('📧 Attempting to send email via ${EmailConfig.smtpHost}...');
      final sendReport = await send(message, smtpServer);

      print('📧 Email send result: $sendReport');
      print('✅ Email sent successfully to $email');
      return true;
    } catch (e) {
      print('❌ Error sending email: $e');

      // Fallback to demo mode if email fails
      print('📧 Falling back to demo mode due to email error');
      return _sendDemoOtp(email, purpose);
    }
  }

  // Generate HTML email template
  String _generateEmailHtml(String otp, String purpose, String email) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verification Code</title>
          <style>
              body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
              .header { background: linear-gradient(135deg, #021024 0%, #052659 100%); color: white; padding: 30px; text-align: center; }
              .logo { font-size: 24px; font-weight: bold; margin-bottom: 10px; }
              .content { padding: 30px; }
              .otp-box { background: #f8f9fa; border: 2px solid #007bff; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0; }
              .otp-code { font-size: 32px; font-weight: bold; color: #007bff; letter-spacing: 4px; margin: 10px 0; font-family: 'Courier New', monospace; }
              .warning { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 15px; margin: 20px 0; color: #856404; }
              .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; border-top: 1px solid #dee2e6; }
              .highlight { color: #007bff; font-weight: bold; }
              .time { color: #6c757d; font-size: 14px; }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="header">
                  <div class="logo">✈️ ${EmailConfig.appName.toUpperCase()}</div>
                  <p>Secure Verification Code</p>
              </div>
              
              <div class="content">
                  <h2>Hello!</h2>
                  <p>You've requested to <span class="highlight">$purpose</span> for your ${EmailConfig.appName} account registered with <span class="highlight">$email</span>.</p>
                  
                  <div class="otp-box">
                      <p>Your verification code is:</p>
                      <div class="otp-code">$otp</div>
                      <p><small>This code is valid for <strong>5 minutes only</strong></small></p>
                  </div>
                  
                  <div class="warning">
                      <strong>🔒 Security Notice:</strong>
                      <ul>
                          <li>Never share this code with anyone</li>
                          <li>${EmailConfig.appName} will never ask for this code via phone or email</li>
                          <li>If you didn't request this code, please ignore this email</li>
                          <li>This code can only be used once</li>
                      </ul>
                  </div>
                  
                  <div style="margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                      <p><strong>Request Details:</strong></p>
                      <p>Purpose: <span class="highlight">$purpose</span></p>
                      <p class="time">Requested: ${DateTime.now().toString().substring(0, 19)}</p>
                      <p class="time">Expires: ${DateTime.now().add(Duration(minutes: 5)).toString().substring(0, 19)}</p>
                  </div>
                  
                  <p>If you're having trouble, please contact our support team.</p>
              </div>
              
              <div class="footer">
                  <p>This is an automated message from ${EmailConfig.appName}</p>
                  <p>© 2025 ${EmailConfig.appName}. All rights reserved.</p>
                  <p style="font-size: 12px;">Support: ${EmailConfig.supportEmail}</p>
              </div>
          </div>
      </body>
      </html>
    ''';
  }

  // Fallback demo OTP method
  Future<bool> _sendDemoOtp(String email, String purpose) async {
    try {
      print('📱 Sending demo OTP for testing');

      // Generate and store OTP
      final otp = await _generateAndStoreOtp(email, purpose);

      // Just return true since this is demo mode
      print('🎭 DEMO MODE: OTP for $email is: $otp');
      print('⚠️ In production, check your email for the verification code');

      return true;
    } catch (e) {
      print('❌ Error in demo OTP: $e');
      return false;
    }
  }

  // Get stored OTP for demonstration (in production, this wouldn't be exposed)
  Future<String?> getStoredOtpForDemo() async {
    try {
      final otpDoc =
          await _firestore.collection('temp_otp').doc(currentUser?.uid).get();

      if (!otpDoc.exists) {
        return null;
      }

      final data = otpDoc.data()!;
      final expiresAt = data['expiresAt'] as int;
      final used = data['used'] as bool;

      // Check if expired or used
      if (DateTime.now().millisecondsSinceEpoch > expiresAt || used) {
        return null;
      }

      return data['otp'] as String;
    } catch (e) {
      print('❌ Error getting stored OTP: $e');
      return null;
    }
  }

  // Configure email settings (call this with your credentials)
  static void configureEmailSettings({
    required String senderEmail,
    required String senderPassword,
  }) {
    // You can use this method to update email credentials at runtime
    // For now, we'll use the constants defined above
    print('📧 Email configuration would be updated');
    print('📧 Sender: $senderEmail');
    print('📧 Password: ${senderPassword.replaceAll(RegExp(r'.'), '*')}');
  }

  // Verify OTP
  Future<bool> verifyEmailOtp(String inputOtp) async {
    try {
      print('🔄 Verifying OTP: $inputOtp');

      final otpDoc =
          await _firestore.collection('temp_otp').doc(currentUser?.uid).get();

      if (!otpDoc.exists) {
        print('❌ No OTP found for user');
        return false;
      }

      final data = otpDoc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = data['expiresAt'] as int;
      final used = data['used'] as bool;

      // Check if OTP is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        print('❌ OTP expired');
        // Clean up expired OTP
        await _firestore.collection('temp_otp').doc(currentUser?.uid).delete();
        return false;
      }

      // Check if OTP is already used
      if (used) {
        print('❌ OTP already used');
        return false;
      }

      // Check if OTP matches
      if (storedOtp != inputOtp) {
        print('❌ OTP does not match');
        return false;
      }

      // Mark OTP as used and DELETE for security
      await _firestore.collection('temp_otp').doc(currentUser?.uid).delete();

      print('✅ OTP verified successfully and deleted for security');
      return true;
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return false;
    }
  }

  // Delete OTP from database immediately (security method)
  Future<void> deleteStoredOtp() async {
    try {
      print('🔒 Deleting stored OTP for security');
      await _firestore.collection('temp_otp').doc(currentUser?.uid).delete();
      print('✅ OTP deleted successfully for security');
    } catch (e) {
      print('❌ Error deleting OTP: $e');
    }
  }

  // Clean up expired OTPs (call this periodically)
  Future<void> cleanupExpiredOtps() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredOtps = await _firestore
          .collection('temp_otp')
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();

      for (final doc in expiredOtps.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Cleaned up ${expiredOtps.docs.length} expired OTPs');
    } catch (e) {
      print('❌ Error cleaning up expired OTPs: $e');
    }
  }

  // Health check method
  Future<Map<String, bool>> performHealthCheck() async {
    final results = <String, bool>{};

    print('🔄 Performing health check...');

    // Check internet connectivity
    results['internetConnection'] = await hasInternetConnection();

    // Check Firebase connectivity
    results['firebaseConnection'] = await testFirebaseConnection();

    // Check authentication status
    results['userAuthenticated'] = isAuthenticated;

    print('📊 Health check results: $results');
    return results;
  }
}
