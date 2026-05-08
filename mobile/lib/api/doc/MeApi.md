# repair_control_api.api.MeApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**usersControllerAddDevice**](MeApi.md#userscontrolleradddevice) | **POST** /api/me/devices | 
[**usersControllerAddRole**](MeApi.md#userscontrolleraddrole) | **POST** /api/me/roles | 
[**usersControllerMe**](MeApi.md#userscontrollerme) | **GET** /api/me | 
[**usersControllerRemoveRole**](MeApi.md#userscontrollerremoverole) | **DELETE** /api/me/roles/{role} | 
[**usersControllerRoles**](MeApi.md#userscontrollerroles) | **GET** /api/me/roles | 
[**usersControllerSetActive**](MeApi.md#userscontrollersetactive) | **PUT** /api/me/active-role | 
[**usersControllerUpdateMe**](MeApi.md#userscontrollerupdateme) | **PATCH** /api/me | 


# **usersControllerAddDevice**
> usersControllerAddDevice(registerDeviceDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();
final RegisterDeviceDto registerDeviceDto = ; // RegisterDeviceDto | 

try {
    api.usersControllerAddDevice(registerDeviceDto);
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerAddDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDeviceDto** | [**RegisterDeviceDto**](RegisterDeviceDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerAddRole**
> usersControllerAddRole(addRoleDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();
final AddRoleDto addRoleDto = ; // AddRoleDto | 

try {
    api.usersControllerAddRole(addRoleDto);
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerAddRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **addRoleDto** | [**AddRoleDto**](AddRoleDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerMe**
> usersControllerMe()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();

try {
    api.usersControllerMe();
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerMe: $e\n');
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

# **usersControllerRemoveRole**
> usersControllerRemoveRole(role)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();
final String role = role_example; // String | 

try {
    api.usersControllerRemoveRole(role);
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerRemoveRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **role** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerRoles**
> usersControllerRoles()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();

try {
    api.usersControllerRoles();
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerRoles: $e\n');
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

# **usersControllerSetActive**
> usersControllerSetActive(setActiveRoleDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();
final SetActiveRoleDto setActiveRoleDto = ; // SetActiveRoleDto | 

try {
    api.usersControllerSetActive(setActiveRoleDto);
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerSetActive: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **setActiveRoleDto** | [**SetActiveRoleDto**](SetActiveRoleDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **usersControllerUpdateMe**
> usersControllerUpdateMe(updateProfileDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getMeApi();
final UpdateProfileDto updateProfileDto = ; // UpdateProfileDto | 

try {
    api.usersControllerUpdateMe(updateProfileDto);
} catch on DioException (e) {
    print('Exception when calling MeApi->usersControllerUpdateMe: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateProfileDto** | [**UpdateProfileDto**](UpdateProfileDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

