# repair_control_api.api.FilesApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**filesApiControllerPresign**](FilesApi.md#filesapicontrollerpresign) | **POST** /api/files/presign-upload | 


# **filesApiControllerPresign**
> filesApiControllerPresign(body)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getFilesApi();
final Object body = Object; // Object | 

try {
    api.filesApiControllerPresign(body);
} catch on DioException (e) {
    print('Exception when calling FilesApi->filesApiControllerPresign: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **Object**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

