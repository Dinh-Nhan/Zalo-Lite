// ============================================================
// CORE - App Constants
// ============================================================
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Zalo Lite Admin';
  static const String appVersion = '1.0.0';

  // Admin credentials — loaded from .env via flutter_dotenv at runtime
  // Never hardcode here. Add ADMIN_EMAIL and ADMIN_PASSWORD to your .env file.
  static String get adminEmail => dotenv.env['ADMIN_EMAIL'] ?? '';
  static String get adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '';

  // Pagination
  static const int pageSize = 20;

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String feedsCollection = 'feeds';
  static const String friendshipsCollection = 'friendships';
  static const String hiddenPostsCollection = 'hidden_posts';
  static const String reportsCollection = 'reports';
  static const String adminsCollection = 'admins';
  static const String notificationsCollection = 'admin_notifications';
  static const String feedbacksCollection = 'feedbacks';

  // Admin roles
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';

  // Notification statuses
  static const String notificationDraft = 'draft';
  static const String notificationSent = 'sent';
  static const String notificationScheduled = 'scheduled';

  // Feedback statuses
  static const String feedbackOpen = 'open';
  static const String feedbackResolved = 'resolved';

  // Friendship statuses
  static const String friendshipPending = 'pending';
  static const String friendshipAccepted = 'accepted';
  static const String friendshipDeclined = 'declined';
  static const String friendshipBlocked = 'blocked';

  // Feed types
  static const String feedTypePost = 'post';
  static const String feedTypeStory = 'story';

  // Feed privacy
  static const String privacyPublic = 'public';
  static const String privacyFriends = 'friends';
  static const String privacyPrivate = 'private';

  // Report statuses
  static const String reportPending = 'pending';
  static const String reportResolved = 'resolved';
  static const String reportRejected = 'rejected';

  // Report target types
  static const String reportTargetUser = 'user';
  static const String reportTargetPost = 'post';
}
