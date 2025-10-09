import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<void> uploadFile(String path) async {
    var uri = Uri.parse("$baseUrl/upload");
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', path));
    var response = await request.send();

    if (response.statusCode == 200) {
      print("✅ Upload sukses");
    } else {
      print("❌ Upload gagal: ${response.statusCode}");
    }
  }
}
