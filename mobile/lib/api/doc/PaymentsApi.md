# repair_control_api.api.PaymentsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**paymentsControllerCancel**](PaymentsApi.md#paymentscontrollercancel) | **POST** /api/payments/{id}/cancel | 
[**paymentsControllerConfirm**](PaymentsApi.md#paymentscontrollerconfirm) | **POST** /api/payments/{id}/confirm | 
[**paymentsControllerCreateAdvance**](PaymentsApi.md#paymentscontrollercreateadvance) | **POST** /api/projects/{projectId}/payments | 
[**paymentsControllerDispute**](PaymentsApi.md#paymentscontrollerdispute) | **POST** /api/payments/{id}/dispute | 
[**paymentsControllerDistribute**](PaymentsApi.md#paymentscontrollerdistribute) | **POST** /api/payments/{id}/distribute | 
[**paymentsControllerGet**](PaymentsApi.md#paymentscontrollerget) | **GET** /api/payments/{id} | 
[**paymentsControllerList**](PaymentsApi.md#paymentscontrollerlist) | **GET** /api/projects/{projectId}/payments | 
[**paymentsControllerProjectBudget**](PaymentsApi.md#paymentscontrollerprojectbudget) | **GET** /api/projects/{projectId}/budget | 
[**paymentsControllerResolve**](PaymentsApi.md#paymentscontrollerresolve) | **POST** /api/payments/{id}/resolve | 
[**paymentsControllerStageBudget**](PaymentsApi.md#paymentscontrollerstagebudget) | **GET** /api/stages/{stageId}/budget | 


# **paymentsControllerCancel**
> paymentsControllerCancel(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 

try {
    api.paymentsControllerCancel(id);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerCancel: $e\n');
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

# **paymentsControllerConfirm**
> paymentsControllerConfirm(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 

try {
    api.paymentsControllerConfirm(id);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerConfirm: $e\n');
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

# **paymentsControllerCreateAdvance**
> paymentsControllerCreateAdvance(projectId, idempotencyKey, createAdvanceDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String projectId = projectId_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final CreateAdvanceDto createAdvanceDto = ; // CreateAdvanceDto | 

try {
    api.paymentsControllerCreateAdvance(projectId, idempotencyKey, createAdvanceDto);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerCreateAdvance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **createAdvanceDto** | [**CreateAdvanceDto**](CreateAdvanceDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerDispute**
> paymentsControllerDispute(id, disputePaymentDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 
final DisputePaymentDto disputePaymentDto = ; // DisputePaymentDto | 

try {
    api.paymentsControllerDispute(id, disputePaymentDto);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerDispute: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **disputePaymentDto** | [**DisputePaymentDto**](DisputePaymentDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerDistribute**
> paymentsControllerDistribute(id, idempotencyKey, distributeDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final DistributeDto distributeDto = ; // DistributeDto | 

try {
    api.paymentsControllerDistribute(id, idempotencyKey, distributeDto);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerDistribute: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **distributeDto** | [**DistributeDto**](DistributeDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerGet**
> paymentsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 

try {
    api.paymentsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerGet: $e\n');
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

# **paymentsControllerList**
> paymentsControllerList(projectId, status, kind, userId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String projectId = projectId_example; // String | 
final String status = status_example; // String | 
final String kind = kind_example; // String | 
final String userId = userId_example; // String | 

try {
    api.paymentsControllerList(projectId, status, kind, userId);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **status** | **String**|  | 
 **kind** | **String**|  | 
 **userId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerProjectBudget**
> paymentsControllerProjectBudget(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String projectId = projectId_example; // String | 

try {
    api.paymentsControllerProjectBudget(projectId);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerProjectBudget: $e\n');
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

# **paymentsControllerResolve**
> paymentsControllerResolve(id, resolvePaymentDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String id = id_example; // String | 
final ResolvePaymentDto resolvePaymentDto = ; // ResolvePaymentDto | 

try {
    api.paymentsControllerResolve(id, resolvePaymentDto);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerResolve: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **resolvePaymentDto** | [**ResolvePaymentDto**](ResolvePaymentDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **paymentsControllerStageBudget**
> paymentsControllerStageBudget(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getPaymentsApi();
final String stageId = stageId_example; // String | 

try {
    api.paymentsControllerStageBudget(stageId);
} catch on DioException (e) {
    print('Exception when calling PaymentsApi->paymentsControllerStageBudget: $e\n');
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

