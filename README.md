# GPS Telemetry App

Uma aplicação Flutter para monitoramento de telemetria GPS em tempo real, desenvolvida com arquitetura MVVM usando flutter_modular.

## Funcionalidades

- 📍 Monitoramento de localização GPS em tempo real
- 📊 Coleta de dados de sensores (acelerômetro, giroscópio, magnetômetro)
- 🗺️ Visualização de rotas no Google Maps
- 💾 Armazenamento local com SQLite
- 📱 Interface responsiva e moderna

## Configuração

### 1. Dependências

Execute o comando para instalar as dependências:

```bash
fvm flutter pub get
```

### 2. Google Maps API Key

Para usar o Google Maps, você precisa configurar uma API Key:

1. Acesse o [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto ou selecione um existente
3. Ative a API do Google Maps para Android e iOS
4. Crie uma API Key

#### Android
Substitua `YOUR_GOOGLE_MAPS_API_KEY_HERE` pela sua API Key no arquivo:
```
android/app/src/main/AndroidManifest.xml
```

#### iOS
Substitua `YOUR_GOOGLE_MAPS_API_KEY_HERE` pela sua API Key no arquivo:
```
ios/Runner/AppDelegate.swift
```

### 3. Permissões

As permissões necessárias já estão configuradas:

#### Android (AndroidManifest.xml)
- Localização (fine, coarse, background)
- Internet
- Wake Lock
- Armazenamento

#### iOS (Info.plist)
- Localização (when in use, always)
- Sensores de movimento

## Executando a Aplicação

```bash
# Para executar no dispositivo/emulador
fvm flutter run

# Para executar no Chrome (web)
fvm flutter run -d chrome
```

## Arquitetura

A aplicação utiliza:
- **MVVM**: Separação clara entre View, ViewModel e Model
- **flutter_modular**: Injeção de dependência e roteamento
- **SQLite**: Banco de dados local para persistência
- **Google Maps**: Visualização de mapas e rotas
- **Geolocator**: Serviços de localização
- **Sensors Plus**: Acesso aos sensores do dispositivo

## Estrutura do Projeto

```
lib/
├── app/
│   ├── modules/
│   │   ├── home/
│   │   ├── telemetry/
│   │   └── map/
│   └── shared/
│       ├── models/
│       └── services/
└── main.dart
```

## Desenvolvimento

Para contribuir com o projeto:

1. Clone o repositório
2. Configure a API Key do Google Maps
3. Execute `fvm flutter pub get`
4. Execute `fvm flutter run`

## Licença

Este projeto está sob a licença MIT.
