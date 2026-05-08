# repair_control_api.api.StagesApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**stagesControllerCreate**](StagesApi.md#stagescontrollercreate) | **POST** /api/projects/{projectId}/stages | 
[**stagesControllerGet**](StagesApi.md#stagescontrollerget) | **GET** /api/projects/{projectId}/stages/{stageId} | 
[**stagesControllerList**](StagesApi.md#stagescontrollerlist) | **GET** /api/projects/{projectId}/stages | 
[**stagesControllerPause**](StagesApi.md#stagescontrollerpause) | **POST** /api/projects/{projectId}/stages/{stageId}/pause | 
[**stagesControllerReorder**](StagesApi.md#stagescontrollerreorder) | **PATCH** /api/projects/{projectId}/stages/reorder | 
[**stagesControllerResume**](StagesApi.md#stagescontrollerresume) | **POST** /api/projects/{projectId}/stages/{stageId}/resume | 
[**stagesControllerSendToReview**](StagesApi.md#stagescontrollersendtoreview) | **POST** /api/projects/{projectId}/stages/{stageId}/send-to-review | 
[**stagesControllerStart**](StagesApi.md#stagescontrollerstart) | **POST** /api/projects/{projectId}/stages/{stageId}/start | 
[**stagesControllerUpdate**](StagesApi.md#stagescontrollerupdate) | **PATCH** /api/projects/{projectId}/stages/{stageId} | 


# **stagesControllerCreate**
> stagesControllerCreate(projectId, createStageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String projectId = projectId_example; // String | 
final CreateStageDto createStageDto = ; // CreateStageDto | 

try {
    api.stagesControllerCreate(projectId, createStageDto);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createStageDto** | [**CreateStageDto**](CreateStageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerGet**
> stagesControllerGet(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 

try {
    api.stagesControllerGet(stageId);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerList**
> stagesControllerList(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String projectId = projectId_example; // String | 

try {
    api.stagesControllerList(projectId);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerList: $e\n');
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

# **stagesControllerPause**
> stagesControllerPause(stageId, pauseStageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 
final PauseStageDto pauseStageDto = ; // PauseStageDto | 

try {
    api.stagesControllerPause(stageId, pauseStageDto);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerPause: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 
 **pauseStageDto** | [**PauseStageDto**](PauseStageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerReorder**
> stagesControllerReorder(projectId, reorderStagesDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String projectId = projectId_example; // String | 
final ReorderStagesDto reorderStagesDto = ; // ReorderStagesDto | 

try {
    api.stagesControllerReorder(projectId, reorderStagesDto);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerReorder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **reorderStagesDto** | [**ReorderStagesDto**](ReorderStagesDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerResume**
> stagesControllerResume(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 

try {
    api.stagesControllerResume(stageId);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerResume: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerSendToReview**
> stagesControllerSendToReview(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 

try {
    api.stagesControllerSendToReview(stageId);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerSendToReview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerStart**
> stagesControllerStart(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 

try {
    api.stagesControllerStart(stageId);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerStart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stagesControllerUpdate**
> stagesControllerUpdate(stageId, updateStageDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStagesApi();
final String stageId = stageId_example; // String | 
final UpdateStageDto updateStageDto = ; // UpdateStageDto | 

try {
    api.stagesControllerUpdate(stageId, updateStageDto);
} catch on DioException (e) {
    print('Exception when calling StagesApi->stagesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 
 **updateStageDto** | [**UpdateStageDto**](UpdateStageDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

