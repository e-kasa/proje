import '../core/api/api_client.dart';

class RegistrationService {
  final ApiClient _apiClient;

  RegistrationService(this._apiClient);

  Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String sectorType,
    required String userName,
    required String password,
    required String displayName,
    String? taxNumber,
    String? taxOffice,
    String? email,
  }) async {
    final response = await _apiClient.post(
      'security/register/company',
      data: {
        'companyName': companyName,
        'sectorType': sectorType,
        'userName': userName,
        'password': password,
        'displayName': displayName,
        if (taxNumber != null) 'taxNumber': taxNumber,
        if (taxOffice != null) 'taxOffice': taxOffice,
        if (email != null) 'email': email,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
