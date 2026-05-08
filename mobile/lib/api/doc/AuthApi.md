# repair_control_api.api.AuthApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authControllerLogin**](AuthApi.md#authcontrollerlogin) | **POST** /api/auth/login | 
[**authControllerLogout**](AuthApi.md#authcontrollerlogout) | **POST** /api/auth/logout | 
[**authControllerRecoveryReset**](AuthApi.md#authcontrollerrecoveryreset) | **POST** /api/auth/recovery/reset | 
[**authControllerRecoverySend**](AuthApi.md#authcontrollerrecoverysend) | **POST** /api/auth/recovery/send | 
[**authControllerRecoveryVerify**](AuthApi.md#authcontrollerrecoveryverify) | **POST** /api/auth/recovery/verify | 
[**authControllerRefresh**](AuthApi.md#authcontrollerrefresh) | **POST** /api/auth/refresh | 
[**authControllerRegister**](AuthApi.md#authcontrollerregister) | **POST** /api/auth/register | 


# **authControllerLogin**
> authControllerLogin(loginDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final LoginDto loginDto = ; // LoginDto | 

try {
    api.authControllerLogin(loginDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginDto** | [**LoginDto**](LoginDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerLogout**
> authControllerLogout(logoutDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final LogoutDto logoutDto = ; // LogoutDto | 

try {
    api.authControllerLogout(logoutDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logoutDto** | [**LogoutDto**](LogoutDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRecoveryReset**
> authControllerRecoveryReset(recoveryResetDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final RecoveryResetDto recoveryResetDto = ; // RecoveryResetDto | 

try {
    api.authControllerRecoveryReset(recoveryResetDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerRecoveryReset: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **recoveryResetDto** | [**RecoveryResetDto**](RecoveryResetDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRecoverySend**
> authControllerRecoverySend(recoverySendDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final RecoverySendDto recoverySendDto = ; // RecoverySendDto | 

try {
    api.authControllerRecoverySend(recoverySendDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerRecoverySend: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **recoverySendDto** | [**RecoverySendDto**](RecoverySendDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRecoveryVerify**
> authControllerRecoveryVerify(recoveryVerifyDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final RecoveryVerifyDto recoveryVerifyDto = ; // RecoveryVerifyDto | 

try {
    api.authControllerRecoveryVerify(recoveryVerifyDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerRecoveryVerify: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **recoveryVerifyDto** | [**RecoveryVerifyDto**](RecoveryVerifyDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRefresh**
> authControllerRefresh(refreshDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final RefreshDto refreshDto = ; // RefreshDto | 

try {
    api.authControllerRefresh(refreshDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerRefresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshDto** | [**RefreshDto**](RefreshDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authControllerRegister**
> authControllerRegister(registerDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getAuthApi();
final RegisterDto registerDto = ; // RegisterDto | 

try {
    api.authControllerRegister(registerDto);
} catch on DioException (e) {
    print('Exception when calling AuthApi->authControllerRegister: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerDto** | [**RegisterDto**](RegisterDto.md)|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

