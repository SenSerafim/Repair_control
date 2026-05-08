# repair_control_api.api.DocumentsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**documentsControllerConfirm**](DocumentsApi.md#documentscontrollerconfirm) | **POST** /api/documents/{id}/confirm | 
[**documentsControllerDelete**](DocumentsApi.md#documentscontrollerdelete) | **DELETE** /api/documents/{id} | 
[**documentsControllerDownload**](DocumentsApi.md#documentscontrollerdownload) | **GET** /api/documents/{id}/download | 
[**documentsControllerGet**](DocumentsApi.md#documentscontrollerget) | **GET** /api/documents/{id} | 
[**documentsControllerList**](DocumentsApi.md#documentscontrollerlist) | **GET** /api/projects/{projectId}/documents | 
[**documentsControllerPatch**](DocumentsApi.md#documentscontrollerpatch) | **PATCH** /api/documents/{id} | 
[**documentsControllerPresign**](DocumentsApi.md#documentscontrollerpresign) | **POST** /api/projects/{projectId}/documents/presign-upload | 
[**documentsControllerThumbnail**](DocumentsApi.md#documentscontrollerthumbnail) | **GET** /api/documents/{id}/thumbnail | 


# **documentsControllerConfirm**
> documentsControllerConfirm(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 

try {
    api.documentsControllerConfirm(id);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerConfirm: $e\n');
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

# **documentsControllerDelete**
> documentsControllerDelete(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 

try {
    api.documentsControllerDelete(id);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerDelete: $e\n');
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

# **documentsControllerDownload**
> documentsControllerDownload(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 

try {
    api.documentsControllerDownload(id);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerDownload: $e\n');
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

# **documentsControllerGet**
> documentsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 

try {
    api.documentsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerGet: $e\n');
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

# **documentsControllerList**
> documentsControllerList(projectId, stageId, stepId, category, q)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String projectId = projectId_example; // String | 
final String stageId = stageId_example; // String | 
final String stepId = stepId_example; // String | 
final String category = category_example; // String | 
final String q = q_example; // String | 

try {
    api.documentsControllerList(projectId, stageId, stepId, category, q);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **stageId** | **String**|  | [optional] 
 **stepId** | **String**|  | [optional] 
 **category** | **String**|  | [optional] 
 **q** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **documentsControllerPatch**
> documentsControllerPatch(id, patchDocumentDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 
final PatchDocumentDto patchDocumentDto = ; // PatchDocumentDto | 

try {
    api.documentsControllerPatch(id, patchDocumentDto);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **patchDocumentDto** | [**PatchDocumentDto**](PatchDocumentDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **documentsControllerPresign**
> documentsControllerPresign(projectId, presignUploadDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String projectId = projectId_example; // String | 
final PresignUploadDto presignUploadDto = ; // PresignUploadDto | 

try {
    api.documentsControllerPresign(projectId, presignUploadDto);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerPresign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **presignUploadDto** | [**PresignUploadDto**](PresignUploadDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **documentsControllerThumbnail**
> documentsControllerThumbnail(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getDocumentsApi();
final String id = id_example; // String | 

try {
    api.documentsControllerThumbnail(id);
} catch on DioException (e) {
    print('Exception when calling DocumentsApi->documentsControllerThumbnail: $e\n');
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

