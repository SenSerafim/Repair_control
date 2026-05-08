# repair_control_api.api.ChatsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**chatsControllerAddParticipant**](ChatsApi.md#chatscontrolleraddparticipant) | **POST** /api/chats/{chatId}/participants | 
[**chatsControllerCreateGroup**](ChatsApi.md#chatscontrollercreategroup) | **POST** /api/projects/{projectId}/chats/group | 
[**chatsControllerCreatePersonal**](ChatsApi.md#chatscontrollercreatepersonal) | **POST** /api/projects/{projectId}/chats/personal | 
[**chatsControllerDeleteMessage**](ChatsApi.md#chatscontrollerdeletemessage) | **DELETE** /api/chats/{chatId}/messages/{id} | 
[**chatsControllerEditMessage**](ChatsApi.md#chatscontrollereditmessage) | **PATCH** /api/chats/{chatId}/messages/{id} | 
[**chatsControllerForward**](ChatsApi.md#chatscontrollerforward) | **POST** /api/chats/{chatId}/messages/{id}/forward | 
[**chatsControllerGet**](ChatsApi.md#chatscontrollerget) | **GET** /api/chats/{chatId} | 
[**chatsControllerList**](ChatsApi.md#chatscontrollerlist) | **GET** /api/projects/{projectId}/chats | 
[**chatsControllerListMessages**](ChatsApi.md#chatscontrollerlistmessages) | **GET** /api/chats/{chatId}/messages | 
[**chatsControllerMarkRead**](ChatsApi.md#chatscontrollermarkread) | **POST** /api/chats/{chatId}/read | 
[**chatsControllerPatch**](ChatsApi.md#chatscontrollerpatch) | **PATCH** /api/chats/{chatId} | 
[**chatsControllerPostMessage**](ChatsApi.md#chatscontrollerpostmessage) | **POST** /api/chats/{chatId}/messages | 
[**chatsControllerRemoveParticipant**](ChatsApi.md#chatscontrollerremoveparticipant) | **DELETE** /api/chats/{chatId}/participants/{userId} | 


# **chatsControllerAddParticipant**
> chatsControllerAddParticipant(chatId, addParticipantDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final AddParticipantDto addParticipantDto = ; // AddParticipantDto | 

try {
    api.chatsControllerAddParticipant(chatId, addParticipantDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerAddParticipant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **addParticipantDto** | [**AddParticipantDto**](AddParticipantDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerCreateGroup**
> chatsControllerCreateGroup(projectId, createGroupChatDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String projectId = projectId_example; // String | 
final CreateGroupChatDto createGroupChatDto = ; // CreateGroupChatDto | 

try {
    api.chatsControllerCreateGroup(projectId, createGroupChatDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerCreateGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createGroupChatDto** | [**CreateGroupChatDto**](CreateGroupChatDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerCreatePersonal**
> chatsControllerCreatePersonal(projectId, createPersonalChatDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String projectId = projectId_example; // String | 
final CreatePersonalChatDto createPersonalChatDto = ; // CreatePersonalChatDto | 

try {
    api.chatsControllerCreatePersonal(projectId, createPersonalChatDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerCreatePersonal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createPersonalChatDto** | [**CreatePersonalChatDto**](CreatePersonalChatDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerDeleteMessage**
> chatsControllerDeleteMessage(chatId, id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final String id = id_example; // String | 

try {
    api.chatsControllerDeleteMessage(chatId, id);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerDeleteMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerEditMessage**
> chatsControllerEditMessage(chatId, id, editMessageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final String id = id_example; // String | 
final EditMessageDto editMessageDto = ; // EditMessageDto | 

try {
    api.chatsControllerEditMessage(chatId, id, editMessageDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerEditMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **id** | **String**|  | 
 **editMessageDto** | [**EditMessageDto**](EditMessageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerForward**
> chatsControllerForward(chatId, id, forwardMessageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final String id = id_example; // String | 
final ForwardMessageDto forwardMessageDto = ; // ForwardMessageDto | 

try {
    api.chatsControllerForward(chatId, id, forwardMessageDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerForward: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **id** | **String**|  | 
 **forwardMessageDto** | [**ForwardMessageDto**](ForwardMessageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerGet**
> chatsControllerGet(chatId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 

try {
    api.chatsControllerGet(chatId);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerList**
> chatsControllerList(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String projectId = projectId_example; // String | 

try {
    api.chatsControllerList(projectId);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerListMessages**
> chatsControllerListMessages(chatId, cursor, limit)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final String cursor = cursor_example; // String | 
final num limit = 8.14; // num | 

try {
    api.chatsControllerListMessages(chatId, cursor, limit);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerListMessages: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **num**|  | [optional] [default to 50]

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerMarkRead**
> chatsControllerMarkRead(chatId, markReadDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final MarkReadDto markReadDto = ; // MarkReadDto | 

try {
    api.chatsControllerMarkRead(chatId, markReadDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerMarkRead: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **markReadDto** | [**MarkReadDto**](MarkReadDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerPatch**
> chatsControllerPatch(chatId, patchChatDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final PatchChatDto patchChatDto = ; // PatchChatDto | 

try {
    api.chatsControllerPatch(chatId, patchChatDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **patchChatDto** | [**PatchChatDto**](PatchChatDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerPostMessage**
> chatsControllerPostMessage(chatId, createMessageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final CreateMessageDto createMessageDto = ; // CreateMessageDto | 

try {
    api.chatsControllerPostMessage(chatId, createMessageDto);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerPostMessage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **createMessageDto** | [**CreateMessageDto**](CreateMessageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **chatsControllerRemoveParticipant**
> chatsControllerRemoveParticipant(chatId, userId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getChatsApi();
final String chatId = chatId_example; // String | 
final String userId = userId_example; // String | 

try {
    api.chatsControllerRemoveParticipant(chatId, userId);
} catch on DioException (e) {
    print('Exception when calling ChatsApi->chatsControllerRemoveParticipant: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **chatId** | **String**|  | 
 **userId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

