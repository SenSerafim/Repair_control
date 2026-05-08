# repair_control_api.api.StepsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**stepsControllerAddSubstep**](StepsApi.md#stepscontrolleraddsubstep) | **POST** /api/steps/{stepId}/substeps | 
[**stepsControllerCompleteStep**](StepsApi.md#stepscontrollercompletestep) | **POST** /api/steps/{stepId}/complete | 
[**stepsControllerCompleteSubstep**](StepsApi.md#stepscontrollercompletesubstep) | **POST** /api/substeps/{substepId}/complete | 
[**stepsControllerConfirmPhoto**](StepsApi.md#stepscontrollerconfirmphoto) | **POST** /api/steps/{stepId}/photos/confirm | 
[**stepsControllerCreateStep**](StepsApi.md#stepscontrollercreatestep) | **POST** /api/stages/{stageId}/steps | 
[**stepsControllerDeletePhoto**](StepsApi.md#stepscontrollerdeletephoto) | **DELETE** /api/photos/{photoId} | 
[**stepsControllerDeleteStep**](StepsApi.md#stepscontrollerdeletestep) | **DELETE** /api/steps/{stepId} | 
[**stepsControllerDeleteSubstep**](StepsApi.md#stepscontrollerdeletesubstep) | **DELETE** /api/substeps/{substepId} | 
[**stepsControllerGetStep**](StepsApi.md#stepscontrollergetstep) | **GET** /api/steps/{stepId} | 
[**stepsControllerListPhotos**](StepsApi.md#stepscontrollerlistphotos) | **GET** /api/steps/{stepId}/photos | 
[**stepsControllerListSteps**](StepsApi.md#stepscontrollerliststeps) | **GET** /api/stages/{stageId}/steps | 
[**stepsControllerPresignPhoto**](StepsApi.md#stepscontrollerpresignphoto) | **POST** /api/steps/{stepId}/photos/presign | 
[**stepsControllerReorderSteps**](StepsApi.md#stepscontrollerreordersteps) | **PATCH** /api/stages/{stageId}/steps/reorder | 
[**stepsControllerUncompleteStep**](StepsApi.md#stepscontrolleruncompletestep) | **POST** /api/steps/{stepId}/uncomplete | 
[**stepsControllerUncompleteSubstep**](StepsApi.md#stepscontrolleruncompletesubstep) | **POST** /api/substeps/{substepId}/uncomplete | 
[**stepsControllerUpdateStep**](StepsApi.md#stepscontrollerupdatestep) | **PATCH** /api/steps/{stepId} | 
[**stepsControllerUpdateSubstep**](StepsApi.md#stepscontrollerupdatesubstep) | **PATCH** /api/substeps/{substepId} | 


# **stepsControllerAddSubstep**
> stepsControllerAddSubstep(stepId, addSubstepDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 
final AddSubstepDto addSubstepDto = ; // AddSubstepDto | 

try {
    api.stepsControllerAddSubstep(stepId, addSubstepDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerAddSubstep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 
 **addSubstepDto** | [**AddSubstepDto**](AddSubstepDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerCompleteStep**
> stepsControllerCompleteStep(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 

try {
    api.stepsControllerCompleteStep(stepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerCompleteStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerCompleteSubstep**
> stepsControllerCompleteSubstep(substepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String substepId = substepId_example; // String | 

try {
    api.stepsControllerCompleteSubstep(substepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerCompleteSubstep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **substepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerConfirmPhoto**
> stepsControllerConfirmPhoto(stepId, confirmPhotoDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 
final ConfirmPhotoDto confirmPhotoDto = ; // ConfirmPhotoDto | 

try {
    api.stepsControllerConfirmPhoto(stepId, confirmPhotoDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerConfirmPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 
 **confirmPhotoDto** | [**ConfirmPhotoDto**](ConfirmPhotoDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerCreateStep**
> stepsControllerCreateStep(stageId, createStepDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stageId = stageId_example; // String | 
final CreateStepDto createStepDto = ; // CreateStepDto | 

try {
    api.stepsControllerCreateStep(stageId, createStepDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerCreateStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 
 **createStepDto** | [**CreateStepDto**](CreateStepDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerDeletePhoto**
> stepsControllerDeletePhoto(photoId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String photoId = photoId_example; // String | 

try {
    api.stepsControllerDeletePhoto(photoId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerDeletePhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **photoId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerDeleteStep**
> stepsControllerDeleteStep(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 

try {
    api.stepsControllerDeleteStep(stepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerDeleteStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerDeleteSubstep**
> stepsControllerDeleteSubstep(substepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String substepId = substepId_example; // String | 

try {
    api.stepsControllerDeleteSubstep(substepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerDeleteSubstep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **substepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerGetStep**
> stepsControllerGetStep(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 

try {
    api.stepsControllerGetStep(stepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerGetStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerListPhotos**
> stepsControllerListPhotos(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 

try {
    api.stepsControllerListPhotos(stepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerListPhotos: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerListSteps**
> stepsControllerListSteps(stageId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stageId = stageId_example; // String | 

try {
    api.stepsControllerListSteps(stageId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerListSteps: $e\n');
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

# **stepsControllerPresignPhoto**
> stepsControllerPresignPhoto(stepId, presignPhotoDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 
final PresignPhotoDto presignPhotoDto = ; // PresignPhotoDto | 

try {
    api.stepsControllerPresignPhoto(stepId, presignPhotoDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerPresignPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 
 **presignPhotoDto** | [**PresignPhotoDto**](PresignPhotoDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerReorderSteps**
> stepsControllerReorderSteps(stageId, reorderStepsDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stageId = stageId_example; // String | 
final ReorderStepsDto reorderStepsDto = ; // ReorderStepsDto | 

try {
    api.stepsControllerReorderSteps(stageId, reorderStepsDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerReorderSteps: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stageId** | **String**|  | 
 **reorderStepsDto** | [**ReorderStepsDto**](ReorderStepsDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerUncompleteStep**
> stepsControllerUncompleteStep(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 

try {
    api.stepsControllerUncompleteStep(stepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerUncompleteStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerUncompleteSubstep**
> stepsControllerUncompleteSubstep(substepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String substepId = substepId_example; // String | 

try {
    api.stepsControllerUncompleteSubstep(substepId);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerUncompleteSubstep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **substepId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerUpdateStep**
> stepsControllerUpdateStep(stepId, updateStepDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String stepId = stepId_example; // String | 
final UpdateStepDto updateStepDto = ; // UpdateStepDto | 

try {
    api.stepsControllerUpdateStep(stepId, updateStepDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerUpdateStep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 
 **updateStepDto** | [**UpdateStepDto**](UpdateStepDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **stepsControllerUpdateSubstep**
> stepsControllerUpdateSubstep(substepId, updateSubstepDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getStepsApi();
final String substepId = substepId_example; // String | 
final UpdateSubstepDto updateSubstepDto = ; // UpdateSubstepDto | 

try {
    api.stepsControllerUpdateSubstep(substepId, updateSubstepDto);
} catch on DioException (e) {
    print('Exception when calling StepsApi->stepsControllerUpdateSubstep: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **substepId** | **String**|  | 
 **updateSubstepDto** | [**UpdateSubstepDto**](UpdateSubstepDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

