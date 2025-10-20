import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  static const String _hereApiKey = 'YOUR_HERE_API_KEY';
  static const String _baseUrl = 'https://geocode.search.hereapi.com/v1';

  Future<LatLng?> obterGeoLocalizacao(String endereco) async {
    
    if (endereco.trim().isEmpty) {
      return null;
    }

    try {
      final encodedAddress = Uri.encodeComponent(endereco);
      final url = Uri.parse('$_baseUrl/geocode?q=$encodedAddress&apikey=$_hereApiKey');
      
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout na requisição de geocodificação');
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['items'] != null && data['items'].isNotEmpty) {
          final firstResult = data['items'][0];
          final position = firstResult['position'];
          
          if (position != null && position['lat'] != null && position['lng'] != null) {
            final lat = position['lat'].toDouble();
            final lng = position['lng'].toDouble();
            
            
            return LatLng(lat, lng);
          } else {
          }
        } else {
        }
      } else {
        throw Exception('Erro na API HERE: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }

  Future<String?> obterEnderecoDeCoordenas(LatLng coordenadas) async {
    
    try {
      final url = Uri.parse(
        '$_baseUrl/revgeocode?at=${coordenadas.latitude},${coordenadas.longitude}&apikey=$_hereApiKey'
      );
      
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout na requisição de geocodificação reversa');
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['items'] != null && data['items'].isNotEmpty) {
          final firstResult = data['items'][0];
          final address = firstResult['address'];
          
          if (address != null && address['label'] != null) {
            final endereco = address['label'].toString();
            return endereco;
          }
        } else {
        }
      } else {
        throw Exception('Erro na API HERE: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> buscarEnderecos(String termoBusca) async {
    
    if (termoBusca.trim().isEmpty) {
      return [];
    }

    try {
      final encodedTerm = Uri.encodeComponent(termoBusca);
      final url = Uri.parse('$_baseUrl/geocode?q=$encodedTerm&apikey=$_hereApiKey&limit=5');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> resultados = [];
        
        if (data['items'] != null) {
          for (final item in data['items']) {
            final position = item['position'];
            final address = item['address'];
            
            if (position != null && address != null) {
              resultados.add({
                'endereco': address['label'] ?? 'Endereço não disponível',
                'latitude': position['lat']?.toDouble(),
                'longitude': position['lng']?.toDouble(),
                'pais': address['countryName'],
                'estado': address['state'],
                'cidade': address['city'],
                'cep': address['postalCode'],
              });
            }
          }
        }
        
        return resultados;
      } else {
        throw Exception('Erro na busca de endereços: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static bool isApiKeyConfigured() {
    return _hereApiKey != 'YOUR_HERE_API_KEY' && _hereApiKey.isNotEmpty;
  }
}