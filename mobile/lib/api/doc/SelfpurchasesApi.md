# repair_control_api.api.SelfpurchasesApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**selfPurchasesControllerApprove**](SelfpurchasesApi.md#selfpurchasescontrollerapprove) | **POST** /api/selfpurchases/{id}/approve | 
[**selfPurchasesControllerCreate**](SelfpurchasesApi.md#selfpurchasescontrollercreate) | **POST** /api/projects/{projectId}/selfpurchases | 
[**selfPurchasesControllerGet**](SelfpurchasesApi.md#selfpurchasescontrollerget) | **GET** /api/selfpurchases/{id} | 
[**selfPurchasesControllerList**](SelfpurchasesApi.md#selfpurchasescontrollerlist) | **GET** /api/projects/{projectId}/selfpurchases | 
[**selfPurchasesControllerReject**](SelfpurchasesApi.md#selfpurchasescontrollerreject) | **POST** /api/selfpurchases/{id}/reject | 


# **selfPurchasesControllerApprove**
> selfPurchasesControllerApprove(id, decideSelfPurchaseDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getSelfpurchasesApi();
final String id = id_example; // String | 
final DecideSelfPurchaseDto decideSelfPurchaseDto = ; // DecideSelfPurchaseDto | 

try {
    api.selfPurchasesControllerApprove(id, decideSelfPurchaseDto);
} catch on DioException (e) {
    print('Exception when calling SelfpurchasesApi->selfPurchasesControllerApprove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **decideSelfPurchaseDto** | [**DecideSelfPurchaseDto**](DecideSelfPurchaseDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **selfPurchasesControllerCreate**
> selfPurchasesControllerCreate(projectId, idempotencyKey, createSelfPurchaseDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getSelfpurchasesApi();
final String projectId = projectId_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final CreateSelfPurchaseDto createSelfPurchaseDto = ; // CreateSelfPurchaseDto | 

try {
    api.selfPurchasesControllerCreate(projectId, idempotencyKey, createSelfPurchaseDto);
} catch on DioException (e) {
    print('Exception when calling SelfpurchasesApi->selfPurchasesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **createSelfPurchaseDto** | [**CreateSelfPurchaseDto**](CreateSelfPurchaseDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **selfPurchasesControllerGet**
> selfPurchasesControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getSelfpurchasesApi();
final String id = id_example; // String | 

try {
    api.selfPurchasesControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling SelfpurchasesApi->selfPurchasesControllerGet: $e\n');
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

# **selfPurchasesControllerList**
> selfPurchasesControllerList(projectId, status, byUserId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getSelfpurchasesApi();
final String projectId = projectId_example; // String | 
final String status = status_example; // String | 
final String byUserId = byUserId_example; // String | 

try {
    api.selfPurchasesControllerList(projectId, status, byUserId);
} catch on DioException (e) {
    print('Exception when calling SelfpurchasesApi->selfPurchasesControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **status** | **String**|  | 
 **byUserId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **selfPurchasesControllerReject**
> selfPurchasesControllerReject(id, decideSelfPurchaseDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getSelfpurchasesApi();
final String id = id_example; // String | 
final DecideSelfPurchaseDto decideSelfPurchaseDto = ; // DecideSelfPurchaseDto | 

try {
    api.selfPurchasesControllerReject(id, decideSelfPurchaseDto);
} catch on DioException (e) {
    print('Exception when calling SelfpurchasesApi->selfPurchasesControllerReject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **decideSelfPurchaseDto** | [**DecideSelfPurchaseDto**](DecideSelfPurchaseDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

