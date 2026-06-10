# AppSer

Aplicativo Flutter do protocolo MBRP assincrono. O projeto utiliza Firebase
Authentication, Cloud Firestore e Firebase Storage.

## Pre-requisitos

Antes de iniciar, instale:

- [Flutter](https://docs.flutter.dev/get-started/install) 3.24 ou superior
- Dart 3.5 ou superior (incluido no Flutter)
- Git
- Um dispositivo, emulador Android ou navegador compativel
- Acesso ao projeto Firebase `appserof`

Para desenvolvimento Android, instale tambem o Android Studio, o Android SDK e
um JDK compativel com a versao atual do Flutter. O aplicativo requer Android 6.0
(API 23) ou superior.

Confirme se o ambiente esta pronto:

```bash
flutter doctor
flutter devices
```

Resolva os problemas indicados pelo `flutter doctor` antes de continuar.

## Instalacao

Na raiz do repositorio, entre na pasta do aplicativo e instale as dependencias:

```bash
cd appser
flutter pub get
```

## Configuracao do Firebase

O aplicativo nao inicia sem a configuracao do Firebase. Os arquivos abaixo
contem configuracoes locais e nao sao enviados ao Git:

- `appser/lib/firebase_options.dart`
- `appser/android/app/google-services.json`
- `appser/ios/Runner/GoogleService-Info.plist`

Caso esses arquivos nao estejam presentes, instale e autentique as ferramentas
do Firebase:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=appserof
```

Execute o ultimo comando dentro da pasta `appser`. Durante a configuracao,
selecione as plataformas que pretende executar. E necessario possuir permissao
de acesso ao projeto Firebase `appserof`.

## Executando

Todos os comandos desta secao devem ser executados dentro da pasta `appser`.

Liste os dispositivos disponiveis:

```bash
flutter devices
```

Execute no dispositivo desejado:

```bash
flutter run -d <id-do-dispositivo>
```

Exemplos:

```bash
# Microsoft Edge
flutter run -d edge

# Windows
flutter run -d windows
```

Para Android, copie o ID exibido por `flutter devices` e use-o no lugar de
`<id-do-dispositivo>`. Se houver apenas um dispositivo conectado, basta executar
`flutter run`. Durante a execucao, pressione `r` para aplicar hot reload e `R`
para reiniciar o aplicativo.

## Verificacoes

Execute a analise estatica e os testes antes de enviar alteracoes:

```bash
flutter analyze
flutter test
```

## Gerando builds

```bash
# APK Android para testes
flutter build apk --debug

# Aplicacao web
flutter build web

# Aplicacao Windows
flutter build windows
```

O build Android de release depende do keystore e da configuracao de assinatura
do responsavel pelo projeto. Para desenvolvimento local, utilize o build debug.

## Problemas comuns

### Firebase nao inicializa

Execute novamente:

```bash
flutterfire configure --project=appserof
flutter clean
flutter pub get
flutter run
```

### Nenhum dispositivo encontrado

Confira os dispositivos e o diagnostico do Flutter:

```bash
flutter devices
flutter doctor -v
```

Para Android, verifique se o emulador esta iniciado ou se a depuracao USB esta
ativada no aparelho.

### Dependencias ou build desatualizados

Limpe os artefatos gerados e reinstale as dependencias:

```bash
flutter clean
flutter pub get
flutter run
```
