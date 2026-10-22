/// The account a cloud subscription belongs to, kept across launches.
class CloudSession {
  final String email;
  final String authData;
  final String token;
  final String serverName;
  final String apiBase;
  final String subscribeUrl;
  final bool authExpired;
  final int? profileId;
  final String? planName;

  const CloudSession({
    required this.email,
    required this.authData,
    required this.token,
    this.serverName = '',
    this.apiBase = '',
    this.subscribeUrl = '',
    this.authExpired = false,
    this.profileId,
    this.planName,
  });

  CloudSession copyWith({
    String? serverName,
    String? apiBase,
    String? subscribeUrl,
    bool? authExpired,
    int? profileId,
    String? planName,
  }) {
    return CloudSession(
      email: email,
      authData: authData,
      token: token,
      serverName: serverName ?? this.serverName,
      apiBase: apiBase ?? this.apiBase,
      subscribeUrl: subscribeUrl ?? this.subscribeUrl,
      authExpired: authExpired ?? this.authExpired,
      profileId: profileId ?? this.profileId,
      planName: planName ?? this.planName,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'authData': authData,
      'token': token,
      'serverName': serverName,
      'apiBase': apiBase,
      'subscribeUrl': subscribeUrl,
      'authExpired': authExpired,
      'profileId': profileId,
      'planName': planName,
    };
  }

  static CloudSession? fromJson(Map<String, Object?> json) {
    final email = json['email'];
    final authData = json['authData'];
    final token = json['token'];
    if (email is! String || authData is! String || token is! String) {
      return null;
    }
    if (email.isEmpty || authData.isEmpty || token.isEmpty) {
      return null;
    }
    final serverName = json['serverName'];
    final apiBase = json['apiBase'];
    final subscribeUrl = json['subscribeUrl'];
    final profileId = json['profileId'];
    final planName = json['planName'];
    return CloudSession(
      email: email,
      authData: authData,
      token: token,
      serverName: serverName is String ? serverName : '',
      apiBase: apiBase is String ? apiBase : '',
      subscribeUrl: subscribeUrl is String ? subscribeUrl : '',
      authExpired: json['authExpired'] == true,
      profileId: profileId is int ? profileId : null,
      planName: planName is String && planName.isNotEmpty ? planName : null,
    );
  }
}

class CloudLoginResult {
  final String token;
  final String authData;

  const CloudLoginResult({required this.token, required this.authData});
}

class CloudAccount {
  final String email;
  final int expiredAt;
  final int transferEnable;

  const CloudAccount({
    required this.email,
    this.expiredAt = 0,
    this.transferEnable = 0,
  });
}

class CloudSubscription {
  final String? planName;
  final int upload;
  final int download;
  final int total;
  final int expire;

  const CloudSubscription({
    this.planName,
    this.upload = 0,
    this.download = 0,
    this.total = 0,
    this.expire = 0,
  });
}
