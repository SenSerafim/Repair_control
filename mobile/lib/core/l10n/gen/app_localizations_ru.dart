// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Repair Control';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_close => 'Закрыть';

  @override
  String get common_loading => 'Загрузка…';

  @override
  String get common_submit => 'Отправить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_edit => 'Редактировать';

  @override
  String get common_back => 'Назад';

  @override
  String get common_next => 'Далее';

  @override
  String get common_done => 'Готово';

  @override
  String get common_yes => 'Да';

  @override
  String get common_no => 'Нет';

  @override
  String get common_search => 'Поиск';

  @override
  String get common_today => 'Сегодня';

  @override
  String get common_yesterday => 'Вчера';

  @override
  String get auth_welcome_title => 'Repair Control';

  @override
  String get auth_welcome_subtitle =>
      'Контроль ремонта для заказчика, представителя, бригадира и мастера.';

  @override
  String get auth_login => 'Войти';

  @override
  String get auth_register => 'Регистрация';

  @override
  String get auth_recover_password => 'Восстановить пароль';

  @override
  String get auth_phone => 'Телефон';

  @override
  String get auth_password => 'Пароль';

  @override
  String get auth_password_repeat => 'Повторите пароль';

  @override
  String get auth_first_name => 'Имя';

  @override
  String get auth_last_name => 'Фамилия';

  @override
  String get auth_role => 'Роль';

  @override
  String get auth_consent_title => 'Согласие на обработку';

  @override
  String get auth_consent_subtitle =>
      'Принимаю условия пользовательского соглашения и политики конфиденциальности';

  @override
  String get auth_logout_title => 'Выйти из аккаунта?';

  @override
  String get auth_logout_subtitle =>
      'Потребуется ввести телефон и пароль, чтобы войти снова.';

  @override
  String get auth_logout_confirm => 'Да, выйти';

  @override
  String get nav_projects => 'Проекты';

  @override
  String get nav_contractors => 'Команда';

  @override
  String get nav_chats => 'Чаты';

  @override
  String get nav_profile => 'Профиль';

  @override
  String get profile_my_tools => 'Мои инструменты';

  @override
  String get profile_notifications => 'Уведомления';

  @override
  String get profile_language => 'Язык';

  @override
  String get profile_theme => 'Тема';

  @override
  String get profile_theme_light => 'Светлая';

  @override
  String get profile_theme_dark => 'Тёмная';

  @override
  String get profile_theme_system => 'Системная';

  @override
  String get profile_theme_picker_title => 'Тема приложения';

  @override
  String get profile_theme_picker_subtitle => 'Выберите внешний вид интерфейса';

  @override
  String get profile_help => 'Обучающие материалы';

  @override
  String get profile_feedback => 'Обратная связь';

  @override
  String get profile_logout => 'Выйти';

  @override
  String get profile_edit => 'Редактировать профиль';

  @override
  String get profile_my_roles => 'Мои роли';

  @override
  String get profile_avatar_change => 'Сменить фото';

  @override
  String get language_ru => 'Русский';

  @override
  String get language_en => 'English';

  @override
  String get projects_title => 'Мои объекты';

  @override
  String get projects_create => 'Создать проект';

  @override
  String get projects_archive => 'Архив';

  @override
  String get projects_search => 'Поиск проектов';

  @override
  String get projects_address => 'Адрес';

  @override
  String get projects_planned_start => 'Плановый старт';

  @override
  String get projects_planned_end => 'Плановый конец';

  @override
  String get projects_empty_customer => 'Создайте первый проект, чтобы начать';

  @override
  String get projects_empty_contractor =>
      'Заказчик ещё не пригласил вас в проект';

  @override
  String get projects_empty_rep => 'Заказчик ещё не пригласил вас в проект';

  @override
  String get projects_card_menu_copy => 'Копировать';

  @override
  String get projects_card_menu_edit => 'Редактировать';

  @override
  String get projects_card_menu_archive => 'Архивировать';

  @override
  String get projects_card_menu_delete => 'Удалить';

  @override
  String get projects_archived_banner => 'Этот проект в архиве';

  @override
  String get stages_title => 'Этапы';

  @override
  String get stages_create => 'Создать этап';

  @override
  String get stages_status_pending => 'Запланирован';

  @override
  String get stages_status_active => 'В работе';

  @override
  String get stages_status_paused => 'На паузе';

  @override
  String get stages_status_review => 'На приёмке';

  @override
  String get stages_status_done => 'Завершён';

  @override
  String get stages_status_rejected => 'Отклонён';

  @override
  String get stages_status_overdue => 'Просрочка';

  @override
  String get stages_status_late_start => 'Старт пропущен';

  @override
  String get stages_action_start => 'Старт';

  @override
  String get stages_action_pause => 'Пауза';

  @override
  String get stages_action_resume => 'Возобновить';

  @override
  String get stages_action_review => 'На приёмку';

  @override
  String get stages_action_complete => 'Завершить';

  @override
  String get stages_pause_reason_materials => 'Ждём материалы';

  @override
  String get stages_pause_reason_approval => 'Ждём согласование';

  @override
  String get stages_pause_reason_force_majeure => 'Форс-мажор';

  @override
  String get stages_pause_reason_other => 'Другое';

  @override
  String get steps_title => 'Шаги';

  @override
  String get steps_add => 'Добавить шаг';

  @override
  String get steps_substep_add => 'Добавить подшаг';

  @override
  String get steps_photo_attach => 'Прикрепить фото';

  @override
  String get steps_send_for_approval => 'Отправить на согласование';

  @override
  String get steps_extra_work => 'Доп. работа';

  @override
  String get steps_question_ask => 'Задать вопрос';

  @override
  String get approvals_title => 'Согласования';

  @override
  String get approvals_pending => 'Активные';

  @override
  String get approvals_history => 'История';

  @override
  String get approvals_approve => 'Одобрить';

  @override
  String get approvals_reject => 'Отклонить';

  @override
  String get approvals_resubmit => 'Отправить повторно';

  @override
  String get approvals_attempt => 'Попытка';

  @override
  String get approvals_comment_required =>
      'Комментарий обязателен (минимум 10 символов)';

  @override
  String get finance_budget => 'Бюджет';

  @override
  String get finance_budget_works => 'Работы';

  @override
  String get finance_budget_materials => 'Материалы';

  @override
  String get finance_budget_total => 'Всего';

  @override
  String get finance_budget_spent => 'Потрачено';

  @override
  String get finance_budget_remaining => 'Остаток';

  @override
  String get finance_payments => 'Выплаты';

  @override
  String get finance_advance_new => 'Новый аванс';

  @override
  String get finance_advance_amount => 'Сумма аванса';

  @override
  String get finance_distribute => 'Распределить';

  @override
  String get finance_dispute_open => 'Открыть спор';

  @override
  String get finance_dispute_resolve => 'Разрешить спор';

  @override
  String get finance_dispute_reason => 'Причина (минимум 30 символов)';

  @override
  String get finance_dispute_photos => 'Фото-доказательства (необязательно)';

  @override
  String get finance_overspent_warning => 'Превышение аванса';

  @override
  String get materials_title => 'Материалы';

  @override
  String get materials_create => 'Создать заявку';

  @override
  String get materials_items => 'Позиции';

  @override
  String get materials_mark_bought => 'Отметить купленным';

  @override
  String get materials_finalize => 'Финализировать';

  @override
  String get selfpurchase_title => 'Самозакуп';

  @override
  String get selfpurchase_create => 'Создать самозакуп';

  @override
  String get selfpurchase_pending_master =>
      'Ваш самозакуп ждёт подтверждения от бригадира';

  @override
  String get selfpurchase_pending_foreman =>
      'Ваш самозакуп ждёт подтверждения заказчика';

  @override
  String get selfpurchase_decision_required => 'Требуется ваше решение';

  @override
  String get selfpurchase_approved =>
      'Самозакуп подтверждён, сумма учтена в бюджете';

  @override
  String get selfpurchase_rejected => 'Самозакуп отклонён';

  @override
  String get chat_title => 'Чаты';

  @override
  String get chat_new => 'Новый чат';

  @override
  String get chat_forward => 'Переслать';

  @override
  String get chat_edit_window_expired =>
      'Редактирование недоступно — окно истекло';

  @override
  String get chat_actions => 'Действия';

  @override
  String get chat_send => 'Отправить';

  @override
  String get chat_type_message => 'Сообщение';

  @override
  String get documents_title => 'Документы';

  @override
  String get documents_upload => 'Загрузить';

  @override
  String get documents_category_contracts => 'Договоры';

  @override
  String get documents_category_acts => 'Акты';

  @override
  String get documents_category_estimates => 'Сметы';

  @override
  String get documents_category_warranties => 'Гарантии';

  @override
  String get documents_category_photos => 'Фото';

  @override
  String get documents_category_drawings => 'Чертежи';

  @override
  String get documents_category_other => 'Прочее';

  @override
  String get feed_title => 'Лента';

  @override
  String get feed_export_pdf => 'Экспорт в PDF';

  @override
  String get feed_export_zip => 'Архив проекта (ZIP)';

  @override
  String get notifications_title => 'Уведомления';

  @override
  String get notifications_empty => 'Нет новых уведомлений';

  @override
  String get notifications_settings => 'Настройки уведомлений';

  @override
  String get team_title => 'Команда';

  @override
  String get team_role_customer => 'Заказчик';

  @override
  String get team_role_representative => 'Представитель';

  @override
  String get team_role_foreman => 'Бригадир';

  @override
  String get team_role_master => 'Мастер';

  @override
  String get team_add_member => 'Добавить участника';

  @override
  String get team_remove_member => 'Удалить участника';

  @override
  String get tools_title => 'Инструменты';

  @override
  String get tools_issue => 'Выдать';

  @override
  String get tools_return => 'Вернуть';

  @override
  String get methodology_title => 'Методичка';

  @override
  String get methodology_open_article => 'Открыть методичку';

  @override
  String get error_network_title => 'Нет соединения';

  @override
  String get error_network_subtitle => 'Проверьте интернет и попробуйте снова.';

  @override
  String get error_server_title => 'Сервер не отвечает';

  @override
  String get error_server_subtitle =>
      'Мы уже знаем о проблеме. Попробуйте позже.';

  @override
  String get error_unknown_title => 'Что-то пошло не так';

  @override
  String get error_unknown_subtitle =>
      'Попробуйте ещё раз или свяжитесь с поддержкой.';

  @override
  String get error_state_conflict =>
      'Сервер изменил состояние, перезагрузите экран';

  @override
  String get error_validation_title => 'Проверьте поля';

  @override
  String get offline_banner_offline =>
      'Нет сети. Изменения сохранятся локально.';

  @override
  String get offline_banner_syncing => 'Синхронизируем изменения…';
}
