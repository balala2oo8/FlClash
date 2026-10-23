import 'dart:convert';

/// The public list the login form offers, served as static JSON.
const cloudServersUrl = 'https://api.peekaboo.fans/getServers';

class CloudServer {
  final String name;
  final String apiBase;

  const CloudServer({required this.name, required this.apiBase});

  Map<String, Object?> toJson() {
    return {'server_name': name, 'api_base': apiBase};
  }

  static CloudServer? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final name = value['server_name'];
    final apiBase = value['api_base'];
    if (name is! String || apiBase is! String) {
      return null;
    }
    final label = name.trim();
    final base = apiBase.trim().replaceAll(RegExp(r'/+$'), '');
    if (label.isEmpty || base.isEmpty) {
      return null;
    }
    return CloudServer(name: label, apiBase: base);
  }
}

/// Reads the endpoint body or the cached copy of it.
List<CloudServer> parseCloudServers(Object? value) {
  var data = value;
  if (data is String) {
    try {
      data = jsonDecode(data);
    } catch (_) {
      return const [];
    }
  }
  if (data is! List) {
    return const [];
  }
  final servers = <CloudServer>[];
  final seen = <String>{};
  for (final item in data) {
    final server = CloudServer.fromJson(item);
    if (server == null || !seen.add(server.apiBase)) {
      continue;
    }
    servers.add(server);
  }
  return servers;
}

/// The subscription link is the server's API base plus `/sub/<login token>`,
/// so it does not depend on `getSubscribe` answering.
String? subscribeUrlOf(String apiBase, String token) {
  final base = apiBase.replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty || token.isEmpty) {
    return null;
  }
  return '$base/sub/$token';
}
