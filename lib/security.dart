import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/location_service.dart';
import 'services/background_location_service.dart';
import 'main.dart'; // Import for UserProvider access
import 'providers/localization_provider.dart';
import 'providers/theme_provider.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({Key? key}) : super(key: key);

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _locationSharing = true; // Default to ON as requested
  bool _backgroundLocationSharing = false; // Default to OFF as requested
  bool _pushNotifications = true;
  bool _biometricLogin = false; // Default to OFF as requested

  @override
  void initState() {
    super.initState();
    // Global location tracking is already running from app startup
    print('📱 Security page loaded - Global location tracking is active');
    print(
        '🌍 Location service status: ${LocationService.instance.isGlobalTracking ? "ACTIVE" : "INACTIVE"}');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, LocalizationProvider, ThemeProvider>(
      builder:
          (context, userProvider, localizationProvider, themeProvider, child) {
        final appTheme = themeProvider.currentAppTheme;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: appTheme.backgroundColor,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with user context
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security & Privacy',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${userProvider.userName}\'s Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Account Status Card
                          Container(
                            padding: EdgeInsets.all(20),
                            margin: EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userProvider.userName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            userProvider.userEmail,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Secure',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSecurityMetric(
                                        'Biometric', _biometricLogin),
                                    _buildSecurityMetric(
                                        'Strong Password', true),
                                    _buildSecurityMetric('Background Location',
                                        _backgroundLocationSharing),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Security Section
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.security,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Security Settings',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                _buildSwitchTile(
                                  'Biometric Login',
                                  'Use fingerprint or face recognition to unlock app',
                                  Icons.fingerprint,
                                  _biometricLogin,
                                  (value) => _toggleBiometricLogin(value),
                                ),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Change Password',
                                  'Update your account password',
                                  Icons.lock,
                                  () => _showChangePasswordDialog(
                                      userProvider.userEmail),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Privacy Section
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: appTheme.accentColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.privacy_tip,
                                        color: appTheme.accentColor,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Privacy Settings',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                _buildSwitchTile(
                                  'Location Sharing',
                                  'Share your live location for safety and recommendations',
                                  Icons.location_on,
                                  _locationSharing,
                                  (value) => _toggleLocationSharing(value),
                                ),
                                SizedBox(height: 16),
                                _buildSwitchTile(
                                  'Background Location Tracking',
                                  'Track location in background even when app is closed (with notification)',
                                  Icons.my_location,
                                  _backgroundLocationSharing,
                                  (value) =>
                                      _toggleBackgroundLocationSharing(value),
                                ),
                                SizedBox(height: 16),
                                _buildSwitchTile(
                                  'Push Notifications',
                                  'Get notified about bookings and important updates',
                                  Icons.notifications,
                                  _pushNotifications,
                                  (value) => setState(
                                      () => _pushNotifications = value),
                                ),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Privacy Policy',
                                  'Read our privacy policy and terms',
                                  Icons.article,
                                  () => _showPrivacyPolicyDialog(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetric(String label, bool isEnabled) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green : Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isEnabled ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showChangePasswordDialog(String email) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF052659),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Account: $email',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() =>
                              obscureCurrentPassword = !obscureCurrentPassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon:
                            Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(
                              () => obscureNewPassword = !obscureNewPassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon:
                            Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() =>
                              obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    Navigator.pop(context);
                  },
                  child:
                      Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Password changed successfully for $email'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: Text(
                '''Privacy Policy for Travelers Hub

Last updated: December 2024

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, use our services, or contact us.

2. How We Use Your Information
- To provide and maintain our service
- To notify you about changes to our service
- To allow you to participate in interactive features
- To provide customer support
- To gather analysis or valuable information

3. Information Sharing
We do not sell, trade, or rent users' personal identification information to others.

4. Data Security
We adopt appropriate data collection, storage and processing practices and security measures to protect against unauthorized access.

5. Your Privacy Rights
You have the right to access, update or delete the information we have on you.

6. Contact Us
If you have any questions about this Privacy Policy, please contact us at privacy@travelershub.com''',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('I Understand'),
            ),
          ],
        );
      },
    );
  }

  // Location tracking is now handled by the global LocationService
  // which starts from app initialization and saves to Firestore every second

  void _toggleLocationSharing(bool value) async {
    setState(() {
      _locationSharing = value;
    });

    if (value) {
      // Request location permissions (simulated)
      bool permissionGranted = await _requestLocationPermission();

      if (permissionGranted) {
        // Start global location tracking if not already running
        if (!LocationService.instance.isGlobalTracking) {
          LocationService.instance.startGlobalLocationTracking();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 8),
                Text('Global location tracking enabled - Updates every second'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _locationSharing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Stop global location tracking
      LocationService.instance.stopGlobalLocationTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Global location tracking disabled'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _toggleBackgroundLocationSharing(bool value) async {
    setState(() {
      _backgroundLocationSharing = value;
    });

    if (value) {
      try {
        // Start real background location tracking service
        await BackgroundLocationService.startBackgroundTracking();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.my_location, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        '✅ Background location tracking enabled - Works when app is closed')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        setState(() {
          _backgroundLocationSharing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        '❌ Failed to start background tracking: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      try {
        // Stop background location tracking service
        await BackgroundLocationService.stopBackgroundTracking();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.location_disabled, color: Colors.white),
                SizedBox(width: 8),
                Text('🛑 Background location tracking stopped'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error stopping background tracking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _requestLocationPermission() async {
    // Simulate location permission request
    await Future.delayed(Duration(milliseconds: 500));
    return true; // Assume permission granted for demo
  }

  void _toggleBiometricLogin(bool value) async {
    if (value) {
      // Check if biometric is available (simulated)
      bool biometricAvailable = await _checkBiometricAvailability();

      if (biometricAvailable) {
        // Simulate biometric authentication setup
        bool authSuccess = await _authenticateWithBiometric(isSetup: true);

        if (authSuccess) {
          setState(() {
            _biometricLogin = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Biometric login enabled successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric authentication setup failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Biometric authentication not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() {
        _biometricLogin = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.white),
              SizedBox(width: 8),
              Text('Biometric login disabled'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _checkBiometricAvailability() async {
    // Simulate checking for biometric hardware
    await Future.delayed(Duration(milliseconds: 300));
    return true; // Assume biometric is available for demo
  }

  Future<bool> _authenticateWithBiometric({bool isSetup = false}) async {
    // Simulate biometric authentication
    await Future.delayed(Duration(seconds: 1));

    // Show mock biometric dialog
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.fingerprint, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                isSetup ? 'Setup Biometric' : 'Biometric Authentication',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              Text(
                isSetup
                    ? 'Touch the fingerprint sensor to setup biometric authentication'
                    : 'Touch the fingerprint sensor to authenticate',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Simulate Success'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  void dispose() {
    // Global location tracking continues running in the background
    // It will be disposed when the app terminates
    super.dispose();
  }
}
