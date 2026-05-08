# repair_control_api.api.LegalPublicApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**legalPublicControllerListVersions**](LegalPublicApi.md#legalpubliccontrollerlistversions) | **GET** /api/legal/{kind}/versions | 
[**legalPublicControllerRender**](LegalPublicApi.md#legalpubliccontrollerrender) | **GET** /api/legal/{kind} | 


# **legalPublicControllerListVersions**
> legalPublicControllerListVersions(kind)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalPublicApi();
final String kind = kind_example; // String | 

try {
    api.legalPublicControllerListVersions(kind);
} catch on DioException (e) {
    print('Exception when calling LegalPublicApi->legalPublicControllerListVersions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalPublicControllerRender**
> legalPublicControllerRender(kind)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalPublicApi();
final String kind = kind_example; // String | 

try {
    api.legalPublicControllerRender(kind);
} catch on DioException (e) {
    print('Exception when calling LegalPublicApi->legalPublicControllerRender: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

