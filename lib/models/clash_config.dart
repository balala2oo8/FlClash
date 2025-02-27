// ignore_for_file: invalid_annotation_target

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/enum.dart';

part 'generated/clash_config.freezed.dart';
part 'generated/clash_config.g.dart';

const defaultTun = Tun();

@freezed
class Tun with _$Tun {
  const factory Tun({
    @Default(false) bool enable,
    @Default(appName) String device,
    @Default(TunStack.gvisor) TunStack stack,
    @JsonKey(name: "dns-hijack") @Default(["any:53"]) List<String> dnsHijack,
  }) = _Tun;

  factory Tun.fromJson(Map<String, Object?> json) => _$TunFromJson(json);

  factory Tun.realFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return defaultTun;
    }
    try {
      return Tun.fromJson(json);
    } catch (_) {
      return defaultTun;
    }
  }
}

@freezed
class FallbackFilter with _$FallbackFilter {
  const factory FallbackFilter({
    @Default(true) bool geoip,
    @Default("CN") @JsonKey(name: "geoip-code") String geoipCode,
    @Default(["gfw"]) List<String> geosite,
    @Default(["240.0.0.0/4"]) List<String> ipcidr,
    @Default([
      "+.google.com",
      "+.facebook.com",
      "+.youtube.com",
    ])
    List<String> domain,
  }) = _FallbackFilter;

  factory FallbackFilter.fromJson(Map<String, Object?> json) =>
      _$FallbackFilterFromJson(json);
}

const defaultDns = Dns();

@freezed
class Dns with _$Dns {
  const factory Dns({
    @Default(true) bool enable,
    @Default(false) @JsonKey(name: "prefer-h3") bool preferH3,
    @Default(true) @JsonKey(name: "use-hosts") bool useHosts,
    @Default(true) @JsonKey(name: "use-system-hosts") bool useSystemHosts,
    @Default(false) @JsonKey(name: "respect-rules") bool respectRules,
    @Default(false) bool ipv6,
    @Default(["223.5.5.5"])
    @JsonKey(name: "default-nameserver")
    List<String> defaultNameserver,
    @Default(DnsMode.fakeIp)
    @JsonKey(name: "enhanced-mode")
    DnsMode enhancedMode,
    @Default("198.18.0.1/16")
    @JsonKey(name: "fake-ip-range")
    String fakeIpRange,
    @Default([
      "*.lan",
      "localhost.ptlogin2.qq.com",
    ])
    @JsonKey(name: "fake-ip-filter")
    List<String> fakeIpFilter,
    @Default({
      "www.baidu.com": "114.114.114.114",
      "+.internal.crop.com": "10.0.0.1",
      "geosite:cn": "https://doh.pub/dns-query"
    })
    @JsonKey(name: "nameserver-policy")
    Map<String, String> nameserverPolicy,
    @Default([
      "https://doh.pub/dns-query",
      "https://dns.alidns.com/dns-query",
    ])
    List<String> nameserver,
    @Default([
      "tls://8.8.4.4",
      "tls://1.1.1.1",
    ])
    List<String> fallback,
    @Default([
      "https://doh.pub/dns-query",
    ])
    @JsonKey(name: "proxy-server-nameserver")
    List<String> proxyServerNameserver,
    @Default(FallbackFilter())
    @JsonKey(name: "fallback-filter")
    FallbackFilter fallbackFilter,
  }) = _Dns;

  factory Dns.fromJson(Map<String, Object?> json) => _$DnsFromJson(json);

  factory Dns.safeDnsFromJson(Map<String, Object?> json) {
    try {
      return Dns.fromJson(json);
    } catch (_) {
      return const Dns();
    }
  }
}

typedef GeoXMap = Map<String, String>;

typedef HostsMap = Map<String, String>;

const defaultMixedPort = 7890;
const defaultKeepAliveInterval = 30;

const defaultBypassPrivateRouteAddress = [
  "1.0.0.0/8",
  "2.0.0.0/7",
  "4.0.0.0/6",
  "8.0.0.0/7",
  "11.0.0.0/8",
  "12.0.0.0/6",
  "16.0.0.0/4",
  "32.0.0.0/3",
  "64.0.0.0/3",
  "96.0.0.0/4",
  "112.0.0.0/5",
  "120.0.0.0/6",
  "124.0.0.0/7",
  "126.0.0.0/8",
  "128.0.0.0/3",
  "160.0.0.0/5",
  "168.0.0.0/8",
  "169.0.0.0/9",
  "169.128.0.0/10",
  "169.192.0.0/11",
  "169.224.0.0/12",
  "169.240.0.0/13",
  "169.248.0.0/14",
  "169.252.0.0/15",
  "169.255.0.0/16",
  "170.0.0.0/7",
  "172.0.0.0/12",
  "172.32.0.0/11",
  "172.64.0.0/10",
  "172.128.0.0/9",
  "173.0.0.0/8",
  "174.0.0.0/7",
  "176.0.0.0/4",
  "192.0.0.0/9",
  "192.128.0.0/11",
  "192.160.0.0/13",
  "192.169.0.0/16",
  "192.170.0.0/15",
  "192.172.0.0/14",
  "192.176.0.0/12",
  "192.192.0.0/10",
  "193.0.0.0/8",
  "194.0.0.0/7",
  "196.0.0.0/6",
  "200.0.0.0/5",
  "208.0.0.0/4",
  "240.0.0.0/5",
  "248.0.0.0/6",
  "252.0.0.0/7",
  "254.0.0.0/8",
  "255.0.0.0/9",
  "255.128.0.0/10",
  "255.192.0.0/11",
  "255.224.0.0/12",
  "255.240.0.0/13",
  "255.248.0.0/14",
  "255.252.0.0/15",
  "255.254.0.0/16",
  "255.255.0.0/17",
  "255.255.128.0/18",
  "255.255.192.0/19",
  "255.255.224.0/20",
  "255.255.240.0/21",
  "255.255.248.0/22",
  "255.255.252.0/23",
  "255.255.254.0/24",
  "255.255.255.0/25",
  "255.255.255.128/26",
  "255.255.255.192/27",
  "255.255.255.224/28",
  "255.255.255.240/29",
  "255.255.255.248/30",
  "255.255.255.252/31",
  "255.255.255.254/32",
  "::/1",
  "8000::/2",
  "c000::/3",
  "e000::/4",
  "f000::/5",
  "f800::/6",
  "fe00::/9",
  "fec0::/10"
];

@JsonSerializable()
class ClashConfig extends ChangeNotifier {
  int _mixedPort;
  bool _allowLan;
  bool _ipv6;
  String _geodataLoader;
  LogLevel _logLevel;
  String _externalController;
  Mode _mode;
  FindProcessMode _findProcessMode;
  int _keepAliveInterval;
  bool _unifiedDelay;
  bool _tcpConcurrent;
  Tun _tun;
  Dns _dns;
  GeoXMap _geoXUrl;
  List<String> _rules;
  String? _globalRealUa;
  HostsMap _hosts;
  List<String> _includeRouteAddress;
  RouteMode _routeMode;

  ClashConfig()
      : _mixedPort = defaultMixedPort,
        _mode = Mode.rule,
        _ipv6 = true,
        _findProcessMode = FindProcessMode.off,
        _allowLan = false,
        _tcpConcurrent = false,
        _logLevel = LogLevel.info,
        _tun = const Tun(),
        _unifiedDelay = true,
        _geodataLoader = geodataLoaderMemconservative,
        _externalController = '',
        _keepAliveInterval = defaultKeepAliveInterval,
        _dns = defaultDns,
        _geoXUrl = defaultGeoXMap,
        _routeMode = RouteMode.config,
        _includeRouteAddress = [],
        _rules = [],
        _hosts = {};

  @JsonKey(name: "mixed-port", defaultValue: defaultMixedPort)
  int get mixedPort => _mixedPort;

  set mixedPort(int value) {
    if (_mixedPort != value) {
      _mixedPort = value;
      notifyListeners();
    }
  }

  @JsonKey(defaultValue: Mode.rule)
  Mode get mode => _mode;

  set mode(Mode value) {
    if (_mode != value) {
      _mode = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "find-process-mode", defaultValue: FindProcessMode.off)
  FindProcessMode get findProcessMode => _findProcessMode;

  set findProcessMode(FindProcessMode value) {
    if (_findProcessMode != value) {
      _findProcessMode = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "allow-lan")
  bool get allowLan => _allowLan;

  set allowLan(bool value) {
    if (_allowLan != value) {
      _allowLan = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "log-level", defaultValue: LogLevel.info)
  LogLevel get logLevel => _logLevel;

  set logLevel(LogLevel value) {
    if (_logLevel != value) {
      _logLevel = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "external-controller", defaultValue: '')
  String get externalController => _externalController;

  set externalController(String value) {
    if (_externalController != value) {
      _externalController = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "keep-alive-interval", defaultValue: defaultKeepAliveInterval)
  int get keepAliveInterval => _keepAliveInterval;

  set keepAliveInterval(int value) {
    if (_keepAliveInterval != value) {
      _keepAliveInterval = value;
      notifyListeners();
    }
  }

  @JsonKey(defaultValue: false)
  bool get ipv6 => _ipv6;

  set ipv6(bool value) {
    if (_ipv6 != value) {
      _ipv6 = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "geodata-loader", defaultValue: geodataLoaderMemconservative)
  String get geodataLoader => _geodataLoader;

  set geodataLoader(String value) {
    if (_geodataLoader != value) {
      _geodataLoader = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "unified-delay", defaultValue: false)
  bool get unifiedDelay => _unifiedDelay;

  set unifiedDelay(bool value) {
    if (_unifiedDelay != value) {
      _unifiedDelay = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "tcp-concurrent", defaultValue: false)
  bool get tcpConcurrent => _tcpConcurrent;

  set tcpConcurrent(bool value) {
    if (_tcpConcurrent != value) {
      _tcpConcurrent = value;
      notifyListeners();
    }
  }

  Tun get tun {
    return _tun;
  }

  set tun(Tun value) {
    if (_tun != value) {
      _tun = value;
      notifyListeners();
    }
  }

  @JsonKey(fromJson: Dns.safeDnsFromJson)
  Dns get dns => _dns;

  set dns(Dns value) {
    if (_dns != value) {
      _dns = value;
      notifyListeners();
    }
  }

  List<String> get rules => _rules;

  set rules(List<String> value) {
    if (_rules != value) {
      _rules = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "global-ua", includeFromJson: false, includeToJson: true)
  String get globalUa {
    if (_globalRealUa == null) {
      return globalState.packageInfo.ua;
    } else {
      return _globalRealUa!;
    }
  }

  @JsonKey(name: "global-real-ua", defaultValue: null)
  String? get globalRealUa => _globalRealUa;

  set globalRealUa(String? value) {
    if (_globalRealUa != value) {
      _globalRealUa = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "geox-url", defaultValue: defaultGeoXMap)
  GeoXMap get geoXUrl => _geoXUrl;

  set geoXUrl(GeoXMap value) {
    if (!stringAndStringMapEquality.equals(value, _geoXUrl)) {
      _geoXUrl = value;
      notifyListeners();
    }
  }

  @JsonKey(defaultValue: {})
  HostsMap get hosts => _hosts;

  set hosts(HostsMap value) {
    if (!stringAndStringMapEquality.equals(value, _hosts)) {
      _hosts = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "route-address", includeFromJson: false, includeToJson: true)
  List<String> get routeAddress {
    return switch (_routeMode == RouteMode.config) {
      true => _includeRouteAddress,
      false => defaultBypassPrivateRouteAddress,
    };
  }

  @JsonKey(name: "include-route-address", defaultValue: [])
  List<String> get includeRouteAddress => _includeRouteAddress;

  set includeRouteAddress(List<String> value) {
    if (!stringListEquality.equals(value, _includeRouteAddress)) {
      _includeRouteAddress = value;
      notifyListeners();
    }
  }

  @JsonKey(name: "route-mode", defaultValue: RouteMode.config)
  RouteMode get routeMode => _routeMode;

  set routeMode(RouteMode value) {
    if (value != _routeMode) {
      _routeMode = value;
      notifyListeners();
    }
  }

  update([ClashConfig? clashConfig]) {
    if (clashConfig != null) {
      _mixedPort = clashConfig._mixedPort;
      _allowLan = clashConfig._allowLan;
      _hosts = clashConfig._hosts;
      _mode = clashConfig._mode;
      _logLevel = clashConfig._logLevel;
      _tun = clashConfig._tun;
      _findProcessMode = clashConfig._findProcessMode;
      _geoXUrl = clashConfig._geoXUrl;
      _unifiedDelay = clashConfig._unifiedDelay;
      _globalRealUa = clashConfig._globalRealUa;
      _tcpConcurrent = clashConfig._tcpConcurrent;
      _externalController = clashConfig._externalController;
      _geodataLoader = clashConfig._geodataLoader;
      _dns = clashConfig._dns;
      _rules = clashConfig._rules;
      _routeMode = clashConfig._routeMode;
      _includeRouteAddress = clashConfig._includeRouteAddress;
    }
    notifyListeners();
  }

  ClashConfig copyWith() {
    return ClashConfig()
      ..mixedPort = _mixedPort
      ..mode = _mode
      ..ipv6 = _ipv6
      ..findProcessMode = _findProcessMode
      ..allowLan = _allowLan
      ..tcpConcurrent = _tcpConcurrent
      ..logLevel = _logLevel
      ..tun = tun
      ..unifiedDelay = _unifiedDelay
      ..geodataLoader = _geodataLoader
      ..externalController = _externalController
      ..keepAliveInterval = _keepAliveInterval
      ..dns = _dns
      ..geoXUrl = _geoXUrl
      ..routeMode = _routeMode
      ..includeRouteAddress = _includeRouteAddress
      ..rules = _rules
      ..hosts = _hosts;
  }

  Map<String, dynamic> toJson() {
    return _$ClashConfigToJson(this);
  }

  factory ClashConfig.fromJson(Map<String, dynamic> json) {
    return _$ClashConfigFromJson(json);
  }

  @override
  String toString() {
    return 'ClashConfig{_mixedPort: $_mixedPort, _allowLan: $_allowLan, _ipv6: $_ipv6, _geodataLoader: $_geodataLoader, _logLevel: $_logLevel, _externalController: $_externalController, _mode: $_mode, _findProcessMode: $_findProcessMode, _keepAliveInterval: $_keepAliveInterval, _unifiedDelay: $_unifiedDelay, _tcpConcurrent: $_tcpConcurrent, _tun: $_tun, _dns: $_dns, _geoXUrl: $_geoXUrl, _rules: $_rules, _globalRealUa: $_globalRealUa, _hosts: $_hosts}';
  }
}
