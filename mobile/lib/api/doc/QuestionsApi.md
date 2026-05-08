# repair_control_api.api.QuestionsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**questionsControllerAnswer**](QuestionsApi.md#questionscontrolleranswer) | **POST** /api/questions/{id}/answer | 
[**questionsControllerAsk**](QuestionsApi.md#questionscontrollerask) | **POST** /api/steps/{stepId}/questions | 
[**questionsControllerClose**](QuestionsApi.md#questionscontrollerclose) | **POST** /api/questions/{id}/close | 
[**questionsControllerListForStep**](QuestionsApi.md#questionscontrollerlistforstep) | **GET** /api/steps/{stepId}/questions | 
[**questionsControllerListMine**](QuestionsApi.md#questionscontrollerlistmine) | **GET** /api/me/questions | 


# **questionsControllerAnswer**
> questionsControllerAnswer(id, answerQuestionDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getQuestionsApi();
final String id = id_example; // String | 
final AnswerQuestionDto answerQuestionDto = ; // AnswerQuestionDto | 

try {
    api.questionsControllerAnswer(id, answerQuestionDto);
} catch on DioException (e) {
    print('Exception when calling QuestionsApi->questionsControllerAnswer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **answerQuestionDto** | [**AnswerQuestionDto**](AnswerQuestionDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **questionsControllerAsk**
> questionsControllerAsk(stepId, askQuestionDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getQuestionsApi();
final String stepId = stepId_example; // String | 
final AskQuestionDto askQuestionDto = ; // AskQuestionDto | 

try {
    api.questionsControllerAsk(stepId, askQuestionDto);
} catch on DioException (e) {
    print('Exception when calling QuestionsApi->questionsControllerAsk: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **stepId** | **String**|  | 
 **askQuestionDto** | [**AskQuestionDto**](AskQuestionDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **questionsControllerClose**
> questionsControllerClose(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getQuestionsApi();
final String id = id_example; // String | 

try {
    api.questionsControllerClose(id);
} catch on DioException (e) {
    print('Exception when calling QuestionsApi->questionsControllerClose: $e\n');
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

# **questionsControllerListForStep**
> questionsControllerListForStep(stepId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getQuestionsApi();
final String stepId = stepId_example; // String | 

try {
    api.questionsControllerListForStep(stepId);
} catch on DioException (e) {
    print('Exception when calling QuestionsApi->questionsControllerListForStep: $e\n');
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

# **questionsControllerListMine**
> questionsControllerListMine(filter)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getQuestionsApi();
final String filter = filter_example; // String | 

try {
    api.questionsControllerListMine(filter);
} catch on DioException (e) {
    print('Exception when calling QuestionsApi->questionsControllerListMine: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **filter** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

