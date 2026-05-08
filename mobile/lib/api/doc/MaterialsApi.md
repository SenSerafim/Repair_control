# repair_control_api.api.MaterialsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**materialsControllerConfirmDelivery**](MaterialsApi.md#materialscontrollerconfirmdelivery) | **POST** /api/materials/{id}/confirm-delivery | 
[**materialsControllerCreate**](MaterialsApi.md#materialscontrollercreate) | **POST** /api/projects/{projectId}/materials | 
[**materialsControllerDispute**](MaterialsApi.md#materialscontrollerdispute) | **POST** /api/materials/{id}/dispute | 
[**materialsControllerFinalize**](MaterialsApi.md#materialscontrollerfinalize) | **POST** /api/materials/{id}/finalize | 
[**materialsControllerGet**](MaterialsApi.md#materialscontrollerget) | **GET** /api/materials/{id} | 
[**materialsControllerList**](MaterialsApi.md#materialscontrollerlist) | **GET** /api/projects/{projectId}/materials | 
[**materialsControllerMarkBought**](MaterialsApi.md#materialscontrollermarkbought) | **POST** /api/materials/{id}/items/{itemId}/bought | 
[**materialsControllerResolve**](MaterialsApi.md#materialscontrollerresolve) | **POST** /api/materials/{id}/resolve | 
[**materialsControllerSend**](MaterialsApi.md#materialscontrollersend) | **POST** /api/materials/{id}/send | 


# **materialsControllerConfirmDelivery**
> materialsControllerConfirmDelivery(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 

try {
    api.materialsControllerConfirmDelivery(id);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerConfirmDelivery: $e\n');
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

# **materialsControllerCreate**
> materialsControllerCreate(projectId, createMaterialRequestDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String projectId = projectId_example; // String | 
final CreateMaterialRequestDto createMaterialRequestDto = ; // CreateMaterialRequestDto | 

try {
    api.materialsControllerCreate(projectId, createMaterialRequestDto);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createMaterialRequestDto** | [**CreateMaterialRequestDto**](CreateMaterialRequestDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **materialsControllerDispute**
> materialsControllerDispute(id, disputeMaterialDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 
final DisputeMaterialDto disputeMaterialDto = ; // DisputeMaterialDto | 

try {
    api.materialsControllerDispute(id, disputeMaterialDto);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerDispute: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **disputeMaterialDto** | [**DisputeMaterialDto**](DisputeMaterialDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **materialsControllerFinalize**
> materialsControllerFinalize(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 

try {
    api.materialsControllerFinalize(id);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerFinalize: $e\n');
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

# **materialsControllerGet**
> materialsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 

try {
    api.materialsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerGet: $e\n');
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

# **materialsControllerList**
> materialsControllerList(projectId, status, stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String projectId = projectId_example; // String | 
final String status = status_example; // String | 
final String stageId = stageId_example; // String | 

try {
    api.materialsControllerList(projectId, status, stageId);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **status** | **String**|  | 
 **stageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **materialsControllerMarkBought**
> materialsControllerMarkBought(id, itemId, markBoughtDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 
final String itemId = itemId_example; // String | 
final MarkBoughtDto markBoughtDto = ; // MarkBoughtDto | 

try {
    api.materialsControllerMarkBought(id, itemId, markBoughtDto);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerMarkBought: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **itemId** | **String**|  | 
 **markBoughtDto** | [**MarkBoughtDto**](MarkBoughtDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **materialsControllerResolve**
> materialsControllerResolve(id, resolveMaterialDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 
final ResolveMaterialDto resolveMaterialDto = ; // ResolveMaterialDto | 

try {
    api.materialsControllerResolve(id, resolveMaterialDto);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerResolve: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **resolveMaterialDto** | [**ResolveMaterialDto**](ResolveMaterialDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **materialsControllerSend**
> materialsControllerSend(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMaterialsApi();
final String id = id_example; // String | 

try {
    api.materialsControllerSend(id);
} catch on DioException (e) {
    print('Exception when calling MaterialsApi->materialsControllerSend: $e\n');
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

