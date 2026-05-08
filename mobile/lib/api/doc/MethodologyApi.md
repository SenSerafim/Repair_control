# repair_control_api.api.MethodologyApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**methodologyControllerCreateArticle**](MethodologyApi.md#methodologycontrollercreatearticle) | **POST** /api/admin/methodology/sections/{sectionId}/articles | 
[**methodologyControllerCreateSection**](MethodologyApi.md#methodologycontrollercreatesection) | **POST** /api/admin/methodology/sections | 
[**methodologyControllerDeleteArticle**](MethodologyApi.md#methodologycontrollerdeletearticle) | **DELETE** /api/admin/methodology/articles/{id} | 
[**methodologyControllerDeleteSection**](MethodologyApi.md#methodologycontrollerdeletesection) | **DELETE** /api/admin/methodology/sections/{id} | 
[**methodologyControllerGetArticle**](MethodologyApi.md#methodologycontrollergetarticle) | **GET** /api/methodology/articles/{id} | 
[**methodologyControllerGetSection**](MethodologyApi.md#methodologycontrollergetsection) | **GET** /api/methodology/sections/{id} | 
[**methodologyControllerListSections**](MethodologyApi.md#methodologycontrollerlistsections) | **GET** /api/methodology/sections | 
[**methodologyControllerSearch**](MethodologyApi.md#methodologycontrollersearch) | **GET** /api/methodology/search | 
[**methodologyControllerUpdateArticle**](MethodologyApi.md#methodologycontrollerupdatearticle) | **PATCH** /api/admin/methodology/articles/{id} | 
[**methodologyControllerUpdateSection**](MethodologyApi.md#methodologycontrollerupdatesection) | **PATCH** /api/admin/methodology/sections/{id} | 


# **methodologyControllerCreateArticle**
> methodologyControllerCreateArticle(sectionId, createArticleDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String sectionId = sectionId_example; // String | 
final CreateArticleDto createArticleDto = ; // CreateArticleDto | 

try {
    api.methodologyControllerCreateArticle(sectionId, createArticleDto);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerCreateArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sectionId** | **String**|  | 
 **createArticleDto** | [**CreateArticleDto**](CreateArticleDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **methodologyControllerCreateSection**
> methodologyControllerCreateSection(createSectionDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final CreateSectionDto createSectionDto = ; // CreateSectionDto | 

try {
    api.methodologyControllerCreateSection(createSectionDto);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerCreateSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createSectionDto** | [**CreateSectionDto**](CreateSectionDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **methodologyControllerDeleteArticle**
> methodologyControllerDeleteArticle(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 

try {
    api.methodologyControllerDeleteArticle(id);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerDeleteArticle: $e\n');
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

# **methodologyControllerDeleteSection**
> methodologyControllerDeleteSection(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 

try {
    api.methodologyControllerDeleteSection(id);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerDeleteSection: $e\n');
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

# **methodologyControllerGetArticle**
> methodologyControllerGetArticle(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 

try {
    api.methodologyControllerGetArticle(id);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerGetArticle: $e\n');
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

# **methodologyControllerGetSection**
> methodologyControllerGetSection(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 

try {
    api.methodologyControllerGetSection(id);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerGetSection: $e\n');
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

# **methodologyControllerListSections**
> methodologyControllerListSections()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();

try {
    api.methodologyControllerListSections();
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerListSections: $e\n');
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

# **methodologyControllerSearch**
> methodologyControllerSearch(q, limit)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String q = q_example; // String | 
final String limit = limit_example; // String | 

try {
    api.methodologyControllerSearch(q, limit);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerSearch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | 
 **limit** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **methodologyControllerUpdateArticle**
> methodologyControllerUpdateArticle(id, updateArticleDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 
final UpdateArticleDto updateArticleDto = ; // UpdateArticleDto | 

try {
    api.methodologyControllerUpdateArticle(id, updateArticleDto);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerUpdateArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateArticleDto** | [**UpdateArticleDto**](UpdateArticleDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **methodologyControllerUpdateSection**
> methodologyControllerUpdateSection(id, updateSectionDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMethodologyApi();
final String id = id_example; // String | 
final UpdateSectionDto updateSectionDto = ; // UpdateSectionDto | 

try {
    api.methodologyControllerUpdateSection(id, updateSectionDto);
} catch on DioException (e) {
    print('Exception when calling MethodologyApi->methodologyControllerUpdateSection: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **updateSectionDto** | [**UpdateSectionDto**](UpdateSectionDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

