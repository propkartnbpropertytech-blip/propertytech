import 'api_client.dart';
import 'api_constants.dart';

class TestConnection {

  final ApiClient api = ApiClient();

  Future<void> check() async {

    try {

      final response = await api.get(ApiConstants.health);

      print(response.data);

    } catch (e) {

      print(e);

    }

  }

}