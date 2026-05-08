# repair_control_api.api.NotificationsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notificationsControllerGetSettings**](NotificationsApi.md#notificationscontrollergetsettings) | **GET** /api/me/notification-settings | 
[**notificationsControllerLogs**](NotificationsApi.md#notificationscontrollerlogs) | **GET** /api/admin/notification-logs | 
[**notificationsControllerPatchSetting**](NotificationsApi.md#notificationscontrollerpatchsetting) | **PATCH** /api/me/notification-settings | 


# **notificationsControllerGetSettings**
> notificationsControllerGetSettings()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotificationsApi();

try {
    api.notificationsControllerGetSettings();
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->notificationsControllerGetSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerLogs**
> notificationsControllerLogs(userId, kind, from, to)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotificationsApi();
final String userId = userId_example; // String | 
final String kind = kind_example; // String | 
final String from = from_example; // String | 
final String to = to_example; // String | 

try {
    api.notificationsControllerLogs(userId, kind, from, to);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->notificationsControllerLogs: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **String**|  | 
 **kind** | **String**|  | 
 **from** | **String**|  | 
 **to** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notificationsControllerPatchSetting**
> notificationsControllerPatchSetting(patchSettingDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotificationsApi();
final PatchSettingDto patchSettingDto = ; // PatchSettingDto | 

try {
    api.notificationsControllerPatchSetting(patchSettingDto);
} catch on DioException (e) {
    print('Exception when calling NotificationsApi->notificationsControllerPatchSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **patchSettingDto** | [**PatchSettingDto**](PatchSettingDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

