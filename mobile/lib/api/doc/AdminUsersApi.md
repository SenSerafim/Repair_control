# repair_control_api.api.AdminUsersApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminUsersControllerAudit**](AdminUsersApi.md#adminuserscontrolleraudit) | **GET** /api/admin/users/{id}/audit | 
[**adminUsersControllerBan**](AdminUsersApi.md#adminuserscontrollerban) | **POST** /api/admin/users/{id}/ban | 
[**adminUsersControllerDetail**](AdminUsersApi.md#adminuserscontrollerdetail) | **GET** /api/admin/users/{id} | 
[**adminUsersControllerForceLogout**](AdminUsersApi.md#adminuserscontrollerforcelogout) | **DELETE** /api/admin/users/{id}/sessions | 
[**adminUsersControllerList**](AdminUsersApi.md#adminuserscontrollerlist) | **GET** /api/admin/users | 
[**adminUsersControllerResetPassword**](AdminUsersApi.md#adminuserscontrollerresetpassword) | **POST** /api/admin/users/{id}/reset-password | 
[**adminUsersControllerSetRoles**](AdminUsersApi.md#adminuserscontrollersetroles) | **PATCH** /api/admin/users/{id}/roles | 
[**adminUsersControllerUnban**](AdminUsersApi.md#adminuserscontrollerunban) | **POST** /api/admin/users/{id}/unban | 


# **adminUsersControllerAudit**
> adminUsersControllerAudit(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 

try {
    api.adminUsersControllerAudit(id);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerAudit: $e\n');
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

# **adminUsersControllerBan**
> adminUsersControllerBan(id, banUserDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 
final BanUserDto banUserDto = ; // BanUserDto | 

try {
    api.adminUsersControllerBan(id, banUserDto);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerBan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **banUserDto** | [**BanUserDto**](BanUserDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUsersControllerDetail**
> adminUsersControllerDetail(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 

try {
    api.adminUsersControllerDetail(id);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerDetail: $e\n');
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

# **adminUsersControllerForceLogout**
> adminUsersControllerForceLogout(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 

try {
    api.adminUsersControllerForceLogout(id);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerForceLogout: $e\n');
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

# **adminUsersControllerList**
> adminUsersControllerList(q, role, banned, limit, offset)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String q = q_example; // String | 
final String role = role_example; // String | 
final bool banned = true; // bool | 
final num limit = 8.14; // num | 
final num offset = 8.14; // num | 

try {
    api.adminUsersControllerList(q, role, banned, limit, offset);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional] 
 **role** | **String**|  | [optional] 
 **banned** | **bool**|  | [optional] 
 **limit** | **num**|  | [optional] 
 **offset** | **num**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUsersControllerResetPassword**
> adminUsersControllerResetPassword(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 

try {
    api.adminUsersControllerResetPassword(id);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerResetPassword: $e\n');
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

# **adminUsersControllerSetRoles**
> adminUsersControllerSetRoles(id, setRolesDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 
final SetRolesDto setRolesDto = ; // SetRolesDto | 

try {
    api.adminUsersControllerSetRoles(id, setRolesDto);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerSetRoles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  | 
 **setRolesDto** | [**SetRolesDto**](SetRolesDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adminUsersControllerUnban**
> adminUsersControllerUnban(id)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAdminUsersApi();
final String id = id_example; // String | 

try {
    api.adminUsersControllerUnban(id);
} catch on DioException (e) {
    print('Exception when calling AdminUsersApi->adminUsersControllerUnban: $e\n');
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

