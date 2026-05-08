# repair_control_api.api.NotesApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**notesControllerCreate**](NotesApi.md#notescontrollercreate) | **POST** /api/projects/{projectId}/notes | 
[**notesControllerDelete**](NotesApi.md#notescontrollerdelete) | **DELETE** /api/notes/{noteId} | 
[**notesControllerList**](NotesApi.md#notescontrollerlist) | **GET** /api/projects/{projectId}/notes | 
[**notesControllerUpdate**](NotesApi.md#notescontrollerupdate) | **PATCH** /api/notes/{noteId} | 


# **notesControllerCreate**
> notesControllerCreate(projectId, createNoteDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotesApi();
final String projectId = projectId_example; // String | 
final CreateNoteDto createNoteDto = ; // CreateNoteDto | 

try {
    api.notesControllerCreate(projectId, createNoteDto);
} catch on DioException (e) {
    print('Exception when calling NotesApi->notesControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **createNoteDto** | [**CreateNoteDto**](CreateNoteDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesControllerDelete**
> notesControllerDelete(noteId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotesApi();
final String noteId = noteId_example; // String | 

try {
    api.notesControllerDelete(noteId);
} catch on DioException (e) {
    print('Exception when calling NotesApi->notesControllerDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **noteId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesControllerList**
> notesControllerList(projectId, scope, stageId, search)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotesApi();
final String projectId = projectId_example; // String | 
final String scope = scope_example; // String | 
final String stageId = stageId_example; // String | 
final String search = search_example; // String | 

try {
    api.notesControllerList(projectId, scope, stageId, search);
} catch on DioException (e) {
    print('Exception when calling NotesApi->notesControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **scope** | **String**|  | 
 **stageId** | **String**|  | 
 **search** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notesControllerUpdate**
> notesControllerUpdate(noteId, updateNoteDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getNotesApi();
final String noteId = noteId_example; // String | 
final UpdateNoteDto updateNoteDto = ; // UpdateNoteDto | 

try {
    api.notesControllerUpdate(noteId, updateNoteDto);
} catch on DioException (e) {
    print('Exception when calling NotesApi->notesControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **noteId** | **String**|  | 
 **updateNoteDto** | [**UpdateNoteDto**](UpdateNoteDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

