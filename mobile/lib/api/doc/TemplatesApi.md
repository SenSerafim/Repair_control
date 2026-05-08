# repair_control_api.api.TemplatesApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**templatesControllerApply**](TemplatesApi.md#templatescontrollerapply) | **POST** /api/templates/{templateId}/apply | 
[**templatesControllerGet**](TemplatesApi.md#templatescontrollerget) | **GET** /api/templates/{id} | 
[**templatesControllerPlatform**](TemplatesApi.md#templatescontrollerplatform) | **GET** /api/templates/platform | 
[**templatesControllerSaveFromStage**](TemplatesApi.md#templatescontrollersavefromstage) | **POST** /api/templates/from-stage/{stageId} | 
[**templatesControllerUser**](TemplatesApi.md#templatescontrolleruser) | **GET** /api/templates/user | 


# **templatesControllerApply**
> templatesControllerApply(templateId, createStageFromTemplateDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getTemplatesApi();
final String templateId = templateId_example; // String | 
final CreateStageFromTemplateDto createStageFromTemplateDto = ; // CreateStageFromTemplateDto | 

try {
    api.templatesControllerApply(templateId, createStageFromTemplateDto);
} catch on DioException (e) {
    print('Exception when calling TemplatesApi->templatesControllerApply: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **templateId** | **String**|  | 
 **createStageFromTemplateDto** | [**CreateStageFromTemplateDto**](CreateStageFromTemplateDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **templatesControllerGet**
> templatesControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getTemplatesApi();
final String id = id_example; // String | 

try {
    api.templatesControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling TemplatesApi->templatesControllerGet: $e\n');
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

# **templatesControllerPlatform**
> templatesControllerPlatform()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getTemplatesApi();

try {
    api.templatesControllerPlatform();
} catch on DioException (e) {
    print('Exception when calling TemplatesApi->templatesControllerPlatform: $e\n');
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

# **templatesControllerSaveFromStage**
> templatesControllerSaveFromStage(stageId, saveAsTemplateDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getTemplatesApi();
final String stageId = stageId_example; // String | 
final SaveAsTemplateDto saveAsTemplateDto = ; // SaveAsTemplateDto | 

try {
    api.templatesControllerSaveFromStage(stageId, saveAsTemplateDto);
} catch on DioException (e) {
    print('Exception when calling TemplatesApi->templatesControllerSaveFromStage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 
 **saveAsTemplateDto** | [**SaveAsTemplateDto**](SaveAsTemplateDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **templatesControllerUser**
> templatesControllerUser()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getTemplatesApi();

try {
    api.templatesControllerUser();
} catch on DioException (e) {
    print('Exception when calling TemplatesApi->templatesControllerUser: $e\n');
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

