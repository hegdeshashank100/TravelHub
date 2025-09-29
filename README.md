# 🌍 Travelers Hub - Complete Travel Companion

A comprehensive Flutter application designed for discovering and exploring tourist destinations across India with AI-powered recommendations and real-time location tracking.

## ✨ Features

### 🏠 **Homepage**

- User location detection and address display
- Nearby tourist attractions discovery
- Integration with tourism APIs for accurate location data
- "See all" functionality for expanded exploration

### 🔍 **Smart Search**

- Gemini Flash 2.0 AI integration for intelligent destination recommendations
- Hybrid coordinate system (OpenTripMap API + Gemini) for accurate GPS data
- Speed-optimized API responses with caching
- Place name-based Google Maps navigation

### 🗺️ **Interactive Maps**

- Real-time location tracking
- Tourist place discovery within user's range
- Google Maps integration for navigation
- Accurate coordinate resolution system

### 🛡️ **Security & Privacy**

- Background location tracking with user consent
- Persistent notifications for active location sharing
- Firebase Authentication integration
- Secure user data management

### 📱 **Digital Identity**

- QR code generation for user profiles
- Secure digital ID system
- Profile management and verification

### 🎯 **Additional Features**

- Real-time Firestore data synchronization
- Background location services (works when app is closed)
- Camera integration for lens/scanning features
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)

## 🚀 Technology Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Core)
- **AI Integration**: Google Gemini Flash 2.0 API
- **Location Services**: Geolocator, Geocoding
- **Maps**: Google Maps integration via URL launcher
- **APIs**: OpenTripMap API for tourism data
- **Background Services**: flutter_background_service
- **Notifications**: flutter_local_notifications
- **State Management**: Provider pattern
- **Architecture**: Clean Architecture with service layer

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Firebase project setup
- Google Gemini API key
- OpenTripMap API key

## 🛠️ Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/hegdeshashank100/Travelers-Hub.git
   cd Travelers-Hub
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Add your `google-services.json` to `android/app/`
   - Add your `GoogleService-Info.plist` to `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Set up API keys**

   - Add your Gemini API key to the app configuration
   - Add your OpenTripMap API key

5. **Generate launcher icons**

   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

6. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔧 Configuration

### Background Location Tracking

The app includes sophisticated background location tracking that continues working even when the app is closed:

- Enable in Security settings
- Grant "Allow all the time" location permission
- Persistent notification shows live location updates
- Firestore receives location updates every minute when app is closed
- 1-second updates when app is active

### API Integration

- **Gemini Flash 2.0**: AI-powered destination recommendations
- **OpenTripMap**: Tourist attraction data and coordinates
- **Firebase**: Real-time data synchronization and authentication

## 📂 Project Structure

```
lib/
├── config/           # Configuration files
├── providers/        # State management
├── services/         # API and background services
├── utils/           # Utility functions
├── main.dart        # App entry point
├── homepage.dart    # Main dashboard
├── searchpage.dart  # Search functionality
├── map.dart         # Maps integration
├── security.dart    # Security settings
├── settings.dart    # App settings
├── login.dart       # Authentication
└── ...
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Shashank Hegde**

- Email: hegdeshashank100@gmail.com
- GitHub: [@hegdeshashank100](https://github.com/hegdeshashank100)

## 🙏 Acknowledgments

- Google Gemini team for AI API
- OpenTripMap for tourism data
- Firebase team for backend services
- Flutter team for the amazing framework

## 🐛 Bug Reports & Feature Requests

Please use the [GitHub Issues](https://github.com/hegdeshashank100/Travelers-Hub/issues) page to report bugs or request features.

---

**Made with ❤️ for travelers by travelers**
