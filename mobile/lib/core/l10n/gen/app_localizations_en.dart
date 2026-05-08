// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Repair Control';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_close => 'Close';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_submit => 'Submit';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_search => 'Search';

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get auth_welcome_title => 'Repair Control';

  @override
  String get auth_welcome_subtitle =>
      'Repair control for customer, representative, foreman and master.';

  @override
  String get auth_login => 'Sign in';

  @override
  String get auth_register => 'Sign up';

  @override
  String get auth_recover_password => 'Recover password';

  @override
  String get auth_phone => 'Phone';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_password_repeat => 'Repeat password';

  @override
  String get auth_first_name => 'First name';

  @override
  String get auth_last_name => 'Last name';

  @override
  String get auth_role => 'Role';

  @override
  String get auth_consent_title => 'Data processing consent';

  @override
  String get auth_consent_subtitle =>
      'I accept the terms of use and the privacy policy';

  @override
  String get auth_logout_title => 'Sign out?';

  @override
  String get auth_logout_subtitle =>
      'You will need to enter your phone and password to sign in again.';

  @override
  String get auth_logout_confirm => 'Yes, sign out';

  @override
  String get nav_projects => 'Projects';

  @override
  String get nav_contractors => 'Team';

  @override
  String get nav_chats => 'Chats';

  @override
  String get nav_profile => 'Profile';

  @override
  String get profile_my_tools => 'My tools';

  @override
  String get profile_notifications => 'Notifications';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_theme => 'Theme';

  @override
  String get profile_theme_light => 'Light';

  @override
  String get profile_theme_dark => 'Dark';

  @override
  String get profile_theme_system => 'System';

  @override
  String get profile_theme_picker_title => 'App theme';

  @override
  String get profile_theme_picker_subtitle =>
      'Choose the appearance of the interface';

  @override
  String get profile_help => 'Learning materials';

  @override
  String get profile_feedback => 'Feedback';

  @override
  String get profile_logout => 'Sign out';

  @override
  String get profile_edit => 'Edit profile';

  @override
  String get profile_my_roles => 'My roles';

  @override
  String get profile_avatar_change => 'Change photo';

  @override
  String get language_ru => 'Russian';

  @override
  String get language_en => 'English';

  @override
  String get projects_title => 'My projects';

  @override
  String get projects_create => 'Create project';

  @override
  String get projects_archive => 'Archive';

  @override
  String get projects_search => 'Search projects';

  @override
  String get projects_address => 'Address';

  @override
  String get projects_planned_start => 'Planned start';

  @override
  String get projects_planned_end => 'Planned end';

  @override
  String get projects_empty_customer =>
      'Create your first project to get started';

  @override
  String get projects_empty_contractor =>
      'The customer hasn\'t invited you to a project yet';

  @override
  String get projects_empty_rep =>
      'The customer hasn\'t invited you to a project yet';

  @override
  String get projects_card_menu_copy => 'Copy';

  @override
  String get projects_card_menu_edit => 'Edit';

  @override
  String get projects_card_menu_archive => 'Archive';

  @override
  String get projects_card_menu_delete => 'Delete';

  @override
  String get projects_archived_banner => 'This project is archived';

  @override
  String get stages_title => 'Stages';

  @override
  String get stages_create => 'Create stage';

  @override
  String get stages_status_pending => 'Planned';

  @override
  String get stages_status_active => 'In progress';

  @override
  String get stages_status_paused => 'Paused';

  @override
  String get stages_status_review => 'In review';

  @override
  String get stages_status_done => 'Completed';

  @override
  String get stages_status_rejected => 'Rejected';

  @override
  String get stages_status_overdue => 'Overdue';

  @override
  String get stages_status_late_start => 'Late start';

  @override
  String get stages_action_start => 'Start';

  @override
  String get stages_action_pause => 'Pause';

  @override
  String get stages_action_resume => 'Resume';

  @override
  String get stages_action_review => 'Send for review';

  @override
  String get stages_action_complete => 'Complete';

  @override
  String get stages_pause_reason_materials => 'Waiting for materials';

  @override
  String get stages_pause_reason_approval => 'Waiting for approval';

  @override
  String get stages_pause_reason_force_majeure => 'Force majeure';

  @override
  String get stages_pause_reason_other => 'Other';

  @override
  String get steps_title => 'Steps';

  @override
  String get steps_add => 'Add step';

  @override
  String get steps_substep_add => 'Add substep';

  @override
  String get steps_photo_attach => 'Attach photo';

  @override
  String get steps_send_for_approval => 'Send for approval';

  @override
  String get steps_extra_work => 'Extra work';

  @override
  String get steps_question_ask => 'Ask a question';

  @override
  String get approvals_title => 'Approvals';

  @override
  String get approvals_pending => 'Pending';

  @override
  String get approvals_history => 'History';

  @override
  String get approvals_approve => 'Approve';

  @override
  String get approvals_reject => 'Reject';

  @override
  String get approvals_resubmit => 'Resubmit';

  @override
  String get approvals_attempt => 'Attempt';

  @override
  String get approvals_comment_required =>
      'Comment is required (min 10 characters)';

  @override
  String get finance_budget => 'Budget';

  @override
  String get finance_budget_works => 'Works';

  @override
  String get finance_budget_materials => 'Materials';

  @override
  String get finance_budget_total => 'Total';

  @override
  String get finance_budget_spent => 'Spent';

  @override
  String get finance_budget_remaining => 'Remaining';

  @override
  String get finance_payments => 'Payments';

  @override
  String get finance_advance_new => 'New advance';

  @override
  String get finance_advance_amount => 'Advance amount';

  @override
  String get finance_distribute => 'Distribute';

  @override
  String get finance_dispute_open => 'Open dispute';

  @override
  String get finance_dispute_resolve => 'Resolve dispute';

  @override
  String get finance_dispute_reason => 'Reason (min 30 characters)';

  @override
  String get finance_dispute_photos => 'Photo evidence (optional)';

  @override
  String get finance_overspent_warning => 'Advance exceeded';

  @override
  String get materials_title => 'Materials';

  @override
  String get materials_create => 'Create request';

  @override
  String get materials_items => 'Items';

  @override
  String get materials_mark_bought => 'Mark as bought';

  @override
  String get materials_finalize => 'Finalize';

  @override
  String get selfpurchase_title => 'Self-purchase';

  @override
  String get selfpurchase_create => 'Create self-purchase';

  @override
  String get selfpurchase_pending_master =>
      'Your self-purchase is waiting for foreman confirmation';

  @override
  String get selfpurchase_pending_foreman =>
      'Your self-purchase is waiting for customer confirmation';

  @override
  String get selfpurchase_decision_required => 'Your decision is required';

  @override
  String get selfpurchase_approved =>
      'Self-purchase approved, amount added to budget';

  @override
  String get selfpurchase_rejected => 'Self-purchase rejected';

  @override
  String get chat_title => 'Chats';

  @override
  String get chat_new => 'New chat';

  @override
  String get chat_forward => 'Forward';

  @override
  String get chat_edit_window_expired => 'Editing unavailable — window expired';

  @override
  String get chat_actions => 'Actions';

  @override
  String get chat_send => 'Send';

  @override
  String get chat_type_message => 'Message';

  @override
  String get documents_title => 'Documents';

  @override
  String get documents_upload => 'Upload';

  @override
  String get documents_category_contracts => 'Contracts';

  @override
  String get documents_category_acts => 'Acts';

  @override
  String get documents_category_estimates => 'Estimates';

  @override
  String get documents_category_warranties => 'Warranties';

  @override
  String get documents_category_photos => 'Photos';

  @override
  String get documents_category_drawings => 'Drawings';

  @override
  String get documents_category_other => 'Other';

  @override
  String get feed_title => 'Activity';

  @override
  String get feed_export_pdf => 'Export to PDF';

  @override
  String get feed_export_zip => 'Project archive (ZIP)';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_empty => 'No new notifications';

  @override
  String get notifications_settings => 'Notification settings';

  @override
  String get team_title => 'Team';

  @override
  String get team_role_customer => 'Customer';

  @override
  String get team_role_representative => 'Representative';

  @override
  String get team_role_foreman => 'Foreman';

  @override
  String get team_role_master => 'Master';

  @override
  String get team_add_member => 'Add member';

  @override
  String get team_remove_member => 'Remove member';

  @override
  String get tools_title => 'Tools';

  @override
  String get tools_issue => 'Issue';

  @override
  String get tools_return => 'Return';

  @override
  String get methodology_title => 'Methodology';

  @override
  String get methodology_open_article => 'Open methodology';

  @override
  String get error_network_title => 'No connection';

  @override
  String get error_network_subtitle => 'Check the internet and try again.';

  @override
  String get error_server_title => 'Server is unreachable';

  @override
  String get error_server_subtitle => 'We are already aware. Please try later.';

  @override
  String get error_unknown_title => 'Something went wrong';

  @override
  String get error_unknown_subtitle => 'Please try again or contact support.';

  @override
  String get error_state_conflict =>
      'Server state changed, please reload the screen';

  @override
  String get error_validation_title => 'Check the fields';

  @override
  String get offline_banner_offline =>
      'No network. Changes will be saved locally.';

  @override
  String get offline_banner_syncing => 'Syncing changes…';
}
