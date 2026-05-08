# repair_control_api.api.AdminBroadcastsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**broadcastsControllerGet**](AdminBroadcastsApi.md#broadcastscontrollerget) | **GET** /api/admin/broadcasts/{id} | 
[**broadcastsControllerList**](AdminBroadcastsApi.md#broadcastscontrollerlist) | **GET** /api/admin/broadcasts | 
[**broadcastsControllerPreview**](AdminBroadcastsApi.md#broadcastscontrollerpreview) | **POST** /api/admin/broadcasts/preview | 
[**broadcastsControllerSend**](AdminBroadcastsApi.md#broadcastscontrollersend) | **POST** /api/admin/broadcasts | 


# **broadcastsControllerGet**
> broadcastsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminBroadcastsApi();
final String id = id_example; // String | 

try {
    api.broadcastsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling AdminBroadcastsApi->broadcastsControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **broadcastsControllerList**
> broadcastsControllerList(status)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminBroadcastsApi();
final String status = status_example; // String | 

try {
    api.broadcastsControllerList(status);
} catch on DioException (e) {
    print('Exception when calling AdminBroadcastsApi->broadcastsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **broadcastsControllerPreview**
> broadcastsControllerPreview(previewDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminBroadcastsApi();
final PreviewDto previewDto = ; // PreviewDto | 

try {
    api.broadcastsControllerPreview(previewDto);
} catch on DioException (e) {
    print('Exception when calling AdminBroadcastsApi->broadcastsControllerPreview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **previewDto** | [**PreviewDto**](PreviewDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **broadcastsControllerSend**
> broadcastsControllerSend(sendBroadcastDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminBroadcastsApi();
final SendBroadcastDto sendBroadcastDto = ; // SendBroadcastDto | 

try {
    api.broadcastsControllerSend(sendBroadcastDto);
} catch on DioException (e) {
    print('Exception when calling AdminBroadcastsApi->broadcastsControllerSend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sendBroadcastDto** | [**SendBroadcastDto**](SendBroadcastDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

