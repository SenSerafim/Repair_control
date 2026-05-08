# repair_control_api.api.HealthApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthControllerHealth**](HealthApi.md#healthcontrollerhealth) | **GET** /healthz | 


# **healthControllerHealth**
> healthControllerHealth()



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getHealthApi();

try {
    api.healthControllerHealth();
} catch on DioException (e) {
    print('Exception when calling HealthApi->healthControllerHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

