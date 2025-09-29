import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import for UserProvider access
import 'providers/localization_provider.dart';
import 'providers/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoBackup = true;
  bool _offlineMode = false;
  bool _highQualityImages = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;

  String _selectedCurrency = 'INR (₹)';

  double _cacheSize = 250.0; // MB

  final List<String> _currencies = [
    'INR (₹)',
    'USD (\$)',
    'EUR (€)',
    'GBP (£)'
  ];

  // Get language display name from provider
  String _getLanguageDisplayName(String languageCode) {
    final languages = LocalizationProvider.supportedLanguages;
    return languages[languageCode]?['nativeName'] ??
        languages[languageCode]?['name'] ??
        languageCode;
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
                              color: appTheme.surfaceColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: appTheme.textColor,
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
                                localizationProvider
                                    .getLocalizedText('settings'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: appTheme.textColor,
                                ),
                              ),
                              Text(
                                '${localizationProvider.getLocalizedText('customize_experience')} - ${userProvider.userName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: appTheme.subtextColor,
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
                          // User Profile Card
                          Container(
                            padding: EdgeInsets.all(20),
                            margin: EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
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
                                      SizedBox(height: 4),
                                      Text(
                                        'Member since Jan 2024',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.green.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // App Preferences
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
                                        Icons.tune,
                                        color: appTheme.accentColor,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      localizationProvider
                                          .getLocalizedText('app_preferences'),
                                      style: TextStyle(
                                        color: appTheme.textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                _buildDropdownTile(
                                  localizationProvider
                                      .getLocalizedText('language'),
                                  localizationProvider
                                      .getLocalizedText('select_language'),
                                  Icons.language,
                                  _getLanguageDisplayName(localizationProvider
                                      .currentLocale
                                      .toString()),
                                  LocalizationProvider
                                      .supportedLanguages.entries
                                      .map(
                                          (e) => _getLanguageDisplayName(e.key))
                                      .toList(),
                                  (value) {
                                    final selectedCode = LocalizationProvider
                                        .supportedLanguages.entries
                                        .firstWhere((e) =>
                                            _getLanguageDisplayName(e.key) ==
                                            value)
                                        .key;
                                    localizationProvider
                                        .setLocale(selectedCode);
                                  },
                                ),
                                SizedBox(height: 16),
                                _buildDropdownTile(
                                  localizationProvider
                                      .getLocalizedText('currency'),
                                  localizationProvider
                                      .getLocalizedText('choose_currency'),
                                  Icons.currency_rupee,
                                  _selectedCurrency,
                                  _currencies,
                                  (value) => setState(
                                      () => _selectedCurrency = value!),
                                ),
                                SizedBox(height: 16),
                                _buildDropdownTile(
                                  localizationProvider
                                      .getLocalizedText('theme'),
                                  localizationProvider
                                      .getLocalizedText('customize_appearance'),
                                  Icons.palette,
                                  themeProvider.currentTheme,
                                  ThemeProvider.themes.keys.toList(),
                                  (value) => themeProvider.setTheme(value!),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Data & Storage
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
                                        Icons.storage,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Data & Storage',
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
                                  'Auto Backup',
                                  'Automatically backup your data to cloud',
                                  Icons.backup,
                                  _autoBackup,
                                  (value) =>
                                      setState(() => _autoBackup = value),
                                ),
                                SizedBox(height: 16),
                                _buildSwitchTile(
                                  'Offline Mode',
                                  'Download content for offline access',
                                  Icons.offline_bolt,
                                  _offlineMode,
                                  (value) =>
                                      setState(() => _offlineMode = value),
                                ),
                                SizedBox(height: 16),
                                _buildSwitchTile(
                                  'High Quality Images',
                                  'Download and display images in high quality',
                                  Icons.high_quality,
                                  _highQualityImages,
                                  (value) => setState(
                                      () => _highQualityImages = value),
                                ),
                                SizedBox(height: 16),
                                _buildCacheSlider(),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Clear Cache',
                                  'Free up storage space by clearing cached data',
                                  Icons.cleaning_services,
                                  () => _showClearCacheDialog(
                                      userProvider.userName),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Audio & Haptics
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
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.volume_up,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'Audio & Haptics',
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
                                  'Sound Effects',
                                  'Play sounds for app interactions',
                                  Icons.music_note,
                                  _soundEffects,
                                  (value) =>
                                      setState(() => _soundEffects = value),
                                ),
                                SizedBox(height: 16),
                                _buildSwitchTile(
                                  'Haptic Feedback',
                                  'Feel vibrations for button presses',
                                  Icons.vibration,
                                  _hapticFeedback,
                                  (value) =>
                                      setState(() => _hapticFeedback = value),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // About & Support
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
                                        color: Colors.purple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.info,
                                        color: Colors.purple,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      'About & Support',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                _buildActionTile(
                                  'About Travelers Hub',
                                  'Learn more about our app and company',
                                  Icons.info_outline,
                                  () => _showAboutDialog(),
                                ),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Help & Support',
                                  'Get help with using the app',
                                  Icons.help_outline,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Help center opening soon')),
                                    );
                                  },
                                ),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Send Feedback',
                                  'Share your thoughts and suggestions',
                                  Icons.feedback,
                                  () => _showFeedbackDialog(
                                      userProvider.userName,
                                      userProvider.userEmail),
                                ),
                                SizedBox(height: 16),
                                _buildActionTile(
                                  'Rate App',
                                  'Rate us on the app store',
                                  Icons.star_rate,
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Thank you ${userProvider.userName.split(' ').first}! Redirecting to app store...')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // App Version
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Travelers Hub v1.0.0',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
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

  Widget _buildDropdownTile(String title, String subtitle, IconData icon,
      String value, List<String> items, Function(String?) onChanged) {
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
          DropdownButton<String>(
            value: value,
            dropdownColor: Color(0xFF052659),
            style: TextStyle(color: Colors.white),
            underline: Container(),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
            onChanged: onChanged,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
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

  Widget _buildCacheSlider() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: Colors.white70, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Size Limit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Maximum storage for cached data',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_cacheSize.round()} MB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.blue.withOpacity(0.2),
            ),
            child: Slider(
              value: _cacheSize,
              min: 50.0,
              max: 1000.0,
              divisions: 19,
              onChanged: (value) => setState(() => _cacheSize = value),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Clear Cache',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Hi $userName! This will free up ${_cacheSize.round()} MB of storage space. Downloaded images and data will need to be re-downloaded.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cache cleared successfully for $userName'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Clear Cache'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'About Travelers Hub',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Travelers Hub v1.0.0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your ultimate travel companion for discovering amazing places, planning trips, and creating unforgettable memories.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                '© 2024 Travelers Hub. All rights reserved.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(String userName, String userEmail) {
    final TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF052659),
          title: Text(
            'Send Feedback',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hi ${userName.split(' ').first}! Help us improve Travelers Hub by sharing your feedback:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Feedback sent successfully! Thank you ${userName.split(' ').first}.'),
                    backgroundColor: Colors.green,
                  ),
                );
                feedbackController.dispose();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Send Feedback'),
            ),
          ],
        );
      },
    );
  }
}
