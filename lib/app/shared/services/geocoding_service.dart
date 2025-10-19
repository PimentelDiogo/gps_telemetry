import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:developer' as dev;

class GeocodingService {
  // Chave da API HERE - deve ser configurada nas variáveis de ambiente
  static const String _hereApiKey = 'YOUR_HERE_API_KEY'; // Substitua pela sua chave
  static const String _baseUrl = 'https://geocode.search.hereapi.com/v1';

  /// Obtém coordenadas LatLng a partir de um endereço usando HERE Geocoding API
  /// 
  /// Exemplo de uso baseado no código fornecido pelo usuário:
  /// ```dart
  /// final geocoding = GeocodingService();
  /// final coordinates = await geocoding.obterGeoLocalizacao('Rua das Flores, 123, São Paulo');
  /// ```
  Future<LatLng?> obterGeoLocalizacao(String endereco) async {
    dev.log("🟡 GEOCODING_SERVICE: Iniciando geocodificação para endereço: '$endereco' 🟡");
    
    if (endereco.trim().isEmpty) {
      dev.log("🔴 GEOCODING_SERVICE: Endereço vazio fornecido 🔴");
      return null;
    }

    try {
      // Construir URL da requisição
      final encodedAddress = Uri.encodeComponent(endereco);
      final url = Uri.parse('$_baseUrl/geocode?q=$encodedAddress&apikey=$_hereApiKey');
      
      dev.log("🟡 GEOCODING_SERVICE: Fazendo requisição para: ${url.toString()} 🟡");
      
      // Fazer requisição HTTP
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          dev.log("🔴 GEOCODING_SERVICE: Timeout na requisição 🔴");
          throw Exception('Timeout na requisição de geocodificação');
        },
      );

      dev.log("🟡 GEOCODING_SERVICE: Status da resposta: ${response.statusCode} 🟡");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar se há resultados
        if (data['items'] != null && data['items'].isNotEmpty) {
          final firstResult = data['items'][0];
          final position = firstResult['position'];
          
          if (position != null && position['lat'] != null && position['lng'] != null) {
            final lat = position['lat'].toDouble();
            final lng = position['lng'].toDouble();
            
            dev.log("🟢 GEOCODING_SERVICE: Geocodificação bem-sucedida - Lat: $lat, Lng: $lng 🟢");
            
            return LatLng(lat, lng);
          } else {
            dev.log("🔴 GEOCODING_SERVICE: Posição não encontrada na resposta 🔴");
          }
        } else {
          dev.log("🔴 GEOCODING_SERVICE: Nenhum resultado encontrado para o endereço 🔴");
        }
      } else {
        dev.log("🔴 GEOCODING_SERVICE: Erro na API HERE - Status: ${response.statusCode}, Body: ${response.body} 🔴");
        throw Exception('Erro na API HERE: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("🔴 GEOCODING_SERVICE: Erro durante geocodificação: $e 🔴");
      rethrow;
    }

    return null;
  }

  /// Obtém endereço a partir de coordenadas (geocodificação reversa)
  Future<String?> obterEnderecoDeCoordenas(LatLng coordenadas) async {
    dev.log("🟡 GEOCODING_SERVICE: Iniciando geocodificação reversa para: ${coordenadas.latitude}, ${coordenadas.longitude} 🟡");
    
    try {
      // Construir URL da requisição para geocodificação reversa
      final url = Uri.parse(
        '$_baseUrl/revgeocode?at=${coordenadas.latitude},${coordenadas.longitude}&apikey=$_hereApiKey'
      );
      
      dev.log("🟡 GEOCODING_SERVICE: Fazendo requisição reversa para: ${url.toString()} 🟡");
      
      // Fazer requisição HTTP
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          dev.log("🔴 GEOCODING_SERVICE: Timeout na requisição reversa 🔴");
          throw Exception('Timeout na requisição de geocodificação reversa');
        },
      );

      dev.log("🟡 GEOCODING_SERVICE: Status da resposta reversa: ${response.statusCode} 🟡");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar se há resultados
        if (data['items'] != null && data['items'].isNotEmpty) {
          final firstResult = data['items'][0];
          final address = firstResult['address'];
          
          if (address != null && address['label'] != null) {
            final endereco = address['label'].toString();
            dev.log("🟢 GEOCODING_SERVICE: Geocodificação reversa bem-sucedida: $endereco 🟢");
            return endereco;
          }
        } else {
          dev.log("🔴 GEOCODING_SERVICE: Nenhum endereço encontrado para as coordenadas 🔴");
        }
      } else {
        dev.log("🔴 GEOCODING_SERVICE: Erro na API HERE (reversa) - Status: ${response.statusCode} 🔴");
        throw Exception('Erro na API HERE: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("🔴 GEOCODING_SERVICE: Erro durante geocodificação reversa: $e 🔴");
      rethrow;
    }

    return null;
  }

  /// Busca múltiplos endereços que correspondem ao termo de busca
  Future<List<Map<String, dynamic>>> buscarEnderecos(String termoBusca) async {
    dev.log("🟡 GEOCODING_SERVICE: Buscando endereços para: '$termoBusca' 🟡");
    
    if (termoBusca.trim().isEmpty) {
      dev.log("🔴 GEOCODING_SERVICE: Termo de busca vazio 🔴");
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
        
        dev.log("🟢 GEOCODING_SERVICE: Encontrados ${resultados.length} endereços 🟢");
        return resultados;
      } else {
        dev.log("🔴 GEOCODING_SERVICE: Erro na busca - Status: ${response.statusCode} 🔴");
        throw Exception('Erro na busca de endereços: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("🔴 GEOCODING_SERVICE: Erro durante busca de endereços: $e 🔴");
      rethrow;
    }
  }

  /// Valida se a chave da API HERE está configurada
  static bool isApiKeyConfigured() {
    return _hereApiKey != 'YOUR_HERE_API_KEY' && _hereApiKey.isNotEmpty;
  }
}