// Email Configuration for SMTP
//
// INSTRUCTIONS:
// 1. Replace 'your-email@gmail.com' with your actual Gmail address
// 2. Replace 'your-app-password' with your Gmail App Password
//
// HOW TO GET GMAIL APP PASSWORD:
// 1. Go to your Google Account settings
// 2. Security → 2-Step Verification (must be enabled)
// 3. App passwords → Generate new app password
// 4. Select "Mail" and your device
// 5. Copy the generated 16-character password (no spaces)
//
// EXAMPLE: If your Gmail is "john.doe@gmail.com" and app password is "abcd efgh ijkl mnop"
// Then replace below values accordingly

class EmailConfig {
  // YOUR EMAIL CREDENTIALS - UPDATE THESE VALUES
  static const String senderEmail = ''; // ← Replace with your Gmail
  static const String senderPassword = ''; // ← Replace with your App Password
  static const String senderName = 'Travelers Hub';

  // SMTP Configuration for Gmail (don't change these)
  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 587;

  // Email template settings
  static const String appName = 'Travelers Hub';
  static const String supportEmail = 'support@travelershub.com';

  // Validation
  static bool get isConfigured {
    return senderEmail != 'your-email@gmail.com' &&
        senderPassword != 'your-app-password' &&
        senderEmail.isNotEmpty &&
        senderPassword.isNotEmpty;
  }

  static String get configurationStatus {
    if (isConfigured) {
      return '✅ Email configuration is complete';
    } else {
      return '⚠️ Email configuration required - Update email_config.dart';
    }
  }
}

// ALTERNATIVE EMAIL PROVIDERS
// If you're not using Gmail, update the SMTP settings:

// For Outlook/Hotmail:
// static const String smtpHost = 'smtp-mail.outlook.com';
// static const int smtpPort = 587;

// For Yahoo:
// static const String smtpHost = 'smtp.mail.yahoo.com';
// static const int smtpPort = 587;

// For custom email providers, check with your provider for SMTP settings
