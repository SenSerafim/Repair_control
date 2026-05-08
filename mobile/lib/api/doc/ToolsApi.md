# repair_control_api.api.ToolsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**toolsControllerConfirmReceipt**](ToolsApi.md#toolscontrollerconfirmreceipt) | **POST** /api/tool-issuances/{id}/confirm | 
[**toolsControllerConfirmReturn**](ToolsApi.md#toolscontrollerconfirmreturn) | **POST** /api/tool-issuances/{id}/return-confirm | 
[**toolsControllerCreate**](ToolsApi.md#toolscontrollercreate) | **POST** /api/me/tools | 
[**toolsControllerGet**](ToolsApi.md#toolscontrollerget) | **GET** /api/tools/{id} | 
[**toolsControllerIssue**](ToolsApi.md#toolscontrollerissue) | **POST** /api/projects/{projectId}/tool-issuances | 
[**toolsControllerList**](ToolsApi.md#toolscontrollerlist) | **GET** /api/projects/{projectId}/tool-issuances | 
[**toolsControllerListMine**](ToolsApi.md#toolscontrollerlistmine) | **GET** /api/me/tools | 
[**toolsControllerRequestReturn**](ToolsApi.md#toolscontrollerrequestreturn) | **POST** /api/tool-issuances/{id}/return | 
[**toolsControllerUpdate**](ToolsApi.md#toolscontrollerupdate) | **PATCH** /api/tools/{id} | 


# **toolsControllerConfirmReceipt**
> toolsControllerConfirmReceipt(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String id = id_example; // String | 

try {
    api.toolsControllerConfirmReceipt(id);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerConfirmReceipt: $e\n');
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

# **toolsControllerConfirmReturn**
> toolsControllerConfirmReturn(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String id = id_example; // String | 

try {
    api.toolsControllerConfirmReturn(id);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerConfirmReturn: $e\n');
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

# **toolsControllerCreate**
> toolsControllerCreate(createToolDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final CreateToolDto createToolDto = ; // CreateToolDto | 

try {
    api.toolsControllerCreate(createToolDto);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createToolDto** | [**CreateToolDto**](CreateToolDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **toolsControllerGet**
> toolsControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String id = id_example; // String | 

try {
    api.toolsControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerGet: $e\n');
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

# **toolsControllerIssue**
> toolsControllerIssue(projectId, issueToolDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String projectId = projectId_example; // String | 
final IssueToolDto issueToolDto = ; // IssueToolDto | 

try {
    api.toolsControllerIssue(projectId, issueToolDto);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerIssue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **issueToolDto** | [**IssueToolDto**](IssueToolDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **toolsControllerList**
> toolsControllerList(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String projectId = projectId_example; // String | 

try {
    api.toolsControllerList(projectId);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerList: $e\n');
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

# **toolsControllerListMine**
> toolsControllerListMine()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();

try {
    api.toolsControllerListMine();
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerListMine: $e\n');
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

# **toolsControllerRequestReturn**
> toolsControllerRequestReturn(id, returnToolDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String id = id_example; // String | 
final ReturnToolDto returnToolDto = ; // ReturnToolDto | 

try {
    api.toolsControllerRequestReturn(id, returnToolDto);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerRequestReturn: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **returnToolDto** | [**ReturnToolDto**](ReturnToolDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **toolsControllerUpdate**
> toolsControllerUpdate(id, updateToolDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getToolsApi();
final String id = id_example; // String | 
final UpdateToolDto updateToolDto = ; // UpdateToolDto | 

try {
    api.toolsControllerUpdate(id, updateToolDto);
} catch on DioException (e) {
    print('Exception when calling ToolsApi->toolsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateToolDto** | [**UpdateToolDto**](UpdateToolDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

