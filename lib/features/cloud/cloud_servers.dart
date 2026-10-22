class CloudServer {
  final String name;
  final String apiBase;

  const CloudServer({required this.name, required this.apiBase});
}

/// The subscription link is the server's API base plus `/sub/<login token>`,
/// so it does not depend on `getSubscribe` answering.
String? subscribeUrlOf(CloudServer server, String token) {
  final base = server.apiBase.replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty || token.isEmpty) {
    return null;
  }
  return '$base/sub/$token';
}

/// The servers the login form offers. An entry without an address is still
/// listed, but signing in through it reports that the address is missing.
const cloudServers = <CloudServer>[
  CloudServer(name: '正式服', apiBase: 'https://net.peekaboo.fans'),
  CloudServer(name: '测试服', apiBase: 'https://ss.peekaboo.fans'),
];
