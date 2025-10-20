# GPS Telemetry - Monitoramento de Telemetria GPS em Tempo Real

Uma aplicação Flutter para monitoramento de telemetria GPS em tempo real, desenvolvida com arquitetura MVVM modular usando flutter_modular.

## 📱 Sobre o Projeto

Esta aplicação permite o rastreamento e monitoramento de dados de telemetria GPS em tempo real, incluindo:

- **Rastreamento GPS** em tempo real com alta precisão
- **Localização automática** - mapa centraliza automaticamente na posição atual
- **Sensores de movimento** (acelerômetro, giroscópio)
- **Bússola digital** para orientação
- **Mapas interativos** com Google Maps otimizado
- **Histórico de sessões** com visualização detalhada
- **Exportação de dados** em formato CSV
- **Armazenamento local** com SQLite
- **Interface moderna** com Material Design 3

## 🏗️ Arquitetura

O projeto utiliza **arquitetura MVVM (Model-View-ViewModel) modular** com:

### 🔧 Padrões Arquiteturais
- **flutter_modular** para injeção de dependência e roteamento modular
- **Provider** para gerenciamento de estado reativo
- **Repository Pattern** para abstração de dados
- **Service Layer** para lógica de negócio
- **Separação clara** entre camadas de apresentação, lógica de negócio e dados

### 📦 Estrutura Modular
```
app/
├── modules/                    # Módulos da aplicação
│   ├── telemetry/             # Módulo de telemetria em tempo real
│   ├── history/               # Módulo de histórico de sessões
│   └── session_details/       # Módulo de detalhes da sessão
├── shared/                    # Recursos compartilhados
│   ├── services/              # Serviços (GPS, sensores, geocoding)
│   ├── repositories/          # Repositórios de dados
│   ├── models/                # Modelos de dados
│   ├── database/              # Serviços de banco de dados
│   └── widgets/               # Widgets reutilizáveis
└── app_module.dart            # Configuração principal de DI
```

### 🎯 Benefícios da Arquitetura
- **Modularidade**: Cada funcionalidade em módulo independente
- **Testabilidade**: Injeção de dependência facilita testes unitários
- **Manutenibilidade**: Separação clara de responsabilidades
- **Escalabilidade**: Fácil adição de novos módulos
- **Reutilização**: Widgets e serviços compartilhados

## 🚀 Tecnologias Utilizadas

### Framework
- **Flutter**: 3.35.6
- **Dart**: 3.9.2

### Principais Dependências

| Dependência | Versão | Descrição |
|-------------|--------|-----------|
| `flutter_modular` | ^6.3.4 | Arquitetura MVVM modular e injeção de dependência |
| `provider` | ^6.1.2 | Gerenciamento de estado reativo |
| `geolocator` | ^13.0.1 | Localização GPS e velocidade |
| `sensors_plus` | ^6.0.1 | Sensores de aceleração e giroscópio |
| `flutter_compass` | ^0.8.0 | Bússola digital |
| `google_maps_flutter` | ^2.9.0 | Mapas interativos |
| `sqflite` | ^2.4.1 | Banco de dados local SQLite |
| `permission_handler` | ^11.3.1 | Gerenciamento de permissões |
| `share_plus` | ^10.1.2 | Compartilhamento de dados |
| `csv` | ^6.0.0 | Exportação em CSV |
| `geocoding` | ^3.0.0 | Conversão de coordenadas para endereços |

## 📋 Pré-requisitos

### Sistema
- **Flutter SDK**: 3.35.6 ou superior
- **Dart SDK**: 3.9.2 ou superior
- **Android Studio** ou **VS Code** com extensões Flutter
- **Git** para controle de versão

### Ferramentas Recomendadas
- **FVM (Flutter Version Management)** para gerenciar versões do Flutter
- **Android SDK** (API level 21+) para desenvolvimento Android
- **Xcode** (para desenvolvimento iOS - apenas macOS)

### APIs Necessárias
- **Google Maps API Key** (obrigatório)
- **Google Services** configurado (Firebase - opcional)

## 🛠️ Configuração do Ambiente

### 1. Instalar Flutter
```bash
# Usando FVM (recomendado)
fvm install 3.35.6
fvm use 3.35.6

# Ou instalar diretamente
# Baixe o Flutter SDK em: https://flutter.dev/docs/get-started/install
```

### 2. Verificar Instalação
```bash
fvm flutter doctor
```

### 3. Configurar Google Maps API

#### Android
1. Obtenha uma API Key no [Google Cloud Console](https://console.cloud.google.com/)
2. Edite `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <meta-data android:name="com.google.android.geo.API_KEY"
               android:value="SUA_API_KEY_AQUI"/>
</application>
```

#### iOS
1. Edite `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("SUA_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 🚀 Como Executar

### 1. Clonar o Repositório
```bash
git clone https://github.com/PimentelDiogo/gps_telemetry.git
cd gps_telemetry/gps_telemetry
```

### 2. Instalar Dependências
```bash
fvm flutter pub get
```

### 3. Configurar Permissões

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastreamento GPS.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para rastreamento GPS.</string>
```

### 4. Executar a Aplicação
```bash
# Debug
fvm flutter run

# Release
fvm flutter run --release

# Dispositivo específico
fvm flutter devices
fvm flutter run -d <device_id>
```

## 📱 Funcionalidades

### 🎯 Novas Funcionalidades

#### 📍 Localização Automática
- **Centralização automática** do mapa na posição atual do usuário
- **Indicador de carregamento** durante obtenção da localização
- **Fallback inteligente** para posição padrão em caso de erro
- **Animação suave** da câmera para a localização atual

#### 🗺️ Mapas Otimizados
- **Google Maps otimizado** com melhor performance
- **Controles de zoom** personalizados (10x - 20x)
- **Tipo de mapa** configurável (normal, satélite, híbrido)
- **Marcadores dinâmicos** para posição atual e trajetória

#### 🎨 Interface Moderna
- **Material Design 3** com tema consistente
- **Cards otimizados** para melhor visualização de dados
- **Indicadores visuais** para status de gravação
- **Transições suaves** entre telas

### 📊 Telemetria em Tempo Real
- **GPS**: Latitude, longitude, altitude, velocidade, precisão
- **Sensores**: Aceleração X/Y/Z, rotação, orientação
- **Bússola**: Direção magnética em tempo real
- **Estatísticas**: Distância percorrida, tempo decorrido, velocidade média/máxima
- **Geocoding**: Conversão automática de coordenadas para endereços

### 🗺️ Visualização de Mapas
- Mapa interativo com Google Maps
- Trajetória em tempo real com polylines
- Marcadores de início/fim de sessão
- Zoom automático baseado na trajetória
- Controles de tipo de mapa

### 📈 Histórico de Sessões
- Lista organizada de todas as sessões gravadas
- Cards informativos com estatísticas resumidas
- Detalhes completos de cada sessão
- Visualização da rota completa no mapa
- Estatísticas consolidadas e métricas de performance

### 💾 Exportação e Compartilhamento
- Exportação completa em formato CSV
- Compartilhamento via apps nativos do sistema
- Dados estruturados com timestamps
- Metadados da sessão incluídos

## 🏗️ Estrutura Detalhada do Projeto

```
lib/
├── app/
│   ├── app_module.dart                    # Módulo principal com DI
│   ├── modules/
│   │   ├── telemetry/                     # 📊 Módulo de Telemetria
│   │   │   ├── telemetry_module.dart      # Configuração do módulo
│   │   │   ├── view/
│   │   │   │   └── telemetry_page.dart    # Tela principal de telemetria
│   │   │   └── viewmodel/
│   │   │       └── telemetry_viewmodel.dart # ViewModel de telemetria
│   │   ├── history/                       # 📚 Módulo de Histórico
│   │   │   ├── history_module.dart        # Configuração do módulo
│   │   │   ├── view/
│   │   │   │   └── history_page.dart      # Tela de histórico
│   │   │   └── viewmodel/
│   │   │       └── history_viewmodel.dart # ViewModel de histórico
│   │   └── session_details/               # 🔍 Módulo de Detalhes
│   │       ├── session_details_module.dart # Configuração do módulo
│   │       ├── view/
│   │       │   └── session_details_page.dart # Tela de detalhes
│   │       ├── viewmodel/
│   │       │   └── session_details_viewmodel.dart # ViewModel de detalhes
│   │       └── widgets/
│   │           └── session_map_widget.dart # Widget de mapa da sessão
│   └── shared/                            # 🔧 Recursos Compartilhados
│       ├── database/
│       │   └── database_service.dart      # Serviço de banco SQLite
│       ├── models/
│       │   ├── telemetry_data.dart        # Modelo de dados de telemetria
│       │   └── telemetry_session.dart     # Modelo de sessão
│       ├── repositories/
│       │   └── telemetry_repository.dart  # Repositório de telemetria
│       ├── services/
│       │   ├── location_service.dart      # Serviço de localização GPS
│       │   ├── sensor_service.dart        # Serviço de sensores
│       │   └── geocoding_service.dart     # Serviço de geocoding
│       ├── utils/                         # Utilitários
│       └── widgets/                       # Widgets reutilizáveis
│           ├── action_card.dart           # Card de ação
│           ├── optimized_google_map.dart  # Mapa otimizado
│           └── session_card.dart          # Card de sessão
├── main.dart                              # Ponto de entrada da aplicação
└── views/                                 # Views auxiliares
```

### 🔄 Fluxo de Dados

```
View (UI) ↔ ViewModel (Estado) ↔ Repository (Dados) ↔ Services (APIs/Sensores)
                                      ↓
                                 Database (SQLite)
```

## 🎨 Screenshots

### 📱 Tela Principal de Telemetria
- Interface moderna com Material Design 3
- Mapa centralizado automaticamente na localização atual
- Indicadores em tempo real de GPS, sensores e bússola
- Controles intuitivos para iniciar/parar gravação

### 📊 Dados em Tempo Real
- Cards organizados com informações de GPS
- Visualização de sensores de movimento
- Bússola digital integrada
- Estatísticas de sessão em tempo real

### 📚 Histórico de Sessões
- Lista organizada de sessões anteriores
- Cards informativos com resumo de cada sessão
- Acesso rápido aos detalhes e visualização no mapa

### 🔍 Detalhes da Sessão
- Visualização completa da rota no mapa
- Estatísticas detalhadas da sessão
- Opções de exportação e compartilhamento

## 🔧 Comandos Úteis

```bash
# Limpar cache
fvm flutter clean && fvm flutter pub get

# Gerar APK
fvm flutter build apk --release

# Gerar Bundle (Google Play)
fvm flutter build appbundle --release

# Executar testes
fvm flutter test

# Analisar código
fvm flutter analyze

# Formatar código
fvm flutter format .

# Verificar dependências desatualizadas
fvm flutter pub outdated

# Atualizar dependências
fvm flutter pub upgrade
```

## 📱 Compatibilidade

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Testado em**: Android 10+, iOS 14+
- **Resolução**: Suporte a diferentes tamanhos de tela
- **Orientação**: Portrait e landscape

## 🚀 Performance

### Otimizações Implementadas
- **Mapas otimizados** com renderização eficiente
- **Widgets reutilizáveis** para melhor performance
- **Gerenciamento de estado** otimizado com Provider
- **Lazy loading** de dados históricos
- **Cache inteligente** de dados de sessão

### Métricas de Performance
- **Tempo de inicialização**: < 3 segundos
- **Uso de memória**: Otimizado para dispositivos com 2GB+ RAM
- **Consumo de bateria**: Otimizado para uso prolongado
- **Precisão GPS**: ±1-5 metros (dependendo do dispositivo)

## 🔒 Privacidade e Segurança

- **Dados locais**: Todas as informações ficam no dispositivo
- **Sem telemetria**: Nenhum dado é enviado para servidores externos
- **Permissões mínimas**: Apenas localização e armazenamento
- **Código aberto**: Transparência total do funcionamento

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### 📝 Diretrizes de Contribuição
- Siga os padrões de código estabelecidos
- Adicione testes para novas funcionalidades
- Mantenha a documentação atualizada
- Use commits semânticos

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👨‍💻 Autor

**Diogo Pimentel**
- GitHub: [@PimentelDiogo](https://github.com/PimentelDiogo)
- LinkedIn: [Diogo Pimentel](https://linkedin.com/in/diogo-pimentel)

## 🆘 Suporte

Se você encontrar algum problema ou tiver dúvidas:

1. Verifique se todas as dependências estão instaladas
2. Confirme se a API Key do Google Maps está configurada
3. Execute `fvm flutter doctor` para verificar o ambiente
4. Consulte a seção de troubleshooting abaixo
5. Abra uma issue no GitHub com detalhes do problema

### 🔧 Troubleshooting

#### Problema: Mapa não carrega
- Verifique se a API Key está configurada corretamente
- Confirme se a API do Google Maps está habilitada no console

#### Problema: GPS não funciona
- Verifique se as permissões de localização estão concedidas
- Teste em ambiente externo para melhor recepção GPS

#### Problema: App não compila
- Execute `fvm flutter clean && fvm flutter pub get`
- Verifique se a versão do Flutter está correta

---

⭐ Se este projeto foi útil para você, considere dar uma estrela no repositório!

## 🔄 Changelog

### v2.0.0 - Arquitetura Modular
- ✨ Implementação da arquitetura MVVM modular
- 🎯 Localização automática na inicialização
- 🎨 Interface moderna com Material Design 3
- 🗺️ Mapas otimizados com melhor performance
- 📊 Widgets reutilizáveis e otimizados
- 🔧 Serviços de geocoding integrados
- 📱 Suporte aprimorado para diferentes resoluções

### v1.0.0 - Versão Inicial
- 📍 Rastreamento GPS básico
- 🗺️ Integração com Google Maps
- 📊 Sensores de movimento
- 💾 Armazenamento local com SQLite
