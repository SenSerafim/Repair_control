# repair_control_api.model.CreateApprovalDto

## Load the model package
```dart
import 'package:repair_control_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**scope** | **String** |  | 
**stageId** | **String** |  | [optional] 
**stepId** | **String** |  | [optional] 
**addresseeId** | **String** | Адресат решения (foreman/customer) | 
**payload** | **Object** | Payload scope-specific (newEnd, stages[], price, ...) | [optional] 
**attachmentKeys** | **List&lt;String&gt;** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


