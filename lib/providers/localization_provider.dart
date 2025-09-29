import 'package:flutter/material.dart';

class LocalizationProvider extends ChangeNotifier {
  Locale _currentLocale =
      const Locale('en', 'IN'); // Default to English (India)

  Locale get currentLocale => _currentLocale;

  // Supported languages with their codes and names
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en_IN': {'name': 'English', 'nativeName': 'English'},
    'hi_IN': {'name': 'Hindi', 'nativeName': 'हिन्दी'},
    'ta_IN': {'name': 'Tamil', 'nativeName': 'தமிழ்'},
    'te_IN': {'name': 'Telugu', 'nativeName': 'తెలుగు'},
    'bn_IN': {'name': 'Bengali', 'nativeName': 'বাংলা'},
    'mr_IN': {'name': 'Marathi', 'nativeName': 'मराठी'},
    'gu_IN': {'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
    'kn_IN': {'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
    'ml_IN': {'name': 'Malayalam', 'nativeName': 'മലയാളം'},
    'pa_IN': {'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ'},
    'or_IN': {'name': 'Odia', 'nativeName': 'ଓଡ଼ିଆ'},
  };

  void setLocale(String languageCode) {
    final parts = languageCode.split('_');
    _currentLocale = Locale(parts[0], parts[1]);
    notifyListeners();
  }

  String getLocalizedText(String key) {
    return AppLocalizations.getText(_currentLocale.toString(), key);
  }
}

class AppLocalizations {
  // Translations for all supported languages
  static const Map<String, Map<String, String>> _localizedValues = {
    'en_IN': {
      // Navigation
      'home': 'Home',
      'search': 'Search',
      'security': 'Security',
      'account': 'Account',
      'settings': 'Settings',

      // Home Page
      'welcome': 'Welcome',
      'discover_india': 'Discover Incredible India',
      'explore_destinations': 'Explore amazing destinations across the country',
      'popular_destinations': 'Popular Destinations',
      'nearby_places': 'Nearby Places',
      'trending_now': 'Trending Now',

      // Settings
      'customize_experience': 'Customize your experience',
      'app_preferences': 'App Preferences',
      'language': 'Language',
      'select_language': 'Select your preferred language',
      'currency': 'Currency',
      'choose_currency': 'Choose your default currency',
      'theme': 'Theme',
      'customize_appearance': 'Customize your app appearance',
      'data_storage': 'Data & Storage',
      'auto_backup': 'Auto Backup',
      'backup_description': 'Automatically backup your data to cloud',
      'offline_mode': 'Offline Mode',
      'offline_description': 'Download content for offline access',
      'high_quality_images': 'High Quality Images',
      'hq_images_description': 'Download and display images in high quality',
      'cache_size_limit': 'Cache Size Limit',
      'cache_description': 'Maximum storage for cached data',
      'clear_cache': 'Clear Cache',
      'clear_cache_description':
          'Free up storage space by clearing cached data',
      'audio_haptics': 'Audio & Haptics',
      'sound_effects': 'Sound Effects',
      'sound_description': 'Play sounds for app interactions',
      'haptic_feedback': 'Haptic Feedback',
      'haptic_description': 'Feel vibrations for button presses',
      'about_support': 'About & Support',
      'about_app': 'About Travelers Hub',
      'about_description': 'Learn more about our app and company',
      'help_support': 'Help & Support',
      'help_description': 'Get help with using the app',
      'send_feedback': 'Send Feedback',
      'feedback_description': 'Share your thoughts and suggestions',
      'rate_app': 'Rate App',
      'rate_description': 'Rate us on the app store',

      // Security
      'location_tracking': 'Location Tracking',
      'enable_location': 'Enable location tracking for better recommendations',
      'privacy_security': 'Privacy & Security',

      // Common
      'cancel': 'Cancel',
      'save': 'Save',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
    },

    'hi_IN': {
      // Navigation
      'home': 'होम',
      'search': 'खोज',
      'security': 'सुरक्षा',
      'account': 'खाता',
      'settings': 'सेटिंग्स',

      // Home Page
      'welcome': 'स्वागत',
      'discover_india': 'अविश्वसनीय भारत की खोज करें',
      'explore_destinations': 'देश भर के अद्भुत स्थलों का अन्वेषण करें',
      'popular_destinations': 'लोकप्रिय गंतव्य',
      'nearby_places': 'आस-पास के स्थान',
      'trending_now': 'अभी ट्रेंडिंग',

      // Settings
      'customize_experience': 'अपने अनुभव को अनुकूलित करें',
      'app_preferences': 'ऐप प्राथमिकताएं',
      'language': 'भाषा',
      'select_language': 'अपनी पसंदीदा भाषा चुनें',
      'currency': 'मुद्रा',
      'choose_currency': 'अपनी डिफ़ॉल्ट मुद्रा चुनें',
      'theme': 'थीम',
      'customize_appearance': 'अपने ऐप की दिखावट को अनुकूलित करें',
      'data_storage': 'डेटा और भंडारण',
      'auto_backup': 'स्वचालित बैकअप',
      'backup_description':
          'अपने डेटा को स्वचालित रूप से क्लाउड में बैकअप करें',
      'offline_mode': 'ऑफ़लाइन मोड',
      'offline_description': 'ऑफ़लाइन एक्सेस के लिए सामग्री डाउनलोड करें',
      'high_quality_images': 'उच्च गुणवत्ता वाली छवियां',
      'hq_images_description':
          'उच्च गुणवत्ता में छवियां डाउनलोड और प्रदर्शित करें',
      'cache_size_limit': 'कैश साइज़ सीमा',
      'cache_description': 'कैश्ड डेटा के लिए अधिकतम भंडारण',
      'clear_cache': 'कैश साफ़ करें',
      'clear_cache_description':
          'कैश्ड डेटा साफ़ करके स्टोरेज स्थान मुक्त करें',
      'audio_haptics': 'ऑडियो और हैप्टिक्स',
      'sound_effects': 'साउंड इफेक्ट्स',
      'sound_description': 'ऐप इंटरैक्शन के लिए ध्वनि चलाएं',
      'haptic_feedback': 'हैप्टिक फीडबैक',
      'haptic_description': 'बटन दबाने पर कंपन महसूस करें',
      'about_support': 'के बारे में और सहायता',
      'about_app': 'ट्रैवलर्स हब के बारे में',
      'about_description': 'हमारे ऐप और कंपनी के बारे में अधिक जानें',
      'help_support': 'सहायता और समर्थन',
      'help_description': 'ऐप का उपयोग करने में सहायता प्राप्त करें',
      'send_feedback': 'फीडबैक भेजें',
      'feedback_description': 'अपने विचार और सुझाव साझा करें',
      'rate_app': 'ऐप को रेट करें',
      'rate_description': 'ऐप स्टोर पर हमें रेट करें',

      // Security
      'location_tracking': 'स्थान ट्रैकिंग',
      'enable_location': 'बेहतर सिफारिशों के लिए स्थान ट्रैकिंग सक्षम करें',
      'privacy_security': 'गोपनीयता और सुरक्षा',

      // Common
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'ok': 'ठीक है',
      'yes': 'हां',
      'no': 'नहीं',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
    },

    'ta_IN': {
      // Navigation
      'home': 'முகப்பு',
      'search': 'தேடு',
      'security': 'பாதுகாப்பு',
      'account': 'கணக்கு',
      'settings': 'அமைப்புகள்',

      // Home Page
      'welcome': 'வரவேற்கிறோம்',
      'discover_india': 'நம்பமுடியாத இந்தியாவை கண்டறியுங்கள்',
      'explore_destinations': 'நாடு முழுவதும் அற்புதமான இடங்களை ஆராயுங்கள்',
      'popular_destinations': 'பிரபலமான இடங்கள்',
      'nearby_places': 'அருகிலுள்ள இடங்கள்',
      'trending_now': 'இப்போது ட்ரெண்டிங்',

      // Settings
      'customize_experience': 'உங்கள் அனுபவத்தை தனிப்பயனாக்குங்கள்',
      'app_preferences': 'ஆப் விருப்பத்தேர்வுகள்',
      'language': 'மொழி',
      'select_language': 'உங்கள் விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
      'currency': 'நாணயம்',
      'choose_currency': 'உங்கள் இயல்புநிலை நாணயத்தைத் தேர்வுசெய்யவும்',
      'theme': 'தீம்',
      'customize_appearance': 'உங்கள் ஆப்பின் தோற்றத்தை தனிப்பயனாக்குங்கள்',
      'data_storage': 'தரவு & சேமிப்பு',
      'auto_backup': 'தானியங்கு காப்புப்பிரதி',
      'backup_description':
          'உங்கள் தரவை தானாக மேகக்கணினியில் காப்புப்பிரதி எடுக்கவும்',
      'offline_mode': 'ஆஃப்லைன் பயன்முறை',
      'offline_description': 'ஆஃப்லைன் அணுகலுக்காக உள்ளடக்கத்தை பதிவிறக்கவும்',
      'high_quality_images': 'உயர் தர படங்கள்',
      'hq_images_description': 'உயர் தரத்தில் படங்களை பதிவிறக்கி காண்பிக்கவும்',
      'cache_size_limit': 'கேச் அளவு வரம்பு',
      'cache_description': 'கேச் செய்யப்பட்ட தரவுக்கான அதிகபட்ச சேமிப்பு',
      'clear_cache': 'கேச் அழிக்கவும்',
      'clear_cache_description':
          'கேச் செய்யப்பட்ட தரவை அழித்து சேமிப்பு இடத்தை மुக்தமாக்குங்கள்',
      'audio_haptics': 'ஆடியோ & ஹாப்டிக்ஸ்',
      'sound_effects': 'ஒலி விளைவுகள்',
      'sound_description': 'ஆப் தொடர்புகளுக்கு ஒலிகளை இயக்கவும்',
      'haptic_feedback': 'ஹாப்டிக் பின்னூட்டம்',
      'haptic_description': 'பொத்தான் அழுத்தங்களுக்கு அதிர்வுகளை உணருங்கள்',
      'about_support': 'பற்றி & ஆதரவு',
      'about_app': 'டிராவலர்ஸ் ஹப் பற்றி',
      'about_description':
          'எங்கள் ஆப் மற்றும் நிறுவனத்தைப் பற்றி மேலும் அறியுங்கள்',
      'help_support': 'உதவி & ஆதரவு',
      'help_description': 'ஆப்பை பயன்படுத்த உதவி பெறுங்கள்',
      'send_feedback': 'கருத்து அனுப்பவும்',
      'feedback_description':
          'உங்கள் எண்ணங்கள் மற்றும் பரிந்துரைகளை பகிருங்கள்',
      'rate_app': 'ஆப்பை மதிப்பிடுங்கள்',
      'rate_description': 'ஆப் ஸ்டோரில் எங்களை மதிப்பிடுங்கள்',

      // Security
      'location_tracking': 'இருப்பிட கண்காணிப்பு',
      'enable_location':
          'சிறந்த பரிந்துரைகளுக்கு இருப்பிட கண்காணிப்பை இயக்கவும்',
      'privacy_security': 'தனியுரிமை & பாதுகாப்பு',

      // Common
      'cancel': 'ரத்துசெய்',
      'save': 'சேமி',
      'ok': 'சரி',
      'yes': 'ஆம்',
      'no': 'இல்லை',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
    },

    // Add more languages - I'll include a few key ones for brevity
    'te_IN': {
      'home': 'హోమ్',
      'search': 'వెతకండి',
      'security': 'భద్రత',
      'account': 'ఖాతా',
      'settings': 'సెట్టింగులు',
      'welcome': 'స్వాగతం',
      'discover_india': 'అద్భుతమైన భారతదేశాన్ని కనుగొనండి',
      'language': 'భాష',
      'theme': 'థీమ్',
      'cancel': 'రద్దుచేయి',
      'save': 'భద్రపరచు',
      'ok': 'సరే',
    },

    'bn_IN': {
      'home': 'হোম',
      'search': 'অনুসন্ধান',
      'security': 'নিরাপত্তা',
      'account': 'অ্যাকাউন্ট',
      'settings': 'সেটিংস',
      'welcome': 'স্বাগতম',
      'discover_india': 'অবিশ্বাস্য ভারত আবিষ্কার করুন',
      'language': 'ভাষা',
      'theme': 'থিম',
      'cancel': 'বাতিল',
      'save': 'সংরক্ষণ',
      'ok': 'ঠিক আছে',
    },

    'mr_IN': {
      'home': 'होम',
      'search': 'शोध',
      'security': 'सुरक्षा',
      'account': 'खाते',
      'settings': 'सेटिंग्ज',
      'welcome': 'स्वागत',
      'discover_india': 'अविश्वसनीय भारताचा शोध घ्या',
      'language': 'भाषा',
      'theme': 'थीम',
      'cancel': 'रद्द करा',
      'save': 'जतन करा',
      'ok': 'ठीक आहे',
    },

    'gu_IN': {
      'home': 'હોમ',
      'search': 'શોધ',
      'security': 'સુરક્ષા',
      'account': 'ખાતું',
      'settings': 'સેટિંગ્સ',
      'welcome': 'સ્વાગત',
      'discover_india': 'અવિશ્વસનીય ભારત શોધો',
      'language': 'ભાષા',
      'theme': 'થીમ',
      'cancel': 'રદ કરો',
      'save': 'સાચવો',
      'ok': 'બરાબર',
    },

    'kn_IN': {
      'home': 'ಮುಖ್ಯಪುಟ',
      'search': 'ಹುಡುಕು',
      'security': 'ಭದ್ರತೆ',
      'account': 'ಖಾತೆ',
      'settings': 'ಸಂಯೋಜನೆಗಳು',
      'welcome': 'ಸ್ವಾಗತ',
      'discover_india': 'ಅದ್ಭುತ ಭಾರತವನ್ನು ಅನ್ವೇಷಿಸಿ',
      'language': 'ಭಾಷೆ',
      'theme': 'ಥೀಮ್',
      'cancel': 'ರದ್ದುಮಾಡು',
      'save': 'ಉಳಿಸು',
      'ok': 'ಸರಿ',
    },

    'ml_IN': {
      'home': 'ഹോം',
      'search': 'തിരയുക',
      'security': 'സുരക്ഷ',
      'account': 'അക്കൗണ്ട്',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'welcome': 'സ്വാഗതം',
      'discover_india': 'അവിശ്വസനീയ ഇന്ത്യ കണ്ടെത്തുക',
      'language': 'ഭാഷ',
      'theme': 'തീം',
      'cancel': 'റദ്ദാക്കുക',
      'save': 'സേവ് ചെയ്യുക',
      'ok': 'ശരി',
    },

    'pa_IN': {
      'home': 'ਘਰ',
      'search': 'ਖੋਜ',
      'security': 'ਸੁਰੱਖਿਆ',
      'account': 'ਖਾਤਾ',
      'settings': 'ਸੈਟਿੰਗਜ਼',
      'welcome': 'ਸਵਾਗਤ',
      'discover_india': 'ਸ਼ਾਨਦਾਰ ਭਾਰਤ ਦੀ ਖੋਜ ਕਰੋ',
      'language': 'ਭਾਸ਼ਾ',
      'theme': 'ਥੀਮ',
      'cancel': 'ਰੱਦ ਕਰੋ',
      'save': 'ਸੇਵ ਕਰੋ',
      'ok': 'ਠੀਕ ਹੈ',
    },

    'or_IN': {
      'home': 'ହୋମ',
      'search': 'ଖୋଜ',
      'security': 'ସୁରକ୍ଷା',
      'account': 'ଖାତା',
      'settings': 'ସେଟିଂଗୁଡ଼ିକ',
      'welcome': 'ସ୍ୱାଗତ',
      'discover_india': 'ଅବିଶ୍ୱସନୀୟ ଭାରତ ଆବିଷ୍କାର କରନ୍ତୁ',
      'language': 'ଭାଷା',
      'theme': 'ଥିମ୍',
      'cancel': 'ବାତିଲ୍',
      'save': 'ସେଭ୍',
      'ok': 'ଠିକ ଅଛି',
    },
  };

  static String getText(String locale, String key) {
    return _localizedValues[locale]?[key] ??
        _localizedValues['en_IN']?[key] ??
        key;
  }
}
