# repair_control_api.api.FeedExportsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**exportsControllerCreate**](FeedExportsApi.md#exportscontrollercreate) | **POST** /api/projects/{projectId}/exports | 
[**exportsControllerGet**](FeedExportsApi.md#exportscontrollerget) | **GET** /api/exports/{id} | 
[**exportsControllerList**](FeedExportsApi.md#exportscontrollerlist) | **GET** /api/projects/{projectId}/exports | 
[**exportsControllerListFeed**](FeedExportsApi.md#exportscontrollerlistfeed) | **GET** /api/projects/{projectId}/feed | 


# **exportsControllerCreate**
> exportsControllerCreate(projectId, idempotencyKey, createExportDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedExportsApi();
final String projectId = projectId_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final CreateExportDto createExportDto = ; // CreateExportDto | 

try {
    api.exportsControllerCreate(projectId, idempotencyKey, createExportDto);
} catch on DioException (e) {
    print('Exception when calling FeedExportsApi->exportsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **createExportDto** | [**CreateExportDto**](CreateExportDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exportsControllerGet**
> exportsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedExportsApi();
final String id = id_example; // String | 

try {
    api.exportsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling FeedExportsApi->exportsControllerGet: $e\n');
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

# **exportsControllerList**
> exportsControllerList(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedExportsApi();
final String projectId = projectId_example; // String | 

try {
    api.exportsControllerList(projectId);
} catch on DioException (e) {
    print('Exception when calling FeedExportsApi->exportsControllerList: $e\n');
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

# **exportsControllerListFeed**
> exportsControllerListFeed(projectId, cursor, limit, kind, stageId, dateFrom, dateTo, actorId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedExportsApi();
final String projectId = projectId_example; // String | 
final String cursor = cursor_example; // String | 
final num limit = 8.14; // num | 
final List<String> kind = ; // List<String> | 
final String stageId = stageId_example; // String | 
final String dateFrom = dateFrom_example; // String | 
final String dateTo = dateTo_example; // String | 
final String actorId = actorId_example; // String | 

try {
    api.exportsControllerListFeed(projectId, cursor, limit, kind, stageId, dateFrom, dateTo, actorId);
} catch on DioException (e) {
    print('Exception when calling FeedExportsApi->exportsControllerListFeed: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **num**|  | [optional] 
 **kind** | [**List&lt;String&gt;**](String.md)|  | [optional] 
 **stageId** | **String**|  | [optional] 
 **dateFrom** | **String**|  | [optional] 
 **dateTo** | **String**|  | [optional] 
 **actorId** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

