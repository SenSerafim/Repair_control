# repair_control_api.api.ApprovalsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**approvalsControllerApprove**](ApprovalsApi.md#approvalscontrollerapprove) | **POST** /api/approvals/{id}/approve | 
[**approvalsControllerCancel**](ApprovalsApi.md#approvalscontrollercancel) | **POST** /api/approvals/{id}/cancel | 
[**approvalsControllerCreate**](ApprovalsApi.md#approvalscontrollercreate) | **POST** /api/projects/{projectId}/approvals | 
[**approvalsControllerGet**](ApprovalsApi.md#approvalscontrollerget) | **GET** /api/approvals/{id} | 
[**approvalsControllerList**](ApprovalsApi.md#approvalscontrollerlist) | **GET** /api/projects/{projectId}/approvals | 
[**approvalsControllerReject**](ApprovalsApi.md#approvalscontrollerreject) | **POST** /api/approvals/{id}/reject | 
[**approvalsControllerResubmit**](ApprovalsApi.md#approvalscontrollerresubmit) | **POST** /api/approvals/{id}/resubmit | 


# **approvalsControllerApprove**
> approvalsControllerApprove(id, decideApprovalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String id = id_example; // String | 
final DecideApprovalDto decideApprovalDto = ; // DecideApprovalDto | 

try {
    api.approvalsControllerApprove(id, decideApprovalDto);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerApprove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **decideApprovalDto** | [**DecideApprovalDto**](DecideApprovalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approvalsControllerCancel**
> approvalsControllerCancel(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String id = id_example; // String | 

try {
    api.approvalsControllerCancel(id);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerCancel: $e\n');
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

# **approvalsControllerCreate**
> approvalsControllerCreate(projectId, createApprovalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String projectId = projectId_example; // String | 
final CreateApprovalDto createApprovalDto = ; // CreateApprovalDto | 

try {
    api.approvalsControllerCreate(projectId, createApprovalDto);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createApprovalDto** | [**CreateApprovalDto**](CreateApprovalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approvalsControllerGet**
> approvalsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String id = id_example; // String | 

try {
    api.approvalsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerGet: $e\n');
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

# **approvalsControllerList**
> approvalsControllerList(projectId, scope, status, addresseeId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String projectId = projectId_example; // String | 
final String scope = scope_example; // String | 
final String status = status_example; // String | 
final String addresseeId = addresseeId_example; // String | 

try {
    api.approvalsControllerList(projectId, scope, status, addresseeId);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **scope** | **String**|  | 
 **status** | **String**|  | 
 **addresseeId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approvalsControllerReject**
> approvalsControllerReject(id, decideApprovalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String id = id_example; // String | 
final DecideApprovalDto decideApprovalDto = ; // DecideApprovalDto | 

try {
    api.approvalsControllerReject(id, decideApprovalDto);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerReject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **decideApprovalDto** | [**DecideApprovalDto**](DecideApprovalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approvalsControllerResubmit**
> approvalsControllerResubmit(id, resubmitApprovalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getApprovalsApi();
final String id = id_example; // String | 
final ResubmitApprovalDto resubmitApprovalDto = ; // ResubmitApprovalDto | 

try {
    api.approvalsControllerResubmit(id, resubmitApprovalDto);
} catch on DioException (e) {
    print('Exception when calling ApprovalsApi->approvalsControllerResubmit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **resubmitApprovalDto** | [**ResubmitApprovalDto**](ResubmitApprovalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

