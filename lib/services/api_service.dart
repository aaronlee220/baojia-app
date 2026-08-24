import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'http://154.51.40.17:8806';
  
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['products'] as List).map((p) => Product.fromJson(p)).toList();
      }
    } catch (e) {
      print('获取产品失败: $e');
    }
    return [];
  }
}
