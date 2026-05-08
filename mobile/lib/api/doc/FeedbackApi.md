# repair_control_api.api.FeedbackApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**feedbackControllerCreate**](FeedbackApi.md#feedbackcontrollercreate) | **POST** /api/feedback | 
[**feedbackControllerGet**](FeedbackApi.md#feedbackcontrollerget) | **GET** /api/admin/feedback/{id} | 
[**feedbackControllerList**](FeedbackApi.md#feedbackcontrollerlist) | **GET** /api/admin/feedback | 
[**feedbackControllerPatch**](FeedbackApi.md#feedbackcontrollerpatch) | **PATCH** /api/admin/feedback/{id} | 


# **feedbackControllerCreate**
> feedbackControllerCreate(createFeedbackDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedbackApi();
final CreateFeedbackDto createFeedbackDto = ; // CreateFeedbackDto | 

try {
    api.feedbackControllerCreate(createFeedbackDto);
} catch on DioException (e) {
    print('Exception when calling FeedbackApi->feedbackControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createFeedbackDto** | [**CreateFeedbackDto**](CreateFeedbackDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **feedbackControllerGet**
> feedbackControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedbackApi();
final String id = id_example; // String | 

try {
    api.feedbackControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling FeedbackApi->feedbackControllerGet: $e\n');
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

# **feedbackControllerList**
> feedbackControllerList(status, cursor)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedbackApi();
final String status = status_example; // String | 
final String cursor = cursor_example; // String | 

try {
    api.feedbackControllerList(status, cursor);
} catch on DioException (e) {
    print('Exception when calling FeedbackApi->feedbackControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 
 **cursor** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **feedbackControllerPatch**
> feedbackControllerPatch(id, patchFeedbackDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFeedbackApi();
final String id = id_example; // String | 
final PatchFeedbackDto patchFeedbackDto = ; // PatchFeedbackDto | 

try {
    api.feedbackControllerPatch(id, patchFeedbackDto);
} catch on DioException (e) {
    print('Exception when calling FeedbackApi->feedbackControllerPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **patchFeedbackDto** | [**PatchFeedbackDto**](PatchFeedbackDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

