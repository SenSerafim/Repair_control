# repair_control_api.api.AdminAuditApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminAuditControllerList**](AdminAuditApi.md#adminauditcontrollerlist) | **GET** /api/admin/audit | 
[**adminAuditControllerStats**](AdminAuditApi.md#adminauditcontrollerstats) | **GET** /api/admin/stats | 


# **adminAuditControllerList**
> adminAuditControllerList(actorId, action, from, to, limit)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminAuditApi();
final String actorId = actorId_example; // String | 
final String action = action_example; // String | 
final String from = from_example; // String | 
final String to = to_example; // String | 
final String limit = limit_example; // String | 

try {
    api.adminAuditControllerList(actorId, action, from, to, limit);
} catch on DioException (e) {
    print('Exception when calling AdminAuditApi->adminAuditControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **actorId** | **String**|  | 
 **action** | **String**|  | 
 **from** | **String**|  | 
 **to** | **String**|  | 
 **limit** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminAuditControllerStats**
> adminAuditControllerStats()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminAuditApi();

try {
    api.adminAuditControllerStats();
} catch on DioException (e) {
    print('Exception when calling AdminAuditApi->adminAuditControllerStats: $e\n');
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

