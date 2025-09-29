import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/background_location_service.dart';
import 'providers/localization_provider.dart';
import 'providers/theme_provider.dart';
import 'login.dart';
import 'homepage.dart';
import 'searchpage.dart';
import 'map.dart';
import 'digitalid.dart';
import 'account_details.dart';
import 'security.dart';
import 'settings.dart';
import 'lens.dart';

// Global user provider for accessing user data across the app
class UserProvider extends ChangeNotifier {
  User? _currentUser;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();

  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userData => _userData;

  // Get the actual user name from Firebase or fallback to display name
  String get userName {
    if (_currentUser != null) {
      // First try to get from user data
      if (_userData?['name'] != null &&
          _userData!['name'].toString().isNotEmpty) {
        return _userData!['name'].toString();
      }
      // Then try Firebase display name
      if (_currentUser!.displayName != null &&
          _currentUser!.displayName!.isNotEmpty) {
        return _currentUser!.displayName!;
      }
      // Extract name from email if available
      if (_currentUser!.email != null && _currentUser!.email!.isNotEmpty) {
        String emailName = _currentUser!.email!.split('@')[0];
        // Convert email username to proper name format
        return emailName
            .replaceAll('.', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
      }
    }
    return 'Traveler';
  }

  // Get the actual user email
  String get userEmail => _currentUser?.email ?? 'user@example.com';

  // Check if user email is verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // Get verification status text
  String get verificationStatus =>
      isEmailVerified ? 'Verified Traveler' : 'Unverified User';

  void setUser(User? user) {
    _currentUser = user;
    if (user != null) {
      _loadUserData();
    } else {
      _userData = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        _userData = await _authService.getUserData();
        notifyListeners();
      } catch (e) {
        print('Error loading user data: $e');
        // Still notify listeners even if user data fails to load
        notifyListeners();
      }
    }
  }

  void clearUser() {
    _currentUser = null;
    _userData = null;
    notifyListeners();
  }

  // Force refresh user data
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;
      await _loadUserData();
    }
  }
}

// Permission handler utility
class AppPermissionHandler {
  static Future<bool> requestStoragePermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    return statuses[Permission.storage]?.isGranted == true ||
        statuses[Permission.manageExternalStorage]?.isGranted == true;
  }

  static Future<bool> requestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      return true;
    }

    PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    return statuses[Permission.location]?.isGranted == true ||
        statuses[Permission.locationWhenInUse]?.isGranted == true;
  }

  static Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    return statuses.values.any((status) => status.isGranted);
  }

  static Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> requestAllPermissions(BuildContext context) async {
    // Show permission explanation dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: Color.fromARGB(255, 236, 233, 233),
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text:
                      'This app needs various permissions to provide the best experience:\n',
                ),
                TextSpan(
                  text: 'Note : Live location is being tracked\n\n',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // ✅ Bold
                    color: Color.fromARGB(
                        255, 183, 88, 81), // 🔥 Optional: makes it stand out
                  ),
                ),
                TextSpan(
                  text: '• Storage: Save QR codes and documents\n'
                      '• Camera: Scan QR codes\n'
                      '• Location: Travel tracking\n'
                      '• Bluetooth: Offline messaging\n'
                      '• Notifications: Important alerts',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    // Request permissions
    await requestStoragePermissions();
    await requestCameraPermission();
    await requestLocationPermissions();
    await requestBluetoothPermissions();
    await requestNotificationPermission();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize background location service
    await BackgroundLocationService.initialize();

    // Start global location tracking after Firebase initialization
    LocationService.instance.startGlobalLocationTracking();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  runApp(const TravelersHubApp());
}

class TravelersHubApp extends StatelessWidget {
  const TravelersHubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer2<LocalizationProvider, ThemeProvider>(
        builder: (context, localizationProvider, themeProvider, child) {
          return MaterialApp(
            title: 'Travelers Hub',
            debugShowCheckedModeBanner: false,
            locale: localizationProvider.currentLocale,
            theme: themeProvider.getThemeData(),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const MainScreen(),
              '/digitalid': (context) => const DigitalIdPage(),
              '/account': (context) => const AccountDetailsPage(),
              '/security': (context) => const SecurityPage(),
              '/settings': (context) => const SettingsPage(),
              '/lens': (context) => const LensPage(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializePermissions();
  }

  void _initializeUser() {
    _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      }
    });
  }

  void _initializePermissions() async {
    // Request permissions after a short delay to allow UI to stabilize
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        try {
          await AppPermissionHandler.requestAllPermissions(context);
        } catch (e) {
          print('Error requesting permissions: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.currentUser != null) {
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MainScreenBody();
  }
}

class MainScreenBody extends StatefulWidget {
  const MainScreenBody({Key? key}) : super(key: key);

  @override
  _MainScreenBodyState createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    MapPage(),
    SizedBox(key: ValueKey('profile-placeholder')),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final appTheme = themeProvider.currentAppTheme;

        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: const ProfileDrawer(),
          body: Container(
            decoration: BoxDecoration(
              color: appTheme.backgroundColor,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Fixed header with proper user data display
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        color: const Color(0xFF052659),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Travelers Hub',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Welcome, ${userProvider.userName}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/lens'),
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Main content with proper flex
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final appTheme = themeProvider.currentAppTheme;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: appTheme.surfaceColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: appTheme.subtextColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItem(Icons.home_outlined, 0),
              _buildNavItem(Icons.search, 1),
              _buildSOSButton(),
              _buildNavItem(Icons.map_outlined, 2),
              _buildNavItem(Icons.person_outline, 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 3) {
          _scaffoldKey.currentState?.openDrawer();
        } else if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Feature Coming Soon'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Drawer(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF052659),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userProvider.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userProvider.userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.credit_card,
                            title: 'Digital ID',
                            onTap: () =>
                                Navigator.pushNamed(context, '/digitalid'),
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.person,
                            title: 'Account Details',
                            onTap: () =>
                                Navigator.pushNamed(context, '/account'),
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.security,
                            title: 'Security & Privacy',
                            onTap: () =>
                                Navigator.pushNamed(context, '/security'),
                          ),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.settings,
                            title: 'Settings',
                            onTap: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                          const Spacer(),
                          _buildDrawerItem(
                            context: context,
                            icon: Icons.logout,
                            title: 'Logout',
                            isLogout: true,
                            onTap: () => _logout(context),
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    Provider.of<UserProvider>(context, listen: false).clearUser();
    AuthService authService = AuthService();
    await authService.signOut();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
