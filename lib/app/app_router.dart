import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/account_created_view.dart';
import '../features/authentication/presentation/biometric_setup_view.dart';
import '../features/authentication/presentation/biometric_unavailable_view.dart';
import '../features/authentication/presentation/check_email_view.dart';
import '../features/authentication/presentation/forgot_password_view.dart';
import '../features/authentication/presentation/login_view.dart';
import '../features/authentication/presentation/onboarding_view.dart';
import '../features/authentication/presentation/password_reset_success_view.dart';
import '../features/authentication/presentation/register_view.dart';
import '../features/authentication/presentation/reset_password_view.dart';
import '../features/authentication/presentation/splash_view.dart';
import '../features/authentication/presentation/welcome_view.dart';
import '../features/cards/presentation/card_create_wizard_view.dart';
import '../features/cards/presentation/card_detail_view.dart';
import '../features/cards/presentation/card_edit_view.dart';
import '../features/documents/presentation/add_document_source_view.dart';
import '../features/documents/presentation/create_folder_view.dart';
import '../features/documents/presentation/document_detail_view.dart';
import '../features/documents/presentation/document_private_view.dart';
import '../features/home/presentation/global_search_view.dart';
import '../features/home/presentation/main_shell_screen.dart';
import '../features/profile_settings/presentation/cloud_sync_view.dart';
import '../features/profile_settings/presentation/export_data_view.dart';
import '../features/profile_settings/presentation/privacy_info_view.dart';
import '../features/profile_settings/presentation/theme_settings_view.dart';
import '../features/reminders/presentation/reminder_form_view.dart';
import '../features/reminders/presentation/reminder_list_view.dart';
import '../features/scan/presentation/camera_scan_flow_view.dart';
import '../features/vault/presentation/emergency_wipe_view.dart';
import '../features/vault/presentation/pin_screen.dart';
import '../features/vault/presentation/security_settings_view.dart';
import '../features/cards/domain/card_model.dart';
import '../features/documents/domain/document_model.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashView()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingView(),
    ),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeView()),
    GoRoute(path: '/login', builder: (context, state) => const LoginView()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/register/success',
      builder: (context, state) => const AccountCreatedView(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: '/forgot-password/sent',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return CheckEmailView(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordView(),
    ),
    GoRoute(
      path: '/reset-password/success',
      builder: (context, state) => const PasswordResetSuccessView(),
    ),
    GoRoute(
      path: '/biometric-setup',
      builder: (context, state) => const BiometricSetupView(),
    ),
    GoRoute(
      path: '/biometric-unavailable',
      builder: (context, state) => const BiometricUnavailableView(),
    ),
    GoRoute(
      path: '/pin-setup',
      builder: (context, state) => const PinScreen(mode: PinScreenMode.create),
    ),
    GoRoute(
      path: '/pin-verify',
      builder: (context, state) => const PinScreen(mode: PinScreenMode.verify),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final tabIndex = int.tryParse(tabStr ?? '0') ?? 0;
        return MainShellScreen(initialIndex: tabIndex);
      },
    ),
    GoRoute(
      path: '/shell',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final tabIndex = int.tryParse(tabStr ?? '0') ?? 0;
        return MainShellScreen(initialIndex: tabIndex);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'];
        final tabIndex = int.tryParse(tabStr ?? '0') ?? 0;
        return MainShellScreen(initialIndex: tabIndex);
      },
    ),
    GoRoute(
      path: '/cards/create',
      builder: (context, state) => const CardCreateWizardView(),
    ),
    GoRoute(
      path: '/cards/add',
      builder: (context, state) => const CardCreateWizardView(),
    ),
    GoRoute(
      path: '/documents/scan',
      builder: (context, state) => const CameraScanFlowView(),
    ),
    GoRoute(
      path: '/cards/detail',
      builder: (context, state) {
        final card = state.extra;
        final id = (card is CardItem)
            ? card.id
            : (state.uri.queryParameters['id'] ?? '');
        return CardDetailView(cardId: id);
      },
    ),
    GoRoute(
      path: '/cards/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CardDetailView(cardId: id);
      },
    ),
    GoRoute(
      path: '/cards/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return CardEditView(cardId: id);
      },
    ),
    GoRoute(
      path: '/folders/create',
      builder: (context, state) => const CreateFolderView(),
    ),
    GoRoute(
      path: '/documents/create',
      builder: (context, state) => const AddDocumentSourceView(),
    ),
    GoRoute(
      path: '/documents/detail',
      builder: (context, state) {
        final doc = state.extra;
        final id = (doc is DocumentItem)
            ? doc.id
            : (state.uri.queryParameters['id'] ?? '');
        return DocumentDetailView(documentId: id);
      },
    ),
    GoRoute(
      path: '/documents/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DocumentDetailView(documentId: id);
      },
    ),
    GoRoute(
      path: '/documents/:id/private-view',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return DocumentPrivateView(documentId: id);
      },
    ),
    GoRoute(
      path: '/vault/security',
      builder: (context, state) => const SecuritySettingsView(),
    ),
    GoRoute(
      path: '/vault/wipe',
      builder: (context, state) => const EmergencyWipeView(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const ReminderListView(),
    ),
    GoRoute(
      path: '/reminders/create',
      builder: (context, state) => const ReminderFormView(),
    ),
    GoRoute(
      path: '/reminders/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return ReminderFormView(reminderId: id);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const GlobalSearchView(),
    ),
    GoRoute(
      path: '/profile/theme',
      builder: (context, state) => const ThemeSettingsView(),
    ),
    GoRoute(
      path: '/profile/export',
      builder: (context, state) => const ExportDataView(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) => const PrivacyInfoView(),
    ),
    GoRoute(
      path: '/profile/sync',
      builder: (context, state) => const CloudSyncView(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const CameraScanFlowView(),
    ),
  ],
);
