import 'dart:io';

class ApiConfig {
  
  static const String _prodUrl = 'https://claudioparedes.site/geriatrico/api';

  
  static const String _devAndroid = 'http://10.0.2.2:8000/api'; 
  static const String _devDesktop = 'http://localhost:8000/api'; 
  static const String _devIos = 'http://127.0.0.1:8000/api';    

 
  static const bool isProduction = true;

  static String get baseUrl {
    if (isProduction) return _prodUrl;

    if (Platform.isAndroid) return _devAndroid;
    if (Platform.isIOS) return _devIos;

    
    return _devDesktop;
  }
}