import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/cloud/cloud.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

bool get cloudAccountAvailable => cloudServers.isNotEmpty;

void showCloudAccount(BuildContext context) {
  final rootContext = globalState.navigatorKey.currentContext ?? context;
  showExtend(rootContext, builder: (_) => const CloudAccountView());
}

/// The dashboard's entry into the account, labelled so a first launch can
/// find it without knowing the glyph.
class CloudAccountButton extends ConsumerWidget {
  const CloudAccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(cloudAuthProvider);
    final appLocalizations = context.appLocalizations;
    final expired = session?.authExpired == true;
    final colorScheme = context.colorScheme;
    final label = switch (session) {
      null => appLocalizations.notLoggedIn,
      final value when value.authExpired => appLocalizations.loginExpired,
      _ => appLocalizations.loggedIn,
    };
    return TonalButton(
      size: TonalButtonSize.bar,
      glyph: AppGlyphs.account,
      label: label,
      color: expired ? colorScheme.errorContainer : null,
      foregroundColor: expired ? colorScheme.onErrorContainer : null,
      onPressed: () => showCloudAccount(context),
    );
  }
}

class CloudAccountView extends ConsumerWidget {
  const CloudAccountView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cloudServers.isEmpty) {
      return const SizedBox.shrink();
    }
    final session = ref.watch(cloudAuthProvider);
    if (session == null) {
      return const _LoginView();
    }
    return _AccountView(session: session);
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  var _server = cloudServers.first;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreServer());
    unawaited(_restoreEmail());
  }

  Future<void> _restoreEmail() async {
    final email = await preferences.getCloudEmail();
    if (!mounted || email == null || email.isEmpty) {
      return;
    }
    _emailController.text = email;
  }

  Future<void> _restoreServer() async {
    final name = await preferences.getCloudServerName();
    if (!mounted || name == null) {
      return;
    }
    for (final server in cloudServers) {
      if (server.name == name) {
        setState(() => _server = server);
        return;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    unawaited(_submit());
  }

  Future<void> _showServerOptions() async {
    final selected = await Navigator.of(context).push<CloudServer>(
      PagedSheetRoute<CloudServer>(
        builder: (context) => SelectionSheet<CloudServer>(
          title: context.appLocalizations.server,
          sections: const [SelectionSection<CloudServer>(items: cloudServers)],
          labelBuilder: (item) => item.name,
          selectedOf: (_) => _server,
          onSelected: (item) => Navigator.of(context).pop(item),
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _server = selected);
    await preferences.saveCloudServerName(selected.name);
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final appLocalizations = context.appLocalizations;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      setState(
        () => _error = appLocalizations.emptyTip(appLocalizations.email),
      );
      return;
    }
    if (password.isEmpty) {
      setState(
        () => _error = appLocalizations.emptyTip(appLocalizations.password),
      );
      return;
    }
    if (_server.apiBase.isEmpty) {
      setState(
        () => _error = appLocalizations.emptyTip(appLocalizations.address),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(cloudActionProvider.notifier)
          .login(_server, email, password);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userFacingErrorMessage(error, appLocalizations),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return FormPage(
      title: appLocalizations.login,
      saveLabel: appLocalizations.login,
      saving: _saving,
      error: _error,
      onSave: _handleSave,
      children: [
        generateSection(
          items: [
            FormRow(
              title: appLocalizations.server,
              trailing: Text(
                _server.name,
                style: AppTextStyle.subheadline.of(context),
              ),
              onPressed: _showServerOptions,
            ),
            FormRow(
              title: appLocalizations.email,
              trailing: FormRowTextField(
                controller: _emailController,
                hintText: appLocalizations.required,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                autocorrect: false,
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
            ),
            FormRow(
              title: appLocalizations.password,
              trailing: FormRowSecretTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                hintText: appLocalizations.required,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSave(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountView extends ConsumerStatefulWidget {
  final CloudSession session;

  const _AccountView({required this.session});

  @override
  ConsumerState<_AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends ConsumerState<_AccountView> {
  var _syncing = false;

  CloudSession get _session => widget.session;

  Future<void> _handleSync() async {
    if (_syncing) {
      return;
    }
    setState(() => _syncing = true);
    try {
      await ref.read(cloudActionProvider.notifier).syncNow();
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.cloudSubscription),
      ),
      destructive: true,
      confirmText: appLocalizations.logout,
    );
    if (res != true) {
      return;
    }
    await ref.read(cloudActionProvider.notifier).logout();
  }

  /// Re-login starts over: the expired account's subscription is removed, so
  /// the new sign-in creates a fresh one.
  Future<void> _handleRelogin() async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.cloudSubscription),
      ),
      destructive: true,
      confirmText: appLocalizations.relogin,
    );
    if (res != true) {
      return;
    }
    await ref.read(cloudActionProvider.notifier).logout();
  }

  String _expireText(int seconds) {
    if (seconds <= 0) {
      return currentAppLocalizations.infiniteTime;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000).show;
  }

  String _accountSubtitle(CloudAccount? account) {
    final parts = <String>[
      if (_session.serverName.isNotEmpty) _session.serverName,
      if (account != null && account.expiredAt > 0)
        _expireText(account.expiredAt),
    ];
    return parts.join(' · ');
  }

  String? _profileSubtitle(
    BuildContext context,
    Profile? profile, {
    required bool stale,
  }) {
    final info = profile?.subscriptionInfo;
    if (info == null) {
      return null;
    }
    final parts = <String>[];
    if (info.total > 0) {
      final used = info.upload + info.download;
      parts.add('${used.traffic.show} / ${info.total.traffic.show}');
    }
    if (info.expire > 0) {
      parts.add(
        '${context.appLocalizations.expireTime} ${_expireText(info.expire)}',
      );
    }
    if (stale) {
      parts.add(context.appLocalizations.maybeStale);
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final account = ref.watch(cloudAccountProvider).value;
    final profile = _session.profileId == null
        ? null
        : ref.watch(profilesProvider).getProfile(_session.profileId);
    final profileSubtitle = _profileSubtitle(
      context,
      profile,
      stale: _session.authExpired,
    );
    final accountSubtitle = _accountSubtitle(account);
    return CommonScaffold(
      title: appLocalizations.account,
      body: ListView(
        padding: EdgeInsets.only(top: context.contentTopPadding, bottom: 16),
        children: [
          if (_session.authExpired)
            generateSection(
              items: [
                ListItem(
                  leading: GlyphIcon(AppGlyphs.info, color: colorScheme.error),
                  title: Text(
                    appLocalizations.loginExpired,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  subtitle: _session.subscribeUrl.isEmpty
                      ? null
                      : Text(appLocalizations.loginExpiredDesc),
                  trailing: Text(
                    appLocalizations.relogin,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                  onTap: _handleRelogin,
                ),
              ],
            ),
          generateSection(
            title: appLocalizations.account,
            items: [
              ListItem(
                leading: const GlyphIcon(AppGlyphs.account),
                title: Text(account?.email ?? _session.email),
                subtitle: accountSubtitle.isEmpty
                    ? null
                    : Text(accountSubtitle),
              ),
            ],
          ),
          generateSection(
            title: appLocalizations.cloudSubscription,
            items: [
              if (profile != null)
                ListItem(
                  leading: const GlyphIcon(AppGlyphs.cloudSync),
                  title: Text(profile.realLabel),
                  subtitle: profileSubtitle == null
                      ? null
                      : Text(profileSubtitle),
                ),
              ListItem(
                leading: const GlyphIcon(AppGlyphs.sync),
                title: Text(appLocalizations.syncNow),
                trailing: _syncing ? const CommonCircleLoading(size: 20) : null,
                onTap: _syncing ? null : _handleSync,
              ),
            ],
          ),
          generateSection(
            items: [
              ListItem(
                leading: GlyphIcon(AppGlyphs.close, color: colorScheme.error),
                title: Text(
                  appLocalizations.logout,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
