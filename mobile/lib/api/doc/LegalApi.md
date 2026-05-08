# repair_control_api.api.LegalApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**legalControllerAccept**](LegalApi.md#legalcontrolleraccept) | **POST** /api/me/legal-acceptance | 
[**legalControllerCreate**](LegalApi.md#legalcontrollercreate) | **POST** /api/admin/legal/documents | 
[**legalControllerGet**](LegalApi.md#legalcontrollerget) | **GET** /api/admin/legal/documents/{id} | 
[**legalControllerListAll**](LegalApi.md#legalcontrollerlistall) | **GET** /api/admin/legal/documents | 
[**legalControllerPublish**](LegalApi.md#legalcontrollerpublish) | **POST** /api/admin/legal/documents/{id}/publish | 
[**legalControllerStatus**](LegalApi.md#legalcontrollerstatus) | **GET** /api/me/legal-acceptance | 
[**legalControllerUpdate**](LegalApi.md#legalcontrollerupdate) | **PATCH** /api/admin/legal/documents/{id} | 


# **legalControllerAccept**
> legalControllerAccept(acceptLegalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final AcceptLegalDto acceptLegalDto = ; // AcceptLegalDto | 

try {
    api.legalControllerAccept(acceptLegalDto);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerAccept: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **acceptLegalDto** | [**AcceptLegalDto**](AcceptLegalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalControllerCreate**
> legalControllerCreate(createLegalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final CreateLegalDto createLegalDto = ; // CreateLegalDto | 

try {
    api.legalControllerCreate(createLegalDto);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createLegalDto** | [**CreateLegalDto**](CreateLegalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalControllerGet**
> legalControllerGet(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final String id = id_example; // String | 

try {
    api.legalControllerGet(id);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerGet: $e\n');
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

# **legalControllerListAll**
> legalControllerListAll(kind)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final String kind = kind_example; // String | 

try {
    api.legalControllerListAll(kind);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerListAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **kind** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **legalControllerPublish**
> legalControllerPublish(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final String id = id_example; // String | 

try {
    api.legalControllerPublish(id);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerPublish: $e\n');
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

# **legalControllerStatus**
> legalControllerStatus()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();

try {
    api.legalControllerStatus();
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerStatus: $e\n');
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

# **legalControllerUpdate**
> legalControllerUpdate(id, updateLegalDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getLegalApi();
final String id = id_example; // String | 
final UpdateLegalDto updateLegalDto = ; // UpdateLegalDto | 

try {
    api.legalControllerUpdate(id, updateLegalDto);
} catch on DioException (e) {
    print('Exception when calling LegalApi->legalControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateLegalDto** | [**UpdateLegalDto**](UpdateLegalDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

