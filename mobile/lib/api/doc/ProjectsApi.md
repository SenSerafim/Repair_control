# repair_control_api.api.ProjectsApi

## Load the API package
```dart
import 'package:repair_control_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**projectsControllerAddMember**](ProjectsApi.md#projectscontrolleraddmember) | **POST** /api/projects/{projectId}/members | 
[**projectsControllerArchive**](ProjectsApi.md#projectscontrollerarchive) | **POST** /api/projects/{projectId}/archive | 
[**projectsControllerCancelInvitation**](ProjectsApi.md#projectscontrollercancelinvitation) | **DELETE** /api/projects/{projectId}/invitations/{invitationId} | 
[**projectsControllerCopy**](ProjectsApi.md#projectscontrollercopy) | **POST** /api/projects/{projectId}/copy | 
[**projectsControllerCreate**](ProjectsApi.md#projectscontrollercreate) | **POST** /api/projects | 
[**projectsControllerGet**](ProjectsApi.md#projectscontrollerget) | **GET** /api/projects/{projectId} | 
[**projectsControllerInvite**](ProjectsApi.md#projectscontrollerinvite) | **POST** /api/projects/{projectId}/invitations | 
[**projectsControllerList**](ProjectsApi.md#projectscontrollerlist) | **GET** /api/projects | 
[**projectsControllerListInvitations**](ProjectsApi.md#projectscontrollerlistinvitations) | **GET** /api/projects/{projectId}/invitations | 
[**projectsControllerListMembers**](ProjectsApi.md#projectscontrollerlistmembers) | **GET** /api/projects/{projectId}/members | 
[**projectsControllerRemoveMember**](ProjectsApi.md#projectscontrollerremovemember) | **DELETE** /api/projects/{projectId}/members/{membershipId} | 
[**projectsControllerRestore**](ProjectsApi.md#projectscontrollerrestore) | **POST** /api/projects/{projectId}/restore | 
[**projectsControllerSearchUser**](ProjectsApi.md#projectscontrollersearchuser) | **GET** /api/projects/{projectId}/search-user | 
[**projectsControllerUpdate**](ProjectsApi.md#projectscontrollerupdate) | **PATCH** /api/projects/{projectId} | 
[**projectsControllerUpdateMember**](ProjectsApi.md#projectscontrollerupdatemember) | **PATCH** /api/projects/{projectId}/members/{membershipId} | 


# **projectsControllerAddMember**
> projectsControllerAddMember(projectId, addMemberDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final AddMemberDto addMemberDto = ; // AddMemberDto | 

try {
    api.projectsControllerAddMember(projectId, addMemberDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerAddMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **addMemberDto** | [**AddMemberDto**](AddMemberDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerArchive**
> projectsControllerArchive(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.projectsControllerArchive(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerArchive: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerCancelInvitation**
> projectsControllerCancelInvitation(projectId, invitationId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final String invitationId = invitationId_example; // String | 

try {
    api.projectsControllerCancelInvitation(projectId, invitationId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerCancelInvitation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **invitationId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerCopy**
> projectsControllerCopy(projectId, copyProjectDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final CopyProjectDto copyProjectDto = ; // CopyProjectDto | 

try {
    api.projectsControllerCopy(projectId, copyProjectDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerCopy: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **copyProjectDto** | [**CopyProjectDto**](CopyProjectDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerCreate**
> projectsControllerCreate(createProjectDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final CreateProjectDto createProjectDto = ; // CreateProjectDto | 

try {
    api.projectsControllerCreate(createProjectDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createProjectDto** | [**CreateProjectDto**](CreateProjectDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerGet**
> projectsControllerGet(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.projectsControllerGet(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerInvite**
> projectsControllerInvite(projectId, inviteByPhoneDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final InviteByPhoneDto inviteByPhoneDto = ; // InviteByPhoneDto | 

try {
    api.projectsControllerInvite(projectId, inviteByPhoneDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerInvite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **inviteByPhoneDto** | [**InviteByPhoneDto**](InviteByPhoneDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerList**
> projectsControllerList(status)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String status = status_example; // String | 

try {
    api.projectsControllerList(status);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerListInvitations**
> projectsControllerListInvitations(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.projectsControllerListInvitations(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerListInvitations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerListMembers**
> projectsControllerListMembers(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.projectsControllerListMembers(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerListMembers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerRemoveMember**
> projectsControllerRemoveMember(projectId, membershipId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final String membershipId = membershipId_example; // String | 

try {
    api.projectsControllerRemoveMember(projectId, membershipId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerRemoveMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **membershipId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerRestore**
> projectsControllerRestore(projectId)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 

try {
    api.projectsControllerRestore(projectId);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerRestore: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerSearchUser**
> projectsControllerSearchUser(phone, email)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String phone = phone_example; // String | 
final String email = email_example; // String | 

try {
    api.projectsControllerSearchUser(phone, email);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerSearchUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **phone** | **String**|  | [optional] 
 **email** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerUpdate**
> projectsControllerUpdate(projectId, updateProjectDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final UpdateProjectDto updateProjectDto = ; // UpdateProjectDto | 

try {
    api.projectsControllerUpdate(projectId, updateProjectDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **updateProjectDto** | [**UpdateProjectDto**](UpdateProjectDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **projectsControllerUpdateMember**
> projectsControllerUpdateMember(projectId, membershipId, updateMembershipDto)



### Example
```dart
import 'package:repair_control_api/api.dart';

final api = RepairControlApi().getProjectsApi();
final String projectId = projectId_example; // String | 
final String membershipId = membershipId_example; // String | 
final UpdateMembershipDto updateMembershipDto = ; // UpdateMembershipDto | 

try {
    api.projectsControllerUpdateMember(projectId, membershipId, updateMembershipDto);
} catch on DioException (e) {
    print('Exception when calling ProjectsApi->projectsControllerUpdateMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **projectId** | **String**|  | 
 **membershipId** | **String**|  | 
 **updateMembershipDto** | [**UpdateMembershipDto**](UpdateMembershipDto.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

