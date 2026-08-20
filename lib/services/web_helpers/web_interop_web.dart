import 'dart:js_interop';

@JS('compareFacesBase64')
external JSPromise _compareFacesBase64(JSString docBase64, JSString selBase64);

@JS('evaluateLivenessFrameBase64')
external JSPromise _evaluateLivenessFrameBase64(JSString base64Image);

@JS('checkLivenessBase64')
external JSPromise _checkLivenessBase64(JSString selBase64);

@JS('extractTextFromBase64')
external JSPromise _extractTextFromBase64(JSString base64Image);

Future<String> compareFacesBase64Web(String docBase64, String selBase64) async {
  final result = await _compareFacesBase64(docBase64.toJS, selBase64.toJS).toDart;
  return (result as JSString).toDart;
}

Future<String> evaluateLivenessFrameWeb(String base64Image) async {
  final result = await _evaluateLivenessFrameBase64(base64Image.toJS).toDart;
  return (result as JSString).toDart;
}

Future<String> checkLivenessBase64Web(String selBase64) async {
  final result = await _checkLivenessBase64(selBase64.toJS).toDart;
  return (result as JSString).toDart;
}

Future<String> extractTextFromBase64Web(String base64Image) async {
  final result = await _extractTextFromBase64(base64Image.toJS).toDart;
  return (result as JSString).toDart;
}
