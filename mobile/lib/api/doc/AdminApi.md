# repair_control_api.api.AdminApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminControllerCreateItem**](AdminApi.md#admincontrollercreateitem) | **POST** /api/admin/faq-items | 
[**adminControllerCreateSection**](AdminApi.md#admincontrollercreatesection) | **POST** /api/admin/faq-sections | 
[**adminControllerDeleteItem**](AdminApi.md#admincontrollerdeleteitem) | **DELETE** /api/admin/faq-items/{id} | 
[**adminControllerListFaq**](AdminApi.md#admincontrollerlistfaq) | **GET** /api/admin/faq-sections | 
[**adminControllerListSettings**](AdminApi.md#admincontrollerlistsettings) | **GET** /api/admin/settings | 
[**adminControllerMe**](AdminApi.md#admincontrollerme) | **GET** /api/me/app-settings | 
[**adminControllerPublicFaq**](AdminApi.md#admincontrollerpublicfaq) | **GET** /api/faq | 
[**adminControllerPutSetting**](AdminApi.md#admincontrollerputsetting) | **PUT** /api/admin/settings | 
[**adminControllerUpdateItem**](AdminApi.md#admincontrollerupdateitem) | **PATCH** /api/admin/faq-items/{id} | 


# **adminControllerCreateItem**
> adminControllerCreateItem(createFaqItemDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();
final CreateFaqItemDto createFaqItemDto = ; // CreateFaqItemDto | 

try {
    api.adminControllerCreateItem(createFaqItemDto);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerCreateItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createFaqItemDto** | [**CreateFaqItemDto**](CreateFaqItemDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminControllerCreateSection**
> adminControllerCreateSection(createFaqSectionDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();
final CreateFaqSectionDto createFaqSectionDto = ; // CreateFaqSectionDto | 

try {
    api.adminControllerCreateSection(createFaqSectionDto);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerCreateSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createFaqSectionDto** | [**CreateFaqSectionDto**](CreateFaqSectionDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminControllerDeleteItem**
> adminControllerDeleteItem(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();
final String id = id_example; // String | 

try {
    api.adminControllerDeleteItem(id);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerDeleteItem: $e\n');
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

# **adminControllerListFaq**
> adminControllerListFaq()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();

try {
    api.adminControllerListFaq();
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerListFaq: $e\n');
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

# **adminControllerListSettings**
> adminControllerListSettings()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();

try {
    api.adminControllerListSettings();
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerListSettings: $e\n');
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

# **adminControllerMe**
> adminControllerMe()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();

try {
    api.adminControllerMe();
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerMe: $e\n');
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

# **adminControllerPublicFaq**
> adminControllerPublicFaq()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();

try {
    api.adminControllerPublicFaq();
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerPublicFaq: $e\n');
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

# **adminControllerPutSetting**
> adminControllerPutSetting(putSettingDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();
final PutSettingDto putSettingDto = ; // PutSettingDto | 

try {
    api.adminControllerPutSetting(putSettingDto);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerPutSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **putSettingDto** | [**PutSettingDto**](PutSettingDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminControllerUpdateItem**
> adminControllerUpdateItem(id, updateFaqItemDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminApi();
final String id = id_example; // String | 
final UpdateFaqItemDto updateFaqItemDto = ; // UpdateFaqItemDto | 

try {
    api.adminControllerUpdateItem(id, updateFaqItemDto);
} catch on DioException (e) {
    print('Exception when calling AdminApi->adminControllerUpdateItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateFaqItemDto** | [**UpdateFaqItemDto**](UpdateFaqItemDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

