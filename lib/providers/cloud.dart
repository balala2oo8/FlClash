import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/cloud/cloud.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/cloud.g.dart';

/// The signed-in account, restored from preferences and kept across launches.
@Riverpod(keepAlive: true)
class CloudAuth extends _$CloudAuth {
  Future<void>? _restoring;

  @override
  CloudSession? build() {
    _restoring = _restore();
    return null;
  }

  /// Startup auto update waits for the stored session to come back.
  Future<CloudSession?> ensureLoaded() async {
    if (state != null) {
      return state;
    }
    await _restoring;
    return state;
  }

  Future<void> _restore() async {
    final json = await preferences.getCloudSession();
    if (!ref.mounted || state != null || json == null) {
      return;
    }
    var session = CloudSession.fromJson(json);
    // Sessions saved before server selection existed fall back to the cached
    // server list, which is the one they were signed in through.
    if (session != null && session.apiBase.isEmpty) {
      final raw = await preferences.getCloudServersCache();
      final servers = raw == null
          ? const <CloudServer>[]
          : parseCloudServers(raw);
      if (servers.isNotEmpty) {
        session = session.copyWith(
          serverName: session.serverName.isEmpty
              ? servers.first.name
              : session.serverName,
          apiBase: servers.first.apiBase,
        );
      }
    }
    state = session;
  }

  Future<void> save(CloudSession session) async {
    state = session;
    await preferences.saveCloudSession(session.toJson());
  }

  Future<void> clear() async {
    state = null;
    await preferences.clearCloudSession();
  }
}

/// The server list the login form offers. The cached copy is ready before the
/// form asks for a refresh, so a failed refresh still leaves it usable.
@Riverpod(keepAlive: true)
class CloudServers extends _$CloudServers {
  @override
  Future<List<CloudServer>> build() async {
    final raw = await preferences.getCloudServersCache();
    return raw == null ? const [] : parseCloudServers(raw);
  }

  Future<void> refresh() async {
    try {
      final servers = await fetchCloudServers();
      if (servers.isEmpty) {
        throw const CloudApiException('The server list is empty');
      }
      await preferences.saveCloudServersCache(
        jsonEncode([for (final server in servers) server.toJson()]),
      );
      state = AsyncData(servers);
    } catch (error, stackTrace) {
      if (state.value?.isNotEmpty != true) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }
}

/// The synced profile is read-only in the UI; membership is account-bound and
/// never stored on the profile itself.
@riverpod
bool isCloudProfile(Ref ref, int profileId) {
  return ref.watch(cloudAuthProvider)?.profileId == profileId;
}

@riverpod
Future<CloudAccount?> cloudAccount(Ref ref) async {
  final session = ref.watch(cloudAuthProvider);
  if (session == null || session.authExpired) {
    return null;
  }
  try {
    return await CloudClient(session.apiBase).fetchAccount(session.authData);
  } on CloudAuthException {
    await ref
        .read(cloudAuthProvider.notifier)
        .save(session.copyWith(authExpired: true));
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class CloudAction extends _$CloudAction {
  @override
  void build() {}

  Future<void> login(CloudServer server, String email, String password) async {
    final result = await CloudClient(server.apiBase).login(email, password);
    await preferences.saveCloudEmail(email);
    final session = CloudSession(
      email: email,
      authData: result.authData,
      token: result.token,
      serverName: server.name,
      apiBase: server.apiBase,
    );
    // The account is saved only once its config landed, so a failed first
    // sync leaves the login form open with the error in view.
    final updated = await _sync(session, refreshMetadata: true, switchTo: true);
    await ref.read(cloudAuthProvider.notifier).save(updated);
  }

  Future<void> syncNow() async {
    final session = ref.read(cloudAuthProvider);
    if (session == null) {
      return;
    }
    final updated = await globalState.loadingRun<CloudSession>(() async {
      try {
        return await _sync(session, refreshMetadata: true, switchTo: true);
      } on CloudAuthException {
        await ref
            .read(cloudAuthProvider.notifier)
            .save(session.copyWith(authExpired: true));
        rethrow;
      }
    }, tag: null);
    if (updated == null) {
      return;
    }
    await ref.read(cloudAuthProvider.notifier).save(updated);
    dialogs.showNotifier(
      currentAppLocalizations.syncSuccess,
      level: MessageLevel.success,
    );
  }

  /// Auto updates download through the cached subscription link, which does
  /// not need the login session, so they keep working after it expires.
  Future<void> autoSyncIfDue() async {
    final session = await ref.read(cloudAuthProvider.notifier).ensureLoaded();
    final profileId = session?.profileId;
    if (session == null || profileId == null) {
      return;
    }
    final profile = await database.profilesDao.get(profileId);
    final lastUpdate = profile?.lastUpdateDate;
    final duration = profile?.autoUpdateDuration ?? defaultUpdateDuration;
    if (lastUpdate != null && !lastUpdate.add(duration).isBeforeNow) {
      return;
    }
    try {
      final updated = await _sync(
        session,
        refreshMetadata: false,
        switchTo: false,
      );
      await ref.read(cloudAuthProvider.notifier).save(updated);
    } catch (error) {
      commonPrint.log(
        'cloud auto sync failed: $error',
        logLevel: LogLevel.warning,
      );
    }
  }

  /// [refreshMetadata] asks the panel for the plan and traffic, which needs the
  /// login session. The subscription link itself is built from the login token
  /// and the chosen server, so it never depends on that request.
  Future<CloudSession> _sync(
    CloudSession session, {
    required bool refreshMetadata,
    required bool switchTo,
  }) async {
    final client = CloudClient(session.apiBase);
    var current = session;
    CloudSubscription? subscription;
    var authExpired = session.authExpired;

    final subscribeUrl =
        subscribeUrlOf(session.apiBase, session.token) ?? session.subscribeUrl;

    if (refreshMetadata) {
      try {
        subscription = await client.fetchSubscription(session.authData);
        authExpired = false;
      } on CloudAuthException {
        authExpired = true;
        if (subscribeUrl.isEmpty) {
          rethrow;
        }
      }
    }

    if (subscribeUrl.isEmpty) {
      throw const CloudApiException('Missing subscription url');
    }
    current = current.copyWith(
      subscribeUrl: subscribeUrl,
      authExpired: authExpired,
    );
    final content = await client.fetchContent(subscribeUrl);
    final label = (subscription?.planName ?? current.planName ?? '')
        .takeFirstValid([session.email]);
    final bytes = content.yaml ?? await _linksToConfig(content.links);
    final profileId = session.profileId;
    final latest = profileId == null
        ? null
        : await database.profilesDao.get(profileId);
    final saved = await (latest ?? Profile.normal(label: label))
        .copyWith(label: label)
        .saveFile(
          bytes,
          validate: (path, key) =>
              ref.read(coreHandlerProvider).validateProfile(path, key),
        );
    final info = subscription;
    final updated = saved.copyWith(
      subscriptionInfo: info == null
          ? latest?.subscriptionInfo
          : SubscriptionInfo(
              upload: info.upload,
              download: info.download,
              total: info.total,
              expire: info.expire,
            ),
    );
    ref.read(profilesProvider.notifier).put(updated);
    if (ref.read(currentProfileIdProvider) == updated.id) {
      ref
          .read(setupActionProvider.notifier)
          .applyProfileDebounce(silence: true);
    } else if (switchTo) {
      // A manual sync makes the account's subscription the current one.
      ref.read(currentProfileIdProvider.notifier).value = updated.id;
    }
    return current.copyWith(profileId: updated.id, planName: label);
  }

  /// This panel hands some clients a share-link list instead of a config. It
  /// becomes the same proxies a share-link import would produce, plus one
  /// selectable group, so the proxies page has something to offer.
  Future<Uint8List> _linksToConfig(List<String> links) async {
    if (links.isEmpty) {
      throw const CloudApiException('Subscription returned no nodes');
    }
    final decoded = await ref.read(coreHandlerProvider).decodeShareLinks(links);
    final taken = {...reservedCustomProxyNames};
    final proxies = <Map<String, dynamic>>[];
    for (final definitions in decoded) {
      for (final definition in definitions) {
        final name = freeProxyName(linkProxyName(definition), taken);
        proxies.add({...definition, 'name': name});
      }
    }
    if (proxies.isEmpty) {
      throw const CloudApiException('Subscription returned no nodes');
    }
    final names = [
      for (final proxy in proxies)
        if (proxy['name'] case final String name) name,
    ];
    final yaml = await encodeYamlTask({
      'proxies': proxies,
      'proxy-groups': [
        {'name': 'Proxy', 'type': 'select', 'proxies': names},
      ],
      'rules': ['MATCH,Proxy'],
    });
    return utf8.encode(yaml);
  }

  Future<void> logout() async {
    final session = ref.read(cloudAuthProvider);
    final email = session?.email;
    if (email != null && email.isNotEmpty) {
      await preferences.saveCloudEmail(email);
    }
    final profileId = session?.profileId;
    if (profileId != null) {
      await ref.read(profilesActionProvider.notifier).deleteProfile(profileId);
    }
    await ref.read(cloudAuthProvider.notifier).clear();
    ref.invalidate(cloudAccountProvider);
  }
}
