Future<String> compareFacesBase64Web(String docBase64, String selBase64) async {
  throw UnsupportedError('Only supported on Web');
}

Future<String> evaluateLivenessFrameWeb(String base64Image) async {
  throw UnsupportedError('Only supported on Web');
}
Future<String> checkLivenessBase64Web(String selBase64) async => throw UnsupportedError('web only');
Future<String> extractTextFromBase64Web(String base64Image) async => throw UnsupportedError('web only');
