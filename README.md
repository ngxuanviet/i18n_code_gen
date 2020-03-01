# i18n_code_gen!

Tự động tạo dart code từ file json ngôn ngữ xử lý vấn đề đa ngôn ngữ cho flutter

#### Tính năng có thể phát triển tiếp:
- Hỗ trợ vùng quốc gia
- Cảnh báo thiếu phiên bản dịch hoặc thiếu string tại ngôn ngữ default

## Tích hợp:
Thêm cấu hình trong file ***pubspec.yaml***:
```
dependencies:  
  flutter_localizations:  
    sdk: flutter  
  flutter_cupertino_localizations: ^1.0.1
```
```
dev_dependencies:  
  build_runner: ^1.7.3  
  i18n_code_gen:
    git: https://github.com/ngxuanviet/i18n_code_gen.git
```
Tạo file ***build.yaml*** trong thư mục gốc của project:
```
targets:  
  #sửa your_project_package_name 
  #đúng theo trường name trong pubspec.yaml  
  test_i18n_code_gen:test_i18n_code_gen:  
    builders:  
      i18n_code_gen|i18nBuilder:  
        generate_for:  
          - lib/langs/*
```
Chạy lệnh packages get:  ```flutter pub get```

## Sử dụng
#### Tạo file ngôn ngữ ***.json*** bên trong ```lib/langs``` với tên file là ***language code*** ví dụ ```en.json```
```
{  
  "isDefault": true,
  "lang": "en",  
  "app_name": "Test App",  
  "content": "Test auto gen language code",
  "two_parameters": "Test format string: $parameter1 and $parameter2"
}
```
"isDefault": true nếu là ngôn ngữ mặc định (yêu cầu phải có 1 ngôn ngữ là mặc định, các file json khác không cần định nghĩa trường này)

#### Chạy lệnh  ```flutter packages pub run build_runner build```
Sau đó các file .dart sẽ được tạo ra bên trong ***lib/langs***
#### Thêm vào main.dart:
Thêm các param sau cho MaterialApp: ***localizationsDelegates, supportedLocales, localeResolutionCallback***
```
class MyApp extends StatelessWidget {  
  // This widget is the root of your application.  
  @override  
  Widget build(BuildContext context) {  
    return MaterialApp(  
      localizationsDelegates: [  
        Strings.delegate,  
        GlobalMaterialLocalizations.delegate,  
        GlobalWidgetsLocalizations.delegate,  
      ],  
      supportedLocales: Strings.delegate.supportedLocales,  
      localeResolutionCallback: Strings.localeResolutionCallback,  
      ...
```
## Sử dụng trong code:
```
Text(Strings.of(context).content) //text: 'Test auto gen language code'
```

## Sử dụng text có params (format):
json ```"two_parameters": "Test format string: $parameter1 and $parameter2"```
```
Text(Strings.of(context).two_parameters('Tom', 'Jerry')) //text: 'Test format string: Tom and Jerry'
```
