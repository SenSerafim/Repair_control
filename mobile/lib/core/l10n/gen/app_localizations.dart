import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Repair Control'**
  String get appTitle;

  /// No description provided for @common_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get common_retry;

  /// No description provided for @common_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get common_save;

  /// No description provided for @common_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get common_close;

  /// No description provided for @common_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get common_loading;

  /// No description provided for @common_submit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get common_submit;

  /// No description provided for @common_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get common_edit;

  /// No description provided for @common_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get common_done;

  /// No description provided for @common_yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get common_no;

  /// No description provided for @common_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get common_search;

  /// No description provided for @common_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get common_yesterday;

  /// No description provided for @auth_welcome_title.
  ///
  /// In ru, this message translates to:
  /// **'Repair Control'**
  String get auth_welcome_title;

  /// No description provided for @auth_welcome_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Контроль ремонта для заказчика, представителя, бригадира и мастера.'**
  String get auth_welcome_subtitle;

  /// No description provided for @auth_login.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get auth_login;

  /// No description provided for @auth_register.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get auth_register;

  /// No description provided for @auth_recover_password.
  ///
  /// In ru, this message translates to:
  /// **'Восстановить пароль'**
  String get auth_recover_password;

  /// No description provided for @auth_phone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get auth_phone;

  /// No description provided for @auth_password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get auth_password;

  /// No description provided for @auth_password_repeat.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get auth_password_repeat;

  /// No description provided for @auth_first_name.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get auth_first_name;

  /// No description provided for @auth_last_name.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get auth_last_name;

  /// No description provided for @auth_role.
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get auth_role;

  /// No description provided for @auth_consent_title.
  ///
  /// In ru, this message translates to:
  /// **'Согласие на обработку'**
  String get auth_consent_title;

  /// No description provided for @auth_consent_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю условия пользовательского соглашения и политики конфиденциальности'**
  String get auth_consent_subtitle;

  /// No description provided for @auth_logout_title.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get auth_logout_title;

  /// No description provided for @auth_logout_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Потребуется ввести телефон и пароль, чтобы войти снова.'**
  String get auth_logout_subtitle;

  /// No description provided for @auth_logout_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Да, выйти'**
  String get auth_logout_confirm;

  /// No description provided for @nav_projects.
  ///
  /// In ru, this message translates to:
  /// **'Проекты'**
  String get nav_projects;

  /// No description provided for @nav_contractors.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get nav_contractors;

  /// No description provided for @nav_chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get nav_chats;

  /// No description provided for @nav_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get nav_profile;

  /// No description provided for @profile_my_tools.
  ///
  /// In ru, this message translates to:
  /// **'Мои инструменты'**
  String get profile_my_tools;

  /// No description provided for @profile_notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get profile_notifications;

  /// No description provided for @profile_language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get profile_language;

  /// No description provided for @profile_theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get profile_theme;

  /// No description provided for @profile_theme_light.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get profile_theme_light;

  /// No description provided for @profile_theme_dark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get profile_theme_dark;

  /// No description provided for @profile_theme_system.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get profile_theme_system;

  /// No description provided for @profile_theme_picker_title.
  ///
  /// In ru, this message translates to:
  /// **'Тема приложения'**
  String get profile_theme_picker_title;

  /// No description provided for @profile_theme_picker_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите внешний вид интерфейса'**
  String get profile_theme_picker_subtitle;

  /// No description provided for @profile_help.
  ///
  /// In ru, this message translates to:
  /// **'Обучающие материалы'**
  String get profile_help;

  /// No description provided for @profile_feedback.
  ///
  /// In ru, this message translates to:
  /// **'Обратная связь'**
  String get profile_feedback;

  /// No description provided for @profile_logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profile_logout;

  /// No description provided for @profile_edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get profile_edit;

  /// No description provided for @profile_my_roles.
  ///
  /// In ru, this message translates to:
  /// **'Мои роли'**
  String get profile_my_roles;

  /// No description provided for @profile_avatar_change.
  ///
  /// In ru, this message translates to:
  /// **'Сменить фото'**
  String get profile_avatar_change;

  /// No description provided for @language_ru.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get language_ru;

  /// No description provided for @language_en.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @projects_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои объекты'**
  String get projects_title;

  /// No description provided for @projects_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать проект'**
  String get projects_create;

  /// No description provided for @projects_archive.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get projects_archive;

  /// No description provided for @projects_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск проектов'**
  String get projects_search;

  /// No description provided for @projects_address.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get projects_address;

  /// No description provided for @projects_planned_start.
  ///
  /// In ru, this message translates to:
  /// **'Плановый старт'**
  String get projects_planned_start;

  /// No description provided for @projects_planned_end.
  ///
  /// In ru, this message translates to:
  /// **'Плановый конец'**
  String get projects_planned_end;

  /// No description provided for @projects_empty_customer.
  ///
  /// In ru, this message translates to:
  /// **'Создайте первый проект, чтобы начать'**
  String get projects_empty_customer;

  /// No description provided for @projects_empty_contractor.
  ///
  /// In ru, this message translates to:
  /// **'Заказчик ещё не пригласил вас в проект'**
  String get projects_empty_contractor;

  /// No description provided for @projects_empty_rep.
  ///
  /// In ru, this message translates to:
  /// **'Заказчик ещё не пригласил вас в проект'**
  String get projects_empty_rep;

  /// No description provided for @projects_card_menu_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get projects_card_menu_copy;

  /// No description provided for @projects_card_menu_edit.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get projects_card_menu_edit;

  /// No description provided for @projects_card_menu_archive.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать'**
  String get projects_card_menu_archive;

  /// No description provided for @projects_card_menu_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get projects_card_menu_delete;

  /// No description provided for @projects_archived_banner.
  ///
  /// In ru, this message translates to:
  /// **'Этот проект в архиве'**
  String get projects_archived_banner;

  /// No description provided for @stages_title.
  ///
  /// In ru, this message translates to:
  /// **'Этапы'**
  String get stages_title;

  /// No description provided for @stages_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать этап'**
  String get stages_create;

  /// No description provided for @stages_status_pending.
  ///
  /// In ru, this message translates to:
  /// **'Запланирован'**
  String get stages_status_pending;

  /// No description provided for @stages_status_active.
  ///
  /// In ru, this message translates to:
  /// **'В работе'**
  String get stages_status_active;

  /// No description provided for @stages_status_paused.
  ///
  /// In ru, this message translates to:
  /// **'На паузе'**
  String get stages_status_paused;

  /// No description provided for @stages_status_review.
  ///
  /// In ru, this message translates to:
  /// **'На приёмке'**
  String get stages_status_review;

  /// No description provided for @stages_status_done.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get stages_status_done;

  /// No description provided for @stages_status_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонён'**
  String get stages_status_rejected;

  /// No description provided for @stages_status_overdue.
  ///
  /// In ru, this message translates to:
  /// **'Просрочка'**
  String get stages_status_overdue;

  /// No description provided for @stages_status_late_start.
  ///
  /// In ru, this message translates to:
  /// **'Старт пропущен'**
  String get stages_status_late_start;

  /// No description provided for @stages_action_start.
  ///
  /// In ru, this message translates to:
  /// **'Старт'**
  String get stages_action_start;

  /// No description provided for @stages_action_pause.
  ///
  /// In ru, this message translates to:
  /// **'Пауза'**
  String get stages_action_pause;

  /// No description provided for @stages_action_resume.
  ///
  /// In ru, this message translates to:
  /// **'Возобновить'**
  String get stages_action_resume;

  /// No description provided for @stages_action_review.
  ///
  /// In ru, this message translates to:
  /// **'На приёмку'**
  String get stages_action_review;

  /// No description provided for @stages_action_complete.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get stages_action_complete;

  /// No description provided for @stages_pause_reason_materials.
  ///
  /// In ru, this message translates to:
  /// **'Ждём материалы'**
  String get stages_pause_reason_materials;

  /// No description provided for @stages_pause_reason_approval.
  ///
  /// In ru, this message translates to:
  /// **'Ждём согласование'**
  String get stages_pause_reason_approval;

  /// No description provided for @stages_pause_reason_force_majeure.
  ///
  /// In ru, this message translates to:
  /// **'Форс-мажор'**
  String get stages_pause_reason_force_majeure;

  /// No description provided for @stages_pause_reason_other.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get stages_pause_reason_other;

  /// No description provided for @steps_title.
  ///
  /// In ru, this message translates to:
  /// **'Шаги'**
  String get steps_title;

  /// No description provided for @steps_add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить шаг'**
  String get steps_add;

  /// No description provided for @steps_substep_add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подшаг'**
  String get steps_substep_add;

  /// No description provided for @steps_photo_attach.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепить фото'**
  String get steps_photo_attach;

  /// No description provided for @steps_send_for_approval.
  ///
  /// In ru, this message translates to:
  /// **'Отправить на согласование'**
  String get steps_send_for_approval;

  /// No description provided for @steps_extra_work.
  ///
  /// In ru, this message translates to:
  /// **'Доп. работа'**
  String get steps_extra_work;

  /// No description provided for @steps_question_ask.
  ///
  /// In ru, this message translates to:
  /// **'Задать вопрос'**
  String get steps_question_ask;

  /// No description provided for @approvals_title.
  ///
  /// In ru, this message translates to:
  /// **'Согласования'**
  String get approvals_title;

  /// No description provided for @approvals_pending.
  ///
  /// In ru, this message translates to:
  /// **'Активные'**
  String get approvals_pending;

  /// No description provided for @approvals_history.
  ///
  /// In ru, this message translates to:
  /// **'История'**
  String get approvals_history;

  /// No description provided for @approvals_approve.
  ///
  /// In ru, this message translates to:
  /// **'Одобрить'**
  String get approvals_approve;

  /// No description provided for @approvals_reject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get approvals_reject;

  /// No description provided for @approvals_resubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить повторно'**
  String get approvals_resubmit;

  /// No description provided for @approvals_attempt.
  ///
  /// In ru, this message translates to:
  /// **'Попытка'**
  String get approvals_attempt;

  /// No description provided for @approvals_comment_required.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий обязателен (минимум 10 символов)'**
  String get approvals_comment_required;

  /// No description provided for @finance_budget.
  ///
  /// In ru, this message translates to:
  /// **'Бюджет'**
  String get finance_budget;

  /// No description provided for @finance_budget_works.
  ///
  /// In ru, this message translates to:
  /// **'Работы'**
  String get finance_budget_works;

  /// No description provided for @finance_budget_materials.
  ///
  /// In ru, this message translates to:
  /// **'Материалы'**
  String get finance_budget_materials;

  /// No description provided for @finance_budget_total.
  ///
  /// In ru, this message translates to:
  /// **'Всего'**
  String get finance_budget_total;

  /// No description provided for @finance_budget_spent.
  ///
  /// In ru, this message translates to:
  /// **'Потрачено'**
  String get finance_budget_spent;

  /// No description provided for @finance_budget_remaining.
  ///
  /// In ru, this message translates to:
  /// **'Остаток'**
  String get finance_budget_remaining;

  /// No description provided for @finance_payments.
  ///
  /// In ru, this message translates to:
  /// **'Выплаты'**
  String get finance_payments;

  /// No description provided for @finance_advance_new.
  ///
  /// In ru, this message translates to:
  /// **'Новый аванс'**
  String get finance_advance_new;

  /// No description provided for @finance_advance_amount.
  ///
  /// In ru, this message translates to:
  /// **'Сумма аванса'**
  String get finance_advance_amount;

  /// No description provided for @finance_distribute.
  ///
  /// In ru, this message translates to:
  /// **'Распределить'**
  String get finance_distribute;

  /// No description provided for @finance_dispute_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть спор'**
  String get finance_dispute_open;

  /// No description provided for @finance_dispute_resolve.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить спор'**
  String get finance_dispute_resolve;

  /// No description provided for @finance_dispute_reason.
  ///
  /// In ru, this message translates to:
  /// **'Причина (минимум 30 символов)'**
  String get finance_dispute_reason;

  /// No description provided for @finance_dispute_photos.
  ///
  /// In ru, this message translates to:
  /// **'Фото-доказательства (необязательно)'**
  String get finance_dispute_photos;

  /// No description provided for @finance_overspent_warning.
  ///
  /// In ru, this message translates to:
  /// **'Превышение аванса'**
  String get finance_overspent_warning;

  /// No description provided for @materials_title.
  ///
  /// In ru, this message translates to:
  /// **'Материалы'**
  String get materials_title;

  /// No description provided for @materials_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать заявку'**
  String get materials_create;

  /// No description provided for @materials_items.
  ///
  /// In ru, this message translates to:
  /// **'Позиции'**
  String get materials_items;

  /// No description provided for @materials_mark_bought.
  ///
  /// In ru, this message translates to:
  /// **'Отметить купленным'**
  String get materials_mark_bought;

  /// No description provided for @materials_finalize.
  ///
  /// In ru, this message translates to:
  /// **'Финализировать'**
  String get materials_finalize;

  /// No description provided for @selfpurchase_title.
  ///
  /// In ru, this message translates to:
  /// **'Самозакуп'**
  String get selfpurchase_title;

  /// No description provided for @selfpurchase_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать самозакуп'**
  String get selfpurchase_create;

  /// No description provided for @selfpurchase_pending_master.
  ///
  /// In ru, this message translates to:
  /// **'Ваш самозакуп ждёт подтверждения от бригадира'**
  String get selfpurchase_pending_master;

  /// No description provided for @selfpurchase_pending_foreman.
  ///
  /// In ru, this message translates to:
  /// **'Ваш самозакуп ждёт подтверждения заказчика'**
  String get selfpurchase_pending_foreman;

  /// No description provided for @selfpurchase_decision_required.
  ///
  /// In ru, this message translates to:
  /// **'Требуется ваше решение'**
  String get selfpurchase_decision_required;

  /// No description provided for @selfpurchase_approved.
  ///
  /// In ru, this message translates to:
  /// **'Самозакуп подтверждён, сумма учтена в бюджете'**
  String get selfpurchase_approved;

  /// No description provided for @selfpurchase_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Самозакуп отклонён'**
  String get selfpurchase_rejected;

  /// No description provided for @chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chat_title;

  /// No description provided for @chat_new.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get chat_new;

  /// No description provided for @chat_forward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get chat_forward;

  /// No description provided for @chat_edit_window_expired.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование недоступно — окно истекло'**
  String get chat_edit_window_expired;

  /// No description provided for @chat_actions.
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get chat_actions;

  /// No description provided for @chat_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get chat_send;

  /// No description provided for @chat_type_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_type_message;

  /// No description provided for @documents_title.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get documents_title;

  /// No description provided for @documents_upload.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get documents_upload;

  /// No description provided for @documents_category_contracts.
  ///
  /// In ru, this message translates to:
  /// **'Договоры'**
  String get documents_category_contracts;

  /// No description provided for @documents_category_acts.
  ///
  /// In ru, this message translates to:
  /// **'Акты'**
  String get documents_category_acts;

  /// No description provided for @documents_category_estimates.
  ///
  /// In ru, this message translates to:
  /// **'Сметы'**
  String get documents_category_estimates;

  /// No description provided for @documents_category_warranties.
  ///
  /// In ru, this message translates to:
  /// **'Гарантии'**
  String get documents_category_warranties;

  /// No description provided for @documents_category_photos.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get documents_category_photos;

  /// No description provided for @documents_category_drawings.
  ///
  /// In ru, this message translates to:
  /// **'Чертежи'**
  String get documents_category_drawings;

  /// No description provided for @documents_category_other.
  ///
  /// In ru, this message translates to:
  /// **'Прочее'**
  String get documents_category_other;

  /// No description provided for @feed_title.
  ///
  /// In ru, this message translates to:
  /// **'Лента'**
  String get feed_title;

  /// No description provided for @feed_export_pdf.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт в PDF'**
  String get feed_export_pdf;

  /// No description provided for @feed_export_zip.
  ///
  /// In ru, this message translates to:
  /// **'Архив проекта (ZIP)'**
  String get feed_export_zip;

  /// No description provided for @notifications_title.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications_title;

  /// No description provided for @notifications_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет новых уведомлений'**
  String get notifications_empty;

  /// No description provided for @notifications_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки уведомлений'**
  String get notifications_settings;

  /// No description provided for @team_title.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get team_title;

  /// No description provided for @team_role_customer.
  ///
  /// In ru, this message translates to:
  /// **'Заказчик'**
  String get team_role_customer;

  /// No description provided for @team_role_representative.
  ///
  /// In ru, this message translates to:
  /// **'Представитель'**
  String get team_role_representative;

  /// No description provided for @team_role_foreman.
  ///
  /// In ru, this message translates to:
  /// **'Бригадир'**
  String get team_role_foreman;

  /// No description provided for @team_role_master.
  ///
  /// In ru, this message translates to:
  /// **'Мастер'**
  String get team_role_master;

  /// No description provided for @team_add_member.
  ///
  /// In ru, this message translates to:
  /// **'Добавить участника'**
  String get team_add_member;

  /// No description provided for @team_remove_member.
  ///
  /// In ru, this message translates to:
  /// **'Удалить участника'**
  String get team_remove_member;

  /// No description provided for @tools_title.
  ///
  /// In ru, this message translates to:
  /// **'Инструменты'**
  String get tools_title;

  /// No description provided for @tools_issue.
  ///
  /// In ru, this message translates to:
  /// **'Выдать'**
  String get tools_issue;

  /// No description provided for @tools_return.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть'**
  String get tools_return;

  /// No description provided for @methodology_title.
  ///
  /// In ru, this message translates to:
  /// **'Методичка'**
  String get methodology_title;

  /// No description provided for @methodology_open_article.
  ///
  /// In ru, this message translates to:
  /// **'Открыть методичку'**
  String get methodology_open_article;

  /// No description provided for @error_network_title.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения'**
  String get error_network_title;

  /// No description provided for @error_network_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте интернет и попробуйте снова.'**
  String get error_network_subtitle;

  /// No description provided for @error_server_title.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не отвечает'**
  String get error_server_title;

  /// No description provided for @error_server_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Мы уже знаем о проблеме. Попробуйте позже.'**
  String get error_server_subtitle;

  /// No description provided for @error_unknown_title.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get error_unknown_title;

  /// No description provided for @error_unknown_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте ещё раз или свяжитесь с поддержкой.'**
  String get error_unknown_subtitle;

  /// No description provided for @error_state_conflict.
  ///
  /// In ru, this message translates to:
  /// **'Сервер изменил состояние, перезагрузите экран'**
  String get error_state_conflict;

  /// No description provided for @error_validation_title.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте поля'**
  String get error_validation_title;

  /// No description provided for @offline_banner_offline.
  ///
  /// In ru, this message translates to:
  /// **'Нет сети. Изменения сохранятся локально.'**
  String get offline_banner_offline;

  /// No description provided for @offline_banner_syncing.
  ///
  /// In ru, this message translates to:
  /// **'Синхронизируем изменения…'**
  String get offline_banner_syncing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
