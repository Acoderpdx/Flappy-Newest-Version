// This file provides dummy implementations of dart:io classes for web platform

// Environment access for web
Map<String, String> getPlatformEnvironment() {
  return {};
}

// Platform checks for web
bool get isIOS => false;
bool get isAndroid => false;

// Stub Platform class
class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isWeb => true;
  
  static Map<String, String> get environment => {};
}

// Add other common dart:io classes that might be used in your app
class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<File> writeAsString(String data) async => this;
}

class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Directory get parent => Directory('');
}

// Add HttpClient stub if your app uses it
class HttpClient {
  Future<HttpClientRequest> getUrl(Uri url) async => HttpClientRequest();
}

class HttpClientRequest {
  Future<HttpClientResponse> close() async => HttpClientResponse();
}

class HttpClientResponse {
  Future<String> transform(dynamic transformer) async => '';
  Stream<List<int>> get handleError => Stream.empty();
}
