import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/cloud/cloud_models.dart';
import 'package:fl_clash/state.dart';

/// A refused request, carrying the message the panel sent so it can be shown.
class CloudApiException implements Exception {
  final String message;
  final int? statusCode;

  const CloudApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// The login session is no longer accepted by the panel.
class CloudAuthException extends CloudApiException {
  const CloudAuthException(super.message, {super.statusCode});
}

/// A panel answers either with a clash document or with a list of share links.
typedef CloudContent = ({Uint8List? yaml, List<String> links});

class CloudClient {
  final String apiBase;

  const CloudClient(this.apiBase);

  static const _sendTimeout = Duration(seconds: 20);
  static const _receiveTimeout = Duration(seconds: 30);

  void _ensureConfigured() {
    if (apiBase.isEmpty) {
      throw const CloudApiException('Cloud API is not configured');
    }
  }

  String _apiUrl(String path) => '$apiBase$path';

  /// A 4xx still carries the panel's envelope, whose message is more useful
  /// than a bare status code.
  static bool _acceptStatus(int? status) => status != null && status < 500;

  static Options _options({Map<String, Object>? headers}) {
    return Options(
      headers: headers,
      validateStatus: _acceptStatus,
      sendTimeout: _sendTimeout,
      receiveTimeout: _receiveTimeout,
    );
  }

  static Future<Response<T>> _request<T>(
    Future<Response<T>> Function() run,
  ) async {
    try {
      return await run();
    } on DioException catch (error) {
      commonPrint.log(_describe(error), logLevel: LogLevel.warning);
      rethrow;
    }
  }

  static String _describe(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final cause = error.error;
    return 'cloud request failed: ${error.type.name}'
        '${status == null ? '' : ' status=$status'}'
        '${body == null ? '' : ' body=$body'}'
        '${cause == null ? '' : ' cause=$cause'}';
  }

  /// The panel answers with an envelope, and only `success` carries data.
  Map<String, Object?> _readData(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map) {
      throw _responseError(
        'Unexpected response (${response.statusCode})',
        response,
      );
    }
    final data = body['data'];
    if (body['status'] != 'success' || data is! Map) {
      final message = body['message'];
      throw _responseError(
        message is String && message.isNotEmpty ? message : 'Request failed',
        response,
      );
    }
    return Map<String, Object?>.from(data);
  }

  /// A 401 or 403 means the login session itself is gone, which callers can
  /// tell apart from a rejected subscription token.
  static CloudApiException _responseError(
    String message,
    Response<dynamic> response,
  ) {
    final status = response.statusCode;
    return status == 401 || status == 403
        ? CloudAuthException(message, statusCode: status)
        : CloudApiException(message, statusCode: status);
  }

  Future<CloudLoginResult> login(String email, String password) async {
    _ensureConfigured();
    final response = await _request(
      () => request.dio.post<dynamic>(
        _apiUrl('/u/passport/auth/login'),
        data: {'email': email, 'password': password},
        options: _options(),
      ),
    );
    final data = _readData(response);
    final token = data['token'];
    final authData = data['auth_data'];
    if (token is! String ||
        token.isEmpty ||
        authData is! String ||
        authData.isEmpty) {
      throw const CloudApiException('Invalid login response');
    }
    return CloudLoginResult(token: token, authData: authData);
  }

  Future<CloudAccount> fetchAccount(String authData) async {
    _ensureConfigured();
    final response = await _request(
      () => request.dio.get<dynamic>(
        _apiUrl('/u/user/info'),
        options: _options(headers: {'Authorization': authData}),
      ),
    );
    final data = _readData(response);
    return CloudAccount(
      email: data['email'] is String ? data['email'] as String : '',
      expiredAt: _asInt(data['expired_at']),
      transferEnable: _asInt(data['transfer_enable']),
    );
  }

  Future<CloudSubscription> fetchSubscription(String authData) async {
    _ensureConfigured();
    final response = await _request(
      () => request.dio.get<dynamic>(
        _apiUrl('/u/user/getSubscribe'),
        options: _options(headers: {'Authorization': authData}),
      ),
    );
    final data = _readData(response);
    final plan = data['plan'];
    return CloudSubscription(
      planName: plan is Map && plan['name'] is String
          ? plan['name'] as String
          : null,
      upload: _asInt(data['u']),
      download: _asInt(data['d']),
      total: _asInt(data['transfer_enable']),
      expire: _asInt(data['expired_at']),
    );
  }

  /// Fetches the config behind [subscribeUrl]. It sends the same user agent the
  /// app's own profile download sends, so the panel answers with the full
  /// clash document and its groups; other agents get share links or a stub.
  Future<CloudContent> fetchContent(String subscribeUrl) async {
    final response = await _request(
      () => request.dio.get<List<int>>(
        subscribeUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'User-Agent': globalState.ua},
          validateStatus: _acceptStatus,
          sendTimeout: _sendTimeout,
          receiveTimeout: const Duration(seconds: 60),
        ),
      ),
    );
    return _decodeContent(
      Uint8List.fromList(response.data ?? const <int>[]),
      statusCode: response.statusCode,
    );
  }

  static int _asInt(Object? value) {
    return value is num ? value.toInt() : 0;
  }
}

CloudContent _decodeContent(Uint8List bytes, {int? statusCode}) {
  final inflated = decompressUnlabeled(bytes);
  final text = utf8.decode(inflated, allowMalformed: true);
  final direct = _contentOf(text, inflated);
  if (direct != null) {
    return direct;
  }
  final directError = _errorMessageOf(text);
  if (directError != null) {
    throw CloudApiException(directError, statusCode: statusCode);
  }
  try {
    final decoded = base64.decode(text.replaceAll(RegExp(r'\s'), ''));
    final decodedBytes = Uint8List.fromList(decoded);
    final decodedText = utf8.decode(decodedBytes, allowMalformed: true);
    final nested = _contentOf(decodedText, decodedBytes);
    if (nested != null) {
      return nested;
    }
    final nestedError = _errorMessageOf(decodedText);
    if (nestedError != null) {
      throw CloudApiException(nestedError, statusCode: statusCode);
    }
  } on FormatException {
    // Not base64.
  }
  throw CloudApiException(
    'Unsupported subscription content',
    statusCode: statusCode,
  );
}

CloudContent? _contentOf(String text, Uint8List bytes) {
  if (text.trimLeft().startsWith('{')) {
    return null;
  }
  if (looksLikeClashConfig(text)) {
    return (yaml: bytes, links: const []);
  }
  final links = _shareLinksOf(text);
  if (links.isNotEmpty) {
    return (yaml: null, links: links);
  }
  return null;
}

List<String> _shareLinksOf(String text) {
  return [
    for (final line in text.split(RegExp(r'\s+')))
      if (line.contains('://')) line,
  ];
}

/// An expired token makes the download endpoint answer with the panel's JSON
/// envelope instead of a config.
String? _errorMessageOf(String text) {
  final trimmed = text.trimLeft();
  if (!trimmed.startsWith('{')) {
    return null;
  }
  try {
    final body = json.decode(trimmed);
    if (body is Map && body['status'] != 'success') {
      final message = body['message'];
      return message is String && message.isNotEmpty
          ? message
          : 'Request failed';
    }
  } on FormatException {
    return null;
  }
  return null;
}

/// Some panels hand a clash client a base64 list instead of the YAML document.
bool looksLikeClashConfig(String text) {
  return text.contains('proxies:') ||
      text.contains('proxy-groups:') ||
      text.contains('mixed-port:') ||
      text.contains('proxy-providers:');
}
