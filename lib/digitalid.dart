import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart'; // Import for UserProvider access
import 'services/auth_service.dart'; // Fixed: Correct import path without ../
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';

class DigitalIdPage extends StatefulWidget {
  const DigitalIdPage({Key? key}) : super(key: key);

  @override
  _DigitalIdPageState createState() => _DigitalIdPageState();
}

class _DigitalIdPageState extends State<DigitalIdPage> {
  bool _hasDigitalId = false;
  bool _isLoading = false;
  Map<String, dynamic>? _digitalIdData;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkExistingDigitalId();
  }

  Future<void> _checkExistingDigitalId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user already has a digital ID
      final userData = await _authService.getUserData();
      if (userData != null && userData['digitalId'] != null) {
        setState(() {
          _hasDigitalId = true;
          _digitalIdData = userData['digitalId'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasDigitalId = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking digital ID: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading digital ID data: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Safe substring helper to prevent RangeError
  String _safeSubstring(String text, int start, [int? end]) {
    if (text.isEmpty) return text;

    int safeStart = start < 0 ? 0 : (start > text.length ? text.length : start);

    if (end == null) return text.substring(safeStart);

    int safeEnd = end < 0 ? 0 : (end > text.length ? text.length : end);
    if (safeEnd <= safeStart) return '';

    return text.substring(safeStart, safeEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<UserProvider, ThemeProvider, LocalizationProvider>(
      builder:
          (context, userProvider, themeProvider, localizationProvider, child) {
        final theme = themeProvider.currentAppTheme;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: theme.backgroundColor,
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Digital ID',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${userProvider.userName}\'s Digital Identity',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Expanded(
                          child: _hasDigitalId
                              ? _buildDigitalIdCard(userProvider, theme)
                              : _buildCreateIdPrompt(userProvider, theme),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateIdPrompt(UserProvider userProvider, AppTheme theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      size: 40,
                      color: theme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create Digital ID',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hi ${userProvider.userName}! Create your secure digital identity card with government ID verification.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleCreateIdPress(userProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_card, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Create ID',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your data is encrypted and securely stored',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Show verification warning for unverified users
                  if (!userProvider.isEmailVerified) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email verification required to create Digital ID',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalIdCard(UserProvider userProvider, AppTheme theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ID Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRAVELERS HUB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Digital Identity Card',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.flight_takeoff,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Profile section with real user data
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _digitalIdData?['officialName'] ??
                                userProvider.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: userProvider.isEmailVerified
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              userProvider.isEmailVerified
                                  ? 'Verified Member'
                                  : 'Unverified',
                              style: TextStyle(
                                color: userProvider.isEmailVerified
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Details with real user data
                Column(
                  children: [
                    _buildDetailRow('Member ID',
                        'TH${_safeSubstring(userProvider.currentUser?.uid ?? '123456789', 0, 9)}'),
                    const SizedBox(height: 12),
                    _buildDetailRow('Email', userProvider.userEmail),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Gov ID Type', _digitalIdData?['idType'] ?? 'Not Set'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'ID Number',
                        _digitalIdData?['idNumber'] != null
                            ? (_digitalIdData!['idNumber'].toString().length > 4
                                ? '${_safeSubstring(_digitalIdData!['idNumber'].toString(), 0, 4)}****'
                                : _digitalIdData!['idNumber'].toString())
                            : 'Not Set'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Address',
                        _digitalIdData?['address'] != null
                            ? _digitalIdData!['address'].toString().length > 20
                                ? '${_safeSubstring(_digitalIdData!['address'].toString(), 0, 20)}...'
                                : _digitalIdData!['address'].toString()
                            : 'Not Set'),
                  ],
                ),

                const SizedBox(height: 30),

                // QR Code section with real data
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (_digitalIdData?['qrCode'] != null)
                        QrImageView(
                          data: _digitalIdData!['qrCode'],
                          version: QrVersions.auto,
                          size: 100.0,
                          backgroundColor: Colors.white,
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan for verification',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Verification status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: userProvider.isEmailVerified
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: userProvider.isEmailVerified
                    ? Colors.green.withOpacity(0.5)
                    : Colors.orange.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  userProvider.isEmailVerified ? Icons.verified : Icons.warning,
                  color: userProvider.isEmailVerified
                      ? Colors.green
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.isEmailVerified
                            ? 'Verified Account'
                            : 'Verification Pending',
                        style: TextStyle(
                          color: userProvider.isEmailVerified
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userProvider.isEmailVerified
                            ? '${userProvider.userName}\'s identity has been verified'
                            : 'Please verify your email to activate full features',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Update ID button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleUpdateIdPress(userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Update ID Information'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Delete Digital ID button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteConfirmation(userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever, size: 20),
                  SizedBox(width: 8),
                  Text('Delete Digital ID'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCreateIdPress(UserProvider userProvider) {
    // Check if user is verified before allowing Digital ID creation
    if (!userProvider.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are not verified! Please verify your email first to create Digital ID.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Verify',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to account details page for verification
              Navigator.pushNamed(context, '/account');
            },
          ),
        ),
      );
      return;
    }

    // If verified, proceed with creating Digital ID
    _showCreateIdForm(userProvider);
  }

  void _handleUpdateIdPress(UserProvider userProvider) {
    // Check if user is verified before allowing Digital ID update
    if (!userProvider.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are not verified! Please verify your email first to update Digital ID.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Verify',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to account details page for verification
              Navigator.pushNamed(context, '/account');
            },
          ),
        ),
      );
      return;
    }

    // If verified, proceed with updating Digital ID
    _showCreateIdForm(userProvider, isUpdate: true);
  }

  void _showCreateIdForm(UserProvider userProvider, {bool isUpdate = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return CreateIdForm(
          userProvider: userProvider,
          isUpdate: isUpdate,
          existingData: _digitalIdData,
          onIdCreated: (data) {
            setState(() {
              _hasDigitalId = true;
              _digitalIdData = data;
            });
            // Reload the entire page data to ensure fresh state
            _checkExistingDigitalId();
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return DeleteIdConfirmation(
          userProvider: userProvider,
          onIdDeleted: () {
            setState(() {
              _hasDigitalId = false;
              _digitalIdData = null;
            });
            _checkExistingDigitalId();
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class CreateIdForm extends StatefulWidget {
  final UserProvider userProvider;
  final bool isUpdate;
  final Map<String, dynamic>? existingData;
  final Function(Map<String, dynamic>) onIdCreated;

  const CreateIdForm({
    Key? key,
    required this.userProvider,
    required this.isUpdate,
    this.existingData,
    required this.onIdCreated,
  }) : super(key: key);

  @override
  _CreateIdFormState createState() => _CreateIdFormState();
}

class _CreateIdFormState extends State<CreateIdForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedIdType = 'Aadhaar Card';
  bool _isLoading = false;

  final List<String> _idTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Voter ID',
    'Driving License',
    'Passport',
    'Ration Card',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  /// Safe substring helper to prevent RangeError
  String _safeSubstring(String text, int start, [int? end]) {
    if (text.isEmpty) return text;

    int safeStart = start < 0 ? 0 : (start > text.length ? text.length : start);

    if (end == null) return text.substring(safeStart);

    int safeEnd = end < 0 ? 0 : (end > text.length ? text.length : end);
    if (safeEnd <= safeStart) return '';

    return text.substring(safeStart, safeEnd);
  }

  void _initializeForm() {
    if (widget.isUpdate && widget.existingData != null) {
      _nameController.text = widget.existingData!['officialName'] ?? '';
      _idNumberController.text = widget.existingData!['idNumber'] ?? '';
      _addressController.text = widget.existingData!['address'] ?? '';
      _selectedIdType = widget.existingData!['idType'] ?? 'Aadhaar Card';
    } else {
      _nameController.text = widget.userProvider.userName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF052659),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.isUpdate
                            ? 'Update Digital ID'
                            : 'Create Digital ID',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Enter your details as per your government ID. All information is encrypted and stored securely.',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Official Name Field
                        const Text(
                          'Official Name (as per Government ID)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              prefixIcon:
                                  Icon(Icons.person, color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: 'Enter full name as per ID',
                              hintStyle: TextStyle(color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your official name';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Government ID Type Dropdown
                        const Text(
                          'Government ID Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedIdType,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF052659),
                              style: const TextStyle(color: Colors.white),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white70),
                              items: _idTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(_getIdIcon(type),
                                          color: Colors.white70, size: 20),
                                      const SizedBox(width: 8),
                                      Text(type),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedIdType = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ID Number Field
                        Text(
                          '$_selectedIdType Number',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextFormField(
                            controller: _idNumberController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: _selectedIdType == 'Aadhaar Card'
                                ? TextInputType.number
                                : TextInputType.text,
                            decoration: InputDecoration(
                              prefixIcon: Icon(_getIdIcon(_selectedIdType),
                                  color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: _getIdHint(_selectedIdType),
                              hintStyle: const TextStyle(color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your $_selectedIdType number';
                              }
                              if (!_validateIdNumber(
                                  value.trim(), _selectedIdType)) {
                                return 'Please enter a valid $_selectedIdType number';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Address Field
                        const Text(
                          'Full Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextFormField(
                            controller: _addressController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.location_on,
                                    color: Colors.white70),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: 'Enter your complete address as per ID',
                              hintStyle: TextStyle(color: Colors.white60),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your address';
                              }
                              if (value.trim().length < 10) {
                                return 'Please enter a complete address';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Create/Update Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createDigitalId,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          widget.isUpdate
                                              ? Icons.update
                                              : Icons.create,
                                          size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isUpdate
                                            ? 'Update Digital ID'
                                            : 'Create Digital ID',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIdIcon(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return Icons.credit_card;
      case 'PAN Card':
        return Icons.account_balance_wallet;
      case 'Voter ID':
        return Icons.how_to_vote;
      case 'Driving License':
        return Icons.drive_eta;
      case 'Passport':
        return Icons.flight;
      case 'Ration Card':
        return Icons.receipt;
      default:
        return Icons.credit_card;
    }
  }

  String _getIdHint(String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return 'XXXX XXXX XXXX';
      case 'PAN Card':
        return 'ABCDE1234F';
      case 'Voter ID':
        return 'ABC1234567';
      case 'Driving License':
        return 'DL-1420110012345';
      case 'Passport':
        return 'A1234567';
      case 'Ration Card':
        return 'Enter ration card number';
      default:
        return 'Enter ID number';
    }
  }

  bool _validateIdNumber(String value, String idType) {
    switch (idType) {
      case 'Aadhaar Card':
        return RegExp(r'^\d{12}$').hasMatch(value.replaceAll(' ', ''));
      case 'PAN Card':
        return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value);
      case 'Voter ID':
        return value.length >= 8 && value.length <= 10;
      case 'Driving License':
        return value.length >= 10;
      case 'Passport':
        return RegExp(r'^[A-Z]{1}[0-9]{7}$').hasMatch(value);
      case 'Ration Card':
        return value.length >= 8;
      default:
        return value.length >= 5;
    }
  }

  Future<void> _createDigitalId() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create digital ID data
      final digitalIdData = {
        'officialName': _nameController.text.trim(),
        'idType': _selectedIdType,
        'idNumber': _idNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'email': widget.userProvider.userEmail,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': widget.userProvider.currentUser?.uid,
      };

      // Generate QR code data
      final qrData = json.encode({
        'name': digitalIdData['officialName'],
        'id':
            'TH${_safeSubstring(widget.userProvider.currentUser?.uid ?? '123456789', 0, 9)}',
        'type': digitalIdData['idType'],
        'verified': widget.userProvider.isEmailVerified,
        'issued': DateTime.now().toIso8601String(),
      });

      digitalIdData['qrCode'] = qrData;

      // Save to Firebase with better error handling
      final authService = AuthService();
      await authService.updateUserDigitalId(digitalIdData);

      // Update local state
      widget.onIdCreated(digitalIdData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Close the form first
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isUpdate
                        ? 'Digital ID updated successfully! Page will refresh automatically.'
                        : 'Digital ID created successfully! Page will refresh automatically.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error creating digital ID: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Error: Please check your internet connection and try again'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class DeleteIdConfirmation extends StatefulWidget {
  final UserProvider userProvider;
  final VoidCallback onIdDeleted;

  const DeleteIdConfirmation({
    Key? key,
    required this.userProvider,
    required this.onIdDeleted,
  }) : super(key: key);

  @override
  _DeleteIdConfirmationState createState() => _DeleteIdConfirmationState();
}

class _DeleteIdConfirmationState extends State<DeleteIdConfirmation> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  int _remainingTime = 300; // 5 minutes in seconds
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel(); // Cancel any existing timer
    setState(() {
      _remainingTime = 300; // 5 minutes
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isOtpSent = false;
        });
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the real email OTP service
      final authService = AuthService();
      final success = await authService.sendEmailOtp(
          widget.userProvider.userEmail, 'Delete Digital ID');

      if (success) {
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });

        _startOtpTimer();

        // Get the demo OTP to show to user (only if email sending failed)
        // final demoOtp = await authService.getStoredOtpForDemo();

        // Show success message with demo OTP only if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verification code sent',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Text(
                //   'Please check your email inbox and spam folder.',
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.9),
                //     fontSize: 14,
                //   ),
                // ),
                // Only show demo OTP if it exists (fallback mode)
                // if (demoOtp != null) ...[
                //   const SizedBox(height: 8),
                //   Container(
                //     padding: const EdgeInsets.all(8),
                //     decoration: BoxDecoration(
                //       color: Colors.orange.withOpacity(0.3),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     // child: Row(
                //     //   children: [
                //     //     const Icon(Icons.warning,
                //     //         color: Colors.orange, size: 16),
                //     //     const SizedBox(width: 8),
                //     //     Expanded(
                //     //       child: Text(
                //     //         // 'Email service unavailable. Demo code: $demoOtp',
                //     //         style: const TextStyle(
                //     //           fontWeight: FontWeight.bold,
                //     //           fontSize: 13,
                //     //         ),
                //     //       ),
                //     //     ),
                //     //   ],
                //     // ),
                //   ),
                // ],
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to send verification code. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error sending verification code: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtpAndDelete() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter a valid 6-digit code.'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP using the real service
      final authService = AuthService();
      final isValidOtp = await authService.verifyEmailOtp(enteredOtp);

      if (isValidOtp) {
        // Delete the digital ID from Firebase
        await authService.deleteUserDigitalId();

        // Ensure OTP is completely removed for security (redundant safety)
        try {
          await authService.deleteStoredOtp();
        } catch (e) {
          print('⚠️ OTP cleanup warning: $e');
          // Don't fail the operation if OTP cleanup fails
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Close the modal
          Navigator.pop(context);

          // Call the callback to update parent state
          widget.onIdDeleted();

          // Show success message with security confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Digital ID deleted successfully! All verification data cleared.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                      'Invalid or expired verification code. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000), // Dark red background for delete action
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Delete Digital ID',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.delete_forever,
                        color: Colors.white, size: 24),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Warning: This action cannot be undone!',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Deleting your Digital ID will permanently remove all your identity information from our secure servers. You will need to create a new Digital ID if you want to use this feature again.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (!_isOtpSent) ...[
                        // Email verification step
                        const Text(
                          'Email Verification Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'To delete your Digital ID, we need to verify your identity. An OTP will be sent to your registered email address:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email, color: Colors.white70),
                              const SizedBox(width: 8),
                              Text(
                                widget.userProvider.userEmail,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Send Verification OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        // OTP verification step
                        Text(
                          'Enter Verification Code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We\'ve sent a 6-digit verification code to ${widget.userProvider.userEmail}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // OTP input field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _otpController,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 4),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              prefixIcon:
                                  Icon(Icons.security, color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: '000000',
                              hintStyle: TextStyle(
                                  color: Colors.white60, letterSpacing: 4),
                              counterText: '',
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Timer and resend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Code expires in: $_formattedTime',
                              style: TextStyle(
                                color: _remainingTime < 60
                                    ? Colors.red
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: _remainingTime == 0 ? _sendOtp : null,
                              child: Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: _remainingTime == 0
                                      ? Colors.orange
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Delete button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading || _otpController.text.length != 6
                                    ? null
                                    : _verifyOtpAndDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete_forever, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Permanently Delete Digital ID',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],

                      const SizedBox(
                          height: 40), // Extra padding to prevent overflow
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpTimer?.cancel(); // Cancel timer to prevent memory leaks
    _otpController.dispose();

    // Clean up any unused OTP for security when dialog is closed
    if (_isOtpSent && _otpController.text.trim().isEmpty) {
      _cleanupUnusedOtp();
    }

    super.dispose();
  }

  // Security method to clean up unused OTP
  void _cleanupUnusedOtp() async {
    try {
      final authService = AuthService();
      await authService.deleteStoredOtp();
      print('🔒 Cleaned up unused OTP for security');
    } catch (e) {
      print('⚠️ Could not cleanup OTP: $e');
    }
  }
}
