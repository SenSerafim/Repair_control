# repair_control_api.api.AdminProjectsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminProjectsControllerDetail**](AdminProjectsApi.md#adminprojectscontrollerdetail) | **GET** /api/admin/projects/{id} | 
[**adminProjectsControllerForceArchive**](AdminProjectsApi.md#adminprojectscontrollerforcearchive) | **POST** /api/admin/projects/{id}/force-archive | 
[**adminProjectsControllerList**](AdminProjectsApi.md#adminprojectscontrollerlist) | **GET** /api/admin/projects | 


# **adminProjectsControllerDetail**
> adminProjectsControllerDetail(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminProjectsApi();
final String id = id_example; // String | 

try {
    api.adminProjectsControllerDetail(id);
} catch on DioException (e) {
    print('Exception when calling AdminProjectsApi->adminProjectsControllerDetail: $e\n');
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

# **adminProjectsControllerForceArchive**
> adminProjectsControllerForceArchive(id, forceArchiveDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminProjectsApi();
final String id = id_example; // String | 
final ForceArchiveDto forceArchiveDto = ; // ForceArchiveDto | 

try {
    api.adminProjectsControllerForceArchive(id, forceArchiveDto);
} catch on DioException (e) {
    print('Exception when calling AdminProjectsApi->adminProjectsControllerForceArchive: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **forceArchiveDto** | [**ForceArchiveDto**](ForceArchiveDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminProjectsControllerList**
> adminProjectsControllerList(q, status, ownerId, limit, offset)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminProjectsApi();
final String q = q_example; // String | 
final String status = status_example; // String | 
final String ownerId = ownerId_example; // String | 
final num limit = 8.14; // num | 
final num offset = 8.14; // num | 

try {
    api.adminProjectsControllerList(q, status, ownerId, limit, offset);
} catch on DioException (e) {
    print('Exception when calling AdminProjectsApi->adminProjectsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **ownerId** | **String**|  | [optional] 
 **limit** | **num**|  | [optional] 
 **offset** | **num**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

