// Service Worker для FCM Web Push.
// Подхватывается автоматически Firebase SDK в web-билде:
//   https://firebase.google.com/docs/cloud-messaging/js/client
//
// Активируется только если пользователь заходит с web-версии и даёт
// permission на уведомления. На Android/iOS этот файл не используется.

/* eslint-disable no-undef */
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyBkAJgTu5jFG5LZPySBPpx-Z731r1dXUKY',
  authDomain: 'repaircontrol-22bd3.firebaseapp.com',
  projectId: 'repaircontrol-22bd3',
  storageBucket: 'repaircontrol-22bd3.firebasestorage.app',
  messagingSenderId: '912221133495',
  appId: '1:912221133495:web:6cae452e2aed689c3acb32',
  measurementId: 'G-CCMJGS94NM',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'Repair Control';
  const body = (payload.notification && payload.notification.body) || '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = event.notification.data || {};
  // Собираем deep-link из payload (те же поля, что в DeepLinkRouter).
  let url = '/';
  if (data.paymentId) url = '/payments/' + data.paymentId;
  else if (data.chatId) url = '/chats/' + data.chatId;
  else if (data.projectId && data.approvalId) url = '/projects/' + data.projectId + '/approvals/' + data.approvalId;
  else if (data.projectId && data.stageId && data.stepId) url = '/projects/' + data.projectId + '/stages/' + data.stageId + '/steps/' + data.stepId;
  else if (data.projectId && data.stageId) url = '/projects/' + data.projectId + '/stages/' + data.stageId;
  else if (data.projectId) url = '/projects/' + data.projectId;
  event.waitUntil(clients.openWindow(url));
});
