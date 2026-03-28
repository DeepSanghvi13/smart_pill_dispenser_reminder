import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/reminder.dart';
import '../screens/admin/admin_webpage_screen.dart';
import '../screens/client/alarm/alarm_display_screen.dart';
import '../screens/client/auth/login_screen.dart';
import '../screens/client/auth/register_screen.dart';
import '../screens/client/dependents/add_dependent_screen.dart';
import '../screens/client/home/home_screen.dart';
import '../screens/client/medications/add_medication_screen.dart';
import '../screens/client/medications/barcode_scanner_screen.dart';
import '../screens/client/medications/expiry_calendar_screen.dart';
import '../screens/client/medfriends/add_caretaker_screen.dart';
import '../screens/client/manage/about_screen.dart';
import '../screens/client/manage/app_settings_screen.dart';
import '../screens/client/manage/contact_support_screen.dart';
import '../screens/client/manage/delete_account_confirm_screen.dart';
import '../screens/client/manage/create_profile_screen.dart';
import '../screens/client/manage/delete_account_reason_screen.dart';
import '../screens/client/manage/evening_reminder_screen.dart';
import '../screens/client/manage/general_settings_screen.dart';
import '../screens/client/manage/help_articles_screen.dart';
import '../screens/client/manage/help_center_screen.dart';
import '../screens/client/manage/manage_screen.dart';
import '../screens/client/manage/morning_reminder_screen.dart';
import '../screens/client/manage/professional_review_request_screen.dart';
import '../screens/client/manage/rate_medisafe_screen.dart';
import '../screens/client/manage/reminder_troubleshooting_screen.dart';
import '../screens/client/manage/send_feedback_screen.dart';
import '../screens/client/manage/share_app_screen.dart';
import '../screens/client/manage/share_help_center_screen.dart';
import '../screens/client/manage/share_medisafe_screen.dart';
import '../screens/client/manage/weekend_mode_screen.dart';
import '../screens/client/manage/weekly_summary_screen.dart';
import '../screens/client/medfriends/caretaker_management_screen.dart';
import '../screens/client/medfriends/edit_caretaker_screen.dart';
import '../screens/client/medfriends/invite_medfriend_screen.dart';
import '../screens/client/reminders/add_reminder_screen.dart';
import '../screens/client/reminders/reminders_screen.dart';
import '../screens/database/sql_category_entries_screen.dart';
import '../screens/database/sql_connection_status_screen.dart';
import '../models/caretaker.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String userHome = '/home';
  static const String adminHome = '/admin';
  static const String createProfile = '/profile/create';
  static const String addDependent = '/dependents/add';
  static const String inviteMedfriend = '/medfriends/invite';
  static const String caretakerManagement = '/medfriends/caretakers';
  static const String addCaretaker = '/medfriends/caretakers/add';
  static const String editCaretaker = '/medfriends/caretakers/edit';
  static const String databaseStatus = '/database/status';
  static const String manage = '/manage';
  static const String reminders = '/reminders';
  static const String reminderTroubleshooting = '/manage/reminder-troubleshooting';
  static const String addMedication = '/medications/add';
  static const String expiryCalendar = '/medications/expiry-calendar';
  static const String appSettings = '/manage/settings';
  static const String barcodeScanner = '/medications/barcode-scanner';
  static const String generalSettings = '/manage/settings/general';
  static const String professionalReview = '/manage/professional-review';
  static const String helpCenter = '/manage/help';
  static const String helpArticles = '/manage/help/articles';
  static const String contactSupport = '/manage/help/contact';
  static const String shareHelpCenter = '/manage/help/share';
  static const String shareMedisafe = '/manage/share-medisafe';
  static const String shareApp = '/manage/share-app';
  static const String rateMedisafe = '/manage/rate';
  static const String sendFeedback = '/manage/feedback';
  static const String about = '/manage/about';
  static const String deleteAccountConfirm = '/manage/delete-account/confirm';
  static const String deleteAccountReason = '/manage/delete-account/reason';
  static const String morningReminder = '/manage/settings/morning';
  static const String eveningReminder = '/manage/settings/evening';
  static const String weeklySummary = '/manage/settings/weekly';
  static const String weekendMode = '/manage/settings/weekend';
  static const String addOrEditReminder = '/reminders/add-or-edit';
  static const String sqlCategoryEntries = '/database/category-entries';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        final args = settings.arguments;
        final prefilledEmail = args is String ? args : null;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(prefilledEmail: prefilledEmail),
        );
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case userHome:
        return MaterialPageRoute(
          builder: (_) => const Stack(
            children: [
              HomeScreen(),
              AlarmDisplayScreen(),
            ],
          ),
        );
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminWebpageScreen());
      case createProfile:
        return MaterialPageRoute(builder: (_) => const CreateProfileScreen());
      case addDependent:
        return MaterialPageRoute(builder: (_) => const AddDependentScreen());
      case inviteMedfriend:
        return MaterialPageRoute(builder: (_) => const InviteMedfriendScreen());
      case caretakerManagement:
        return MaterialPageRoute(
          builder: (_) => const CaretakerManagementScreen(),
        );
      case addCaretaker:
        return MaterialPageRoute(builder: (_) => const AddCaretakerScreen());
      case editCaretaker:
        final args = settings.arguments;
        if (args is Caretaker) {
          return MaterialPageRoute(
            builder: (_) => EditCaretakerScreen(caretaker: args),
          );
        }
        return _unknownRoute();
      case databaseStatus:
        return MaterialPageRoute(
          builder: (_) => const SqlConnectionStatusScreen(),
        );
      case manage:
        return MaterialPageRoute(builder: (_) => const ManageScreen());
      case reminders:
        return MaterialPageRoute(builder: (_) => const RemindersScreen());
      case reminderTroubleshooting:
        return MaterialPageRoute(
          builder: (_) => const ReminderTroubleshootingScreen(),
        );
      case addMedication:
        final args = settings.arguments;
        return MaterialPageRoute(
          builder: (_) => AddMedicationScreen(medicine: args is Medicine ? args : null),
        );
      case expiryCalendar:
        final args = settings.arguments;
        if (args is List<Medicine>) {
          return MaterialPageRoute(
            builder: (_) => ExpiryCalendarScreen(medicines: args),
          );
        }
        return _unknownRoute();
      case appSettings:
        return MaterialPageRoute(builder: (_) => const AppSettingsScreen());
      case barcodeScanner:
        return MaterialPageRoute(builder: (_) => const BarcodeScannerScreen());
      case generalSettings:
        return MaterialPageRoute(
          builder: (_) => const GeneralSettingsScreen(),
        );
      case professionalReview:
        return MaterialPageRoute(
          builder: (_) => const ProfessionalReviewRequestScreen(),
        );
      case helpCenter:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case helpArticles:
        return MaterialPageRoute(builder: (_) => const HelpArticlesScreen());
      case contactSupport:
        return MaterialPageRoute(builder: (_) => const ContactSupportScreen());
      case shareHelpCenter:
        return MaterialPageRoute(builder: (_) => const ShareHelpCenterScreen());
      case shareMedisafe:
        return MaterialPageRoute(builder: (_) => const ShareMedisafeScreen());
      case shareApp:
        return MaterialPageRoute(builder: (_) => const ShareAppScreen());
      case rateMedisafe:
        return MaterialPageRoute(builder: (_) => const RateMedisafeScreen());
      case sendFeedback:
        return MaterialPageRoute(builder: (_) => const SendFeedbackScreen());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case deleteAccountConfirm:
        return MaterialPageRoute(
          builder: (_) => const DeleteAccountConfirmScreen(),
        );
      case deleteAccountReason:
        return MaterialPageRoute(
          builder: (_) => const DeleteAccountReasonScreen(),
        );
      case morningReminder:
        return MaterialPageRoute(builder: (_) => const MorningReminderScreen());
      case eveningReminder:
        return MaterialPageRoute(builder: (_) => const EveningReminderScreen());
      case weeklySummary:
        return MaterialPageRoute(builder: (_) => const WeeklySummaryScreen());
      case weekendMode:
        return MaterialPageRoute(builder: (_) => const WeekendModeScreen());
      case addOrEditReminder:
        final args = settings.arguments;
        if (args is ReminderRouteArgs) {
          return MaterialPageRoute(
            builder: (_) => AddReminderScreen(
              medicines: args.medicines,
              reminder: args.reminder,
            ),
          );
        }
        return _unknownRoute();
      case sqlCategoryEntries:
        final args = settings.arguments;
        if (args is SqlCategoryEntriesArgs) {
          return MaterialPageRoute(
            builder: (_) => SqlCategoryEntriesScreen(
              title: args.title,
              icon: args.icon,
              rows: args.rows,
              columns: args.columns,
            ),
          );
        }
        return _unknownRoute();
      default:
        return _unknownRoute();
    }
  }

  static Route<dynamic> _unknownRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Route not found'),
        ),
      ),
    );
  }
}

class ReminderRouteArgs {
  const ReminderRouteArgs({required this.medicines, this.reminder});

  final List<Medicine> medicines;
  final Reminder? reminder;
}

class SqlCategoryEntriesArgs {
  const SqlCategoryEntriesArgs({
    required this.title,
    required this.icon,
    required this.rows,
    required this.columns,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> rows;
  final List<String> columns;
}
