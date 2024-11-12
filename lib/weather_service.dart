import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'd6310cf9f24fe09b6eafa9e3122bc556'; 
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>?> getWeather(String city) async {
    final url = Uri.parse('$baseUrl?q=$city&appid=$apiKey&units=metric&lang=pt_br');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Erro ao buscar clima: ${response.statusCode}');
      return null;
    }
  }
}
