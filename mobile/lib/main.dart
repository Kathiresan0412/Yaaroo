import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/api_client.dart';
import 'core/secure_storage.dart';
import 'features/auth/presentation/auth_sheet.dart';
import 'features/onboarding/presentation/onboarding_wizard.dart';
import 'features/chat/presentation/chat_screen.dart';

const _dartDefineApiBaseUrl = String.fromEnvironment(
  'YAARO0_API_URL',
  defaultValue: 'https://yaaro-backend.vercel.app',
);

String get apiBaseUrl {
  final envApiBaseUrl = dotenv.env['YAARO0_API_URL']?.trim();
  return envApiBaseUrl?.isNotEmpty == true
      ? envApiBaseUrl!
      : _dartDefineApiBaseUrl;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  final api = ApiClient(apiBaseUrl);
  await api.init();
  runApp(YaaroMobileApp(api: api));
}

class YaaroMobileApp extends StatefulWidget {
  const YaaroMobileApp({required this.api, super.key});

  final ApiClient api;

  @override
  State<YaaroMobileApp> createState() => _YaaroMobileAppState();
}

class _YaaroMobileAppState extends State<YaaroMobileApp> {
  @override
  Widget build(BuildContext context) {
    return YaaroScope(
      api: widget.api,
      child: MaterialApp(
        title: 'Yaaro0',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: YaaroColors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: YaaroColors.rose,
            brightness: Brightness.dark,
            primary: YaaroColors.rose,
            secondary: YaaroColors.teal,
            surface: YaaroColors.surface,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const AppShell(),
      ),
    );
  }
}

class YaaroColors {
  static const black = Color(0xFF050506);
  static const surface = Color(0xFF111216);
  static const surfaceAlt = Color(0xFF191A20);
  static const rose = Color(0xFFFF4F6D);
  static const saffron = Color(0xFFFFB84D);
  static const teal = Color(0xFF31D0B2);
  static const muted = Color(0xB8FFFFFF);
  static const line = Color(0x2EFFFFFF);
}

Future<void> openMembershipScreen(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MembershipScreen()),
  );
}

class YaaroScope extends InheritedWidget {
  const YaaroScope({
    required this.api,
    required super.child,
    super.key,
  });

  final ApiClient api;

  static ApiClient of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<YaaroScope>();
    assert(scope != null, 'YaaroScope is missing.');
    return scope!.api;
  }

  @override
  bool updateShouldNotify(YaaroScope oldWidget) => api != oldWidget.api;
}

// ApiClient and ApiException are imported from core/api_client.dart

enum SwipeAction { like, pass, superlike }

class SwipeResult {
  const SwipeResult({
    required this.matched,
    this.matchId,
    this.message,
  });

  final bool matched;
  final String? matchId;
  final String? message;

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      matched: json['matched'] == true,
      matchId: json['matchId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.emailVerified,
    required this.onboardingCompleted,
  });

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool emailVerified;
  final bool onboardingCompleted;

  String get displayName {
    final parts =
        [firstName, lastName].whereType<String>().where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Yaaro0 member' : parts.join(' ');
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      firstName: (json['firstName'] ?? json['first_name'])?.toString(),
      lastName: (json['lastName'] ?? json['last_name'])?.toString(),
      emailVerified:
          json['emailVerified'] == true || json['email_verified'] == true,
      onboardingCompleted: json['onboardingCompleted'] == true ||
          json['onboarding_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'emailVerified': emailVerified,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    bool? emailVerified,
    bool? onboardingCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class DiscoveryProfile {
  const DiscoveryProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.city,
    required this.country,
    required this.headline,
    required this.photoUrl,
    required this.compatibilityScore,
    required this.distanceKm,
    required this.isVerified,
    required this.sharedInterests,
    required this.bio,
    required this.relationshipGoal,
    required this.loveLanguage,
  });

  final String id;
  final String displayName;
  final int age;
  final String? city;
  final String? country;
  final String headline;
  final String? photoUrl;
  final int compatibilityScore;
  final num? distanceKm;
  final bool isVerified;
  final List<String> sharedInterests;
  final String? bio;
  final String? relationshipGoal;
  final String? loveLanguage;

  String get location {
    final parts =
        [city, country].whereType<String>().where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Nearby' : parts.join(', ');
  }

  String get distanceLabel {
    if (distanceKm == null) {
      return 'Nearby';
    }
    return '${distanceKm!.round()} km away';
  }

  factory DiscoveryProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final interests = profile['interests'] is Map<String, dynamic>
        ? profile['interests'] as Map<String, dynamic>
        : <String, dynamic>{};
    final hobbies =
        interests['hobbies'] is List ? interests['hobbies'] as List : const [];
    final shared = json['sharedInterests'] is List
        ? json['sharedInterests'] as List
        : const [];

    return DiscoveryProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'New member',
      age: int.tryParse(json['age']?.toString() ?? '') ?? 0,
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      headline: json['headline']?.toString() ?? 'Open to meaningful connection',
      photoUrl: json['mainPhotoUrl']?.toString(),
      compatibilityScore:
          int.tryParse(json['compatibilityScore']?.toString() ?? '') ?? 80,
      distanceKm: num.tryParse(json['distanceKm']?.toString() ?? ''),
      isVerified: json['isVerified'] == true,
      sharedInterests: shared.isNotEmpty
          ? shared.map((item) => item.toString()).toList()
          : hobbies.map((item) => item.toString()).toList(),
      bio: profile['bio']?.toString(),
      relationshipGoal: profile['relationshipGoal']?.toString(),
      loveLanguage: profile['loveLanguage']?.toString(),
    );
  }
}

class ExploreCategory {
  const ExploreCategory({
    required this.key,
    required this.label,
    required this.count,
    required this.emoji,
  });

  final String key;
  final String label;
  final int count;
  final String emoji;

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    return ExploreCategory(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Interest',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      emoji: json['emoji']?.toString() ?? '•',
    );
  }
}

class VibeQuestion {
  const VibeQuestion({
    required this.id,
    required this.prompt,
    required this.answers,
    required this.answer,
  });

  final String id;
  final String prompt;
  final List<String> answers;
  final String? answer;

  factory VibeQuestion.fromJson(Map<String, dynamic> json, String? answer) {
    final answers =
        json['answers'] is List ? json['answers'] as List : const [];
    return VibeQuestion(
      id: json['id']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? 'What are you feeling today?',
      answers: answers.map((item) => item.toString()).toList(),
      answer: answer,
    );
  }
}

class MatchItem {
  const MatchItem({
    required this.id,
    this.userId = '',
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.preview,
    required this.unreadCount,
    required this.compatibilityScore,
    required this.isVerified,
    this.isNew = false,
    this.matchedAt = '',
    this.sentAt,
  });

  final String id;
  final String userId;
  final String name;
  final int? age;
  final String? photoUrl;
  final String preview;
  final int unreadCount;
  final int compatibilityScore;
  final bool isVerified;
  final bool isNew;
  final String matchedAt;
  final String? sentAt;

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map<String, dynamic>
        ? json['lastMessage'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MatchItem(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['displayName']?.toString() ?? 'Match',
      age: int.tryParse(user['age']?.toString() ?? ''),
      photoUrl: user['mainPhotoUrl']?.toString(),
      preview: lastMessage['preview']?.toString() ?? 'Start the conversation.',
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
      compatibilityScore:
          int.tryParse(json['compatibilityScore']?.toString() ?? '') ?? 82,
      isVerified: user['isVerified'] == true,
      isNew: json['isNew'] == true,
      matchedAt: json['matchedAt']?.toString() ?? '',
      sentAt: lastMessage['sentAt']?.toString(),
    );
  }
}

class LikeItem {
  const LikeItem({
    required this.id,
    this.userId = '',
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.action,
    required this.isVerified,
  });

  final String id;
  final String userId;
  final String name;
  final int? age;
  final String? photoUrl;
  final String action;
  final bool isVerified;

  factory LikeItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return LikeItem(
      id: json['id']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['displayName']?.toString() ?? 'Someone new',
      age: int.tryParse(user['age']?.toString() ?? ''),
      photoUrl: user['mainPhotoUrl']?.toString(),
      action: json['action']?.toString() ?? 'like',
      isVerified: user['isVerified'] == true,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  bool _showLanding = true;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = YaaroScope.of(context);
      if (api.user != null) {
        setState(() {
          _showLanding = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check initial link if app was opened by a deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Listen to incoming links while the app is in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    final pathSegments = uri.pathSegments;
    final host = uri.host;
    final scheme = uri.scheme;

    String? mode;
    String? token;

    if (scheme == 'yaaro0') {
      if (host == 'verify-email') {
        mode = 'verify';
        token = pathSegments.isNotEmpty
            ? pathSegments.first
            : uri.queryParameters['token'];
      } else if (host == 'reset-password') {
        mode = 'reset';
        token = pathSegments.isNotEmpty
            ? pathSegments.first
            : uri.queryParameters['token'];
      }
    } else if (scheme == 'http' || scheme == 'https') {
      if (pathSegments.length >= 2) {
        if (pathSegments[0] == 'verify-email') {
          mode = 'verify';
          token = pathSegments[1];
        } else if (pathSegments[0] == 'reset-password') {
          mode = 'reset';
          token = pathSegments[1];
        }
      }
    }

    if (mode != null && token != null) {
      final authMode = mode == 'verify' ? AuthMode.verify : AuthMode.reset;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAuthForDeepLink(authMode, token!);
      });
    }
  }

  Future<void> _openAuthForDeepLink(AuthMode mode, String token) async {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthSheet(
        initialMode: mode,
        token: token,
      ),
    );

    setState(() {
      if (YaaroScope.of(context).user != null) {
        _showLanding = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = YaaroScope.of(context);
    final user = api.user;

    if (_showLanding && user == null) {
      return LandingScreen(
        onLogin: () => _openAuth(),
        onCreateAccount: () => _openAuth(createAccount: true),
      );
    }

    if (user != null && !user.onboardingCompleted) {
      return OnboardingWizard(
        onComplete: () {
          setState(() {
            _showLanding = false;
            _tab = 0;
          });
        },
        onLogout: () async {
          await api.logout();
          setState(() {
            _showLanding = true;
            _tab = 0;
          });
        },
      );
    }

    final screens = [
      DiscoverScreen(onOpenAuth: _openAuth),
      ExploreScreen(onOpenAuth: _openAuth),
      MatchesScreen(onOpenAuth: _openAuth),
      ProfileScreen(
        onOpenAuth: _openAuth,
        onLogout: () async {
          await api.logout();
          setState(() {
            _showLanding = true;
            _tab = 0;
          });
        },
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: NavigationBar(
            selectedIndex: _tab,
            height: 70,
            backgroundColor: YaaroColors.surface.withOpacity(0.94),
            indicatorColor: YaaroColors.rose.withOpacity(0.22),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.local_fire_department), label: 'Discover'),
              NavigationDestination(
                  icon: Icon(Icons.explore), label: 'Explore'),
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble), label: 'Matches'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAuth({bool createAccount = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthSheet(initialSignup: createAccount),
    );
    setState(() {
      if (YaaroScope.of(context).user != null) {
        _showLanding = false;
      }
    });
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    required this.onLogin,
    required this.onCreateAccount,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                left: 22,
                right: 22,
                top: 92,
                child: Text(
                  'Meet with\ntrust, not\nnoise.',
                  style: TextStyle(
                    fontSize: 56,
                    height: 0.92,
                    fontWeight: FontWeight.w900,
                    color: Color(0x24FFFFFF),
                  ),
                ),
              ),
              Positioned(
                right: -36,
                top: 86,
                child: Transform.rotate(
                  angle: 0.14,
                  child: const _LandingPreviewCard(
                    title: 'Verified',
                    subtitle: 'Profile review',
                    icon: Icons.verified_user,
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 156,
                child: Transform.rotate(
                  angle: -0.12,
                  child: const _LandingPreviewCard(
                    title: 'Private',
                    subtitle: 'Safer matching',
                    icon: Icons.lock,
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/brand/logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      TextButton(
                          onPressed: onLogin, child: const Text('Log in')),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.34),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: YaaroColors.surface.withOpacity(0.94),
                      border: Border.all(color: YaaroColors.line),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: YaaroColors.rose.withOpacity(0.18),
                          blurRadius: 52,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'TAMIL DATING, FRIENDSHIP, AND MATRIMONY',
                          style: TextStyle(
                            color: YaaroColors.teal,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Log in to Yaaro0',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 0.98,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Continue to your conversations, profile review, safer matches, and shared-interest discovery.',
                          style:
                              TextStyle(color: YaaroColors.muted, height: 1.35),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: onLogin,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: YaaroColors.line),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: onLogin,
                          icon: const Icon(Icons.music_note),
                          label: const Text('Continue with TikTok'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: YaaroColors.line),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.14))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text('or use email',
                                  style: TextStyle(color: YaaroColors.muted)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.14))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onLogin,
                          style: FilledButton.styleFrom(
                            backgroundColor: YaaroColors.rose,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                          ),
                          child: const Text('Log in'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: onCreateAccount,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: YaaroColors.line),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('New to Yaaro0? Create account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingPreviewCard extends StatelessWidget {
  const _LandingPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: Container(
        width: 148,
        height: 198,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YaaroColors.surfaceAlt,
          border: Border.all(color: YaaroColors.line),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: YaaroColors.teal, size: 30),
            const Spacer(),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: YaaroColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({required this.onOpenAuth, super.key});

  final VoidCallback onOpenAuth;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<DiscoveryProfile> _profiles = const [];
  bool _loading = true;
  bool _swiping = false;
  String _message = '';
  Offset _drag = Offset.zero;

  DiscoveryProfile? get _top => _profiles.isEmpty ? null : _profiles.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cards = await YaaroScope.of(context).discover();
      setState(() {
        _profiles = cards;
        _message = '';
      });
    } catch (_) {
      setState(() {
        _profiles = const [];
        _message = '';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradient(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            children: [
              HeaderBar(
                title: 'Yaaro0',
                actionLabel: YaaroScope.of(context).user == null ? 'Login' : '',
                onAction: widget.onOpenAuth,
              ),
              const SizedBox(height: 18),
              StatusPill(
                text: _message.isEmpty
                    ? 'Reviewed profiles, shared intent, private by default'
                    : _message,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _top == null
                        ? EmptyState(
                            title: 'Fresh profiles are on the way',
                            message:
                                'Check back soon or explore people by interest.',
                            actionLabel: 'Refresh',
                            onAction: _load,
                          )
                        : _buildCardStack(),
              ),
              if (_top != null) ...[
                const SizedBox(height: 14),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    final visible = _profiles.take(3).toList().reversed.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < visible.length; i++)
              Transform.translate(
                offset: Offset(
                    0,
                    i == visible.length - 1
                        ? _drag.dy
                        : 16.0 * (visible.length - i - 1)),
                child: Transform.rotate(
                  angle: i == visible.length - 1 ? _drag.dx / 850 : 0,
                  child: GestureDetector(
                    onPanUpdate: i == visible.length - 1
                        ? (details) => setState(() => _drag += details.delta)
                        : null,
                    onPanEnd: i == visible.length - 1
                        ? (_) {
                            final action = _drag.dx > 110
                                ? SwipeAction.like
                                : _drag.dx < -110
                                    ? SwipeAction.pass
                                    : null;
                            if (action == null) {
                              setState(() => _drag = Offset.zero);
                            } else {
                              _swipe(action);
                            }
                          }
                        : null,
                    child: ProfileCard(profile: visible[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RoundAction(
            icon: Icons.close,
            color: Colors.white,
            onPressed: _swiping ? null : () => _swipe(SwipeAction.pass)),
        const SizedBox(width: 18),
        RoundAction(
            icon: Icons.favorite,
            color: YaaroColors.rose,
            onPressed: _swiping ? null : () => _swipe(SwipeAction.like)),
        const SizedBox(width: 18),
        RoundAction(
            icon: Icons.rotate_left,
            color: YaaroColors.saffron,
            onPressed: _swiping ? null : _undo),
      ],
    );
  }

  Future<void> _swipe(SwipeAction action) async {
    final profile = _top;
    if (profile == null || _swiping) {
      return;
    }

    setState(() {
      _swiping = true;
      _profiles = _profiles.skip(1).toList();
      _drag = Offset.zero;
      if (action == SwipeAction.like || action == SwipeAction.superlike) {
        _message = 'Sent ${action == SwipeAction.superlike ? 'a superlike' : 'a like'} to ${profile.displayName}.';
      } else {
        _message = '';
      }
    });

    // Throttled UI unlock: allow the next swipe after 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _swiping = false);
      }
    });

    // Run the swipe request in the background (optimistic UI)
    YaaroScope.of(context).swipe(profile.id, action).then((result) {
      if (result.matched && mounted) {
        setState(() => _message = "It's a match with ${profile.displayName}!");
      }
    }).catchError((err) {
      debugPrint('Swipe failed: $err');
      if (mounted) {
        setState(() => _message = 'Could not send swipe to ${profile.displayName}.');
      }
    });
  }

  Future<void> _undo() async {
    setState(() => _message = '');
    try {
      await YaaroScope.of(context).undoSwipe();
      await _load();
      setState(() => _message = 'Last swipe undone.');
    } catch (_) {
      setState(() => _message = 'Undo is unavailable right now.');
    }
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({required this.onOpenAuth, super.key});

  final VoidCallback onOpenAuth;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<ExploreCategory> _categories = const [];
  List<DiscoveryProfile> _profiles = const [];
  List<DiscoveryProfile> _vibeProfiles = const [];
  VibeQuestion? _vibeQuestion;
  String _activeGoal = '';
  String _activeInterest = '';
  String _message = '';
  bool _loading = true;
  bool _profilesLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = YaaroScope.of(context);
      final results = await Future.wait<dynamic>([
        api.categories(),
        api.exploreNearby(),
        api.vibeToday(),
      ]);
      setState(() {
        _categories = results[0] as List<ExploreCategory>;
        _profiles = results[1] as List<DiscoveryProfile>;
        _vibeQuestion = results[2] as VibeQuestion?;
        _message = '';
      });
    } catch (_) {
      setState(() {
        _categories = const [];
        _profiles = const [];
        _vibeQuestion = null;
        _message = '';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradient(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            HeaderBar(
              title: 'Explore',
              actionLabel: YaaroScope.of(context).user == null ? 'Login' : '',
              onAction: widget.onOpenAuth,
            ),
            const SizedBox(height: 18),
            Text(
              'Find people by what you both love',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse shared interests, intent, nearby profiles, and daily conversation prompts.',
              style: TextStyle(color: YaaroColors.muted, height: 1.35),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 14),
              StatusPill(text: _message),
            ],
            const SizedBox(height: 20),
            SectionTitle(
                title: 'Vibes', trailing: _loading ? 'Syncing' : 'Today'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _vibeQuestion?.prompt ??
                        'Today\'s vibe question is unavailable.',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_vibeQuestion?.answers ?? const <String>[])
                        .map((answer) => ChoiceChip(
                              label: Text(answer),
                              selected: answer == _vibeQuestion?.answer,
                              selectedColor: YaaroColors.teal.withOpacity(0.24),
                              onSelected: (_) => _answerVibe(answer),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            if (_vibeProfiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._vibeProfiles.map(
                (profile) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CompactProfileTile(
                    profile: profile,
                    onPass: () => _decide(profile, SwipeAction.pass),
                    onLike: () => _decide(profile, SwipeAction.like),
                  ),
                ),
              ),
            ],
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 22),
              SectionTitle(
                  title: 'Interests', trailing: '${_categories.length} groups'),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isActive = category.key == _activeInterest;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExploreCategoryDetailScreen(category: category),
                          ),
                        );
                      },
                      child: Container(
                        width: 148,
                        padding: const EdgeInsets.all(12),
                        decoration: panelDecoration().copyWith(
                          border: Border.all(
                            color:
                                isActive ? YaaroColors.rose : YaaroColors.line,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(height: 6),
                            Text(category.label,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text(
                              '${category.count} people',
                              style: const TextStyle(
                                  color: YaaroColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 22),
            SectionTitle(title: 'Intent', trailing: _activeGoal),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Long-term', 'Casual', 'Friends', 'Not sure']
                  .map(
                    (goal) => ChoiceChip(
                      label: Text(goal),
                      selected: goal == _activeGoal,
                      selectedColor: YaaroColors.rose.withOpacity(0.26),
                      onSelected: (_) => _loadByGoal(goal),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            SectionTitle(
                title: _activeInterest.isEmpty
                    ? 'Nearby picks'
                    : 'People in this interest',
                trailing: _profilesLoading ? 'Loading' : 'Live'),
            const SizedBox(height: 10),
            ..._profiles.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CompactProfileTile(
                  profile: profile,
                  onPass: () => _decide(profile, SwipeAction.pass),
                  onLike: () => _decide(profile, SwipeAction.like),
                ),
              ),
            ),
            if (!_profilesLoading && _profiles.isEmpty)
              EmptyState(
                title: 'No profiles in this lane yet',
                message: 'Try a different interest or relationship goal.',
                actionLabel: 'Refresh nearby',
                onAction: _loadNearby,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNearby() async {
    setState(() {
      _profilesLoading = true;
      _activeGoal = '';
      _activeInterest = '';
    });
    try {
      final profiles = await YaaroScope.of(context).exploreNearby();
      setState(() {
        _profiles = profiles;
        _message = '';
      });
    } catch (_) {
      setState(() => _message = 'Nearby profiles are unavailable right now.');
    } finally {
      if (mounted) {
        setState(() => _profilesLoading = false);
      }
    }
  }

  Future<void> _loadByGoal(String goal) async {
    setState(() {
      _profilesLoading = true;
      _activeGoal = goal;
      _activeInterest = '';
    });
    try {
      final profiles = await YaaroScope.of(context).exploreByGoal(goal);
      setState(() {
        _profiles = profiles;
        _message = '';
      });
    } catch (_) {
      setState(() => _message = 'No profiles found for $goal yet.');
    } finally {
      if (mounted) {
        setState(() => _profilesLoading = false);
      }
    }
  }



  Future<void> _answerVibe(String answer) async {
    setState(() {
      _vibeQuestion = _vibeQuestion == null
          ? null
          : VibeQuestion(
              id: _vibeQuestion!.id,
              prompt: _vibeQuestion!.prompt,
              answers: _vibeQuestion!.answers,
              answer: answer,
            );
      _message = '';
    });
    try {
      final profiles = await YaaroScope.of(context).respondToVibe(answer);
      setState(() => _vibeProfiles = profiles);
    } catch (_) {
      setState(() => _message = 'Unable to save your vibe right now.');
    }
  }

  Future<void> _decide(DiscoveryProfile profile, SwipeAction action) async {
    setState(() {
      _profiles = _profiles.where((item) => item.id != profile.id).toList();
      _vibeProfiles =
          _vibeProfiles.where((item) => item.id != profile.id).toList();
      _message = action == SwipeAction.like
          ? 'Liked ${profile.displayName}.'
          : 'Passed on ${profile.displayName}.';
    });

    try {
      final result = await YaaroScope.of(context).swipe(profile.id, action);
      if (result.matched) {
        setState(() => _message = "It's a match with ${profile.displayName}.");
      }
    } catch (_) {
      setState(() => _message = 'Action failed. Try again.');
    }
  }
}

String formatTimestamp(String? value) {
  if (value == null || value.isEmpty) {
    return '';
  }

  try {
    final date = DateTime.parse(value).toLocal();
    final diff = DateTime.now().difference(date);
    final minutes = diff.inMinutes;

    if (minutes < 1) {
      return 'now';
    }

    if (minutes < 60) {
      return '${minutes}m';
    }

    final hours = diff.inHours;
    if (hours < 24) {
      return '${hours}h';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  } catch (_) {
    return '';
  }
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({required this.onOpenAuth, super.key});

  final VoidCallback onOpenAuth;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchItem> _matches = [];
  List<LikeItem> _likes = [];
  int _likesCount = 0;
  bool _likesBlurred = true;
  String _query = '';
  String _message = '';
  bool _loading = true;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _load();
    Future.delayed(Duration.zero, _setupSocket);
  }

  @override
  void dispose() {
    if (_socket != null) {
      try {
        _socket!.disconnect();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final api = YaaroScope.of(context);
      final results = await Future.wait<dynamic>([
        api.matches(),
        api.likesReceivedFull(),
      ]);

      final matches = results[0] as List<MatchItem>;
      final likesPayload = results[1] as Map<String, dynamic>;
      final rawLikes = likesPayload['likes'];
      List<LikeItem> likes = [];
      if (rawLikes is List) {
        likes = rawLikes
            .whereType<Map<String, dynamic>>()
            .map(LikeItem.fromJson)
            .toList();
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _likes = likes;
          _likesCount = int.tryParse(likesPayload['count']?.toString() ?? '') ??
              likes.length;
          _likesBlurred = likesPayload['blurred'] == true;
          _message = '';
        });
      }

      final cacheData = jsonEncode({
        'matches': matches
            .map((m) => {
                  'id': m.id,
                  'user': {
                    'id': m.userId,
                    'displayName': m.name,
                    'age': m.age,
                    'mainPhotoUrl': m.photoUrl,
                    'isVerified': m.isVerified,
                  },
                  'lastMessage': {
                    'preview': m.preview,
                    'sentAt': m.sentAt,
                  },
                  'unreadCount': m.unreadCount,
                  'compatibilityScore': m.compatibilityScore,
                  'isNew': m.isNew,
                  'matchedAt': m.matchedAt,
                })
            .toList(),
        'likes': likes
            .map((l) => {
                  'id': l.id,
                  'user': {
                    'id': l.userId,
                    'displayName': l.name,
                    'age': l.age,
                    'mainPhotoUrl': l.photoUrl,
                    'isVerified': l.isVerified,
                  },
                  'action': l.action,
                })
            .toList(),
        'likesCount': _likesCount,
        'likesBlurred': _likesBlurred,
      });
      await SecureStorage.instance.write('matches_cache', cacheData);
    } catch (e) {
      try {
        final rawCache = await SecureStorage.instance.read('matches_cache');
        if (rawCache != null) {
          final cached = jsonDecode(rawCache);
          if (cached is Map<String, dynamic>) {
            final rawMatches = cached['matches'] as List? ?? [];
            final rawLikes = cached['likes'] as List? ?? [];
            if (mounted) {
              setState(() {
                _matches = rawMatches
                    .whereType<Map<String, dynamic>>()
                    .map(MatchItem.fromJson)
                    .toList();
                _likes = rawLikes
                    .whereType<Map<String, dynamic>>()
                    .map(LikeItem.fromJson)
                    .toList();
                _likesCount = cached['likesCount'] as int? ?? 0;
                _likesBlurred = cached['likesBlurred'] == true;
                _message = 'Showing saved matches while Yaaro0 reconnects.';
              });
            }
            return;
          }
        }
      } catch (_) {}
      if (mounted) {
        setState(() => _message = 'Matches are unavailable.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _setupSocket() {
    final api = YaaroScope.of(context);
    final token = api.accessToken;
    if (token == null) return;

    final String apiHost = '${api.baseUri.scheme}://${api.baseUri.authority}';
    final String socketUrl =
        const String.fromEnvironment('YAARO0_SOCKET_URL').isNotEmpty
            ? const String.fromEnvironment('YAARO0_SOCKET_URL')
            : apiHost;

    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        final matchId = data['matchId']?.toString();
        final senderId = data['senderId']?.toString();
        final type = data['type']?.toString();
        final content = data['content']?.toString();
        final createdAt = data['createdAt']?.toString();

        if (senderId == api.user?.id) return;

        if (mounted) {
          setState(() {
            _matches = _matches.map((match) {
              if (match.id == matchId) {
                String preview = 'Message';
                if (type == 'photo' || type == 'image') {
                  preview = 'Photo';
                } else if (type == 'gif') {
                  preview = 'GIF';
                } else if (type == 'voice') {
                  preview = 'Voice message';
                } else if (content != null) {
                  preview = content;
                }

                return MatchItem(
                  id: match.id,
                  userId: match.userId,
                  name: match.name,
                  age: match.age,
                  photoUrl: match.photoUrl,
                  preview: preview,
                  unreadCount: match.unreadCount + 1,
                  compatibilityScore: match.compatibilityScore,
                  isVerified: match.isVerified,
                  isNew: match.isNew,
                  matchedAt: match.matchedAt,
                  sentAt: createdAt,
                );
              }
              return match;
            }).toList();
          });
        }
      }
    });

    _socket!.connect();
  }

  List<MatchItem> get _filteredMatches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _matches;
    }
    return _matches.where((m) => m.name.toLowerCase().contains(query)).toList();
  }

  List<MatchItem> get _newMatches {
    return _filteredMatches.where((m) => m.isNew).toList();
  }

  List<MapEntry<String, String>> _sectionRows(Map<String, dynamic>? section) {
    if (section == null) return [];
    return section.entries
        .map((entry) {
          final value = entry.value;
          String strVal = '';
          if (value is List) {
            strVal = value.join(', ');
          } else if (value != null) {
            strVal = value.toString();
          }
          final label = entry.key
              .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
              .replaceFirstMapped(
                  RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
          return MapEntry(label, strVal);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  Future<void> _unmatch(MatchItem match) async {
    if (mounted) {
      setState(() => _message = '');
    }
    try {
      final api = YaaroScope.of(context);
      await api.deleteMatch(match.id);
      if (!mounted) return;
      setState(() {
        _matches = _matches.where((m) => m.id != match.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unmatched with ${match.name}.'),
          backgroundColor: YaaroColors.rose,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Unable to unmatch.');
      }
    }
  }

  Future<void> _likeBack(String userId, String name) async {
    if (mounted) {
      setState(() => _message = '');
    }
    try {
      final api = YaaroScope.of(context);
      final result = await api.swipe(userId, SwipeAction.like);

      if (!mounted) return;
      setState(() {
        _likes = _likes.where((l) => l.userId != userId).toList();
        if (_likesCount > 0) {
          _likesCount--;
        }
      });

      if (result.matched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("It's a Match with $name!"),
            backgroundColor: YaaroColors.teal,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sent a like back to $name."),
            backgroundColor: YaaroColors.rose,
          ),
        );
      }

      _load();
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Unable to like back.');
      }
    }
  }

  Future<void> _showUnmatchConfirmation(MatchItem match) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: YaaroColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.shield, color: YaaroColors.rose, size: 28),
              const SizedBox(width: 10),
              Text(
                'Unmatch ${match.name}?',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: const Text(
            'This removes the match from your list and deletes all conversations. This action cannot be undone.',
            style: TextStyle(color: YaaroColors.muted, height: 1.35),
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: YaaroColors.rose),
              child: const Text('Unmatch',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () async {
                Navigator.pop(context);
                await _unmatch(match);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openProfile(String userId, String matchId) async {
    if (mounted) {
      setState(() => _message = '');
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<Map<String, dynamic>>(
              future: YaaroScope.of(context).getUserProfile(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: const BoxDecoration(
                      color: YaaroColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: YaaroColors.rose),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!['profile'] == null) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    decoration: const BoxDecoration(
                      color: YaaroColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          snapshot.error?.toString() ??
                              'Unable to open profile.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: YaaroColors.rose, fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }

                final profile =
                    snapshot.data!['profile'] as Map<String, dynamic>;
                final photos = profile['photos'] as List? ?? [];
                final displayName =
                    profile['displayName']?.toString() ?? 'Yaaro0 Member';
                final age = profile['age']?.toString();
                final city = profile['city']?.toString();
                final country = profile['country']?.toString();
                final distanceKm = profile['distanceKm']?.toString();
                final bio = profile['bio']?.toString() ??
                    profile['headline']?.toString() ??
                    'This profile is keeping things concise.';
                final compatibilityScore =
                    profile['compatibilityScore']?.toString() ?? '80';
                final isVerified = profile['isVerified'] == true;
                final sharedInterests =
                    (profile['sharedInterests'] as List? ?? [])
                        .map((i) => i.toString())
                        .toList();

                int photoIndex = 0;

                return Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: YaaroColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Stack(
                        children: [
                          ListView(
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 380,
                                    child: photos.isEmpty
                                        ? Container(
                                            color: YaaroColors.surfaceAlt,
                                            child: const Center(
                                              child: Icon(Icons.person,
                                                  size: 84,
                                                  color: Colors.white24),
                                            ),
                                          )
                                        : PageView.builder(
                                            itemCount: photos.length,
                                            onPageChanged: (idx) {
                                              setModalState(() {
                                                photoIndex = idx;
                                              });
                                            },
                                            itemBuilder: (context, idx) {
                                              final photo = photos[idx];
                                              final url =
                                                  photo['url']?.toString() ??
                                                      '';
                                              return Image.network(url,
                                                  fit: BoxFit.cover);
                                            },
                                          ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.05),
                                            Colors.black.withOpacity(0.05),
                                            Colors.black.withOpacity(0.65),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (photos.length > 1)
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          photos.length,
                                          (idx) => Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: idx == photoIndex
                                                  ? YaaroColors.rose
                                                  : Colors.white
                                                      .withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                age != null
                                                    ? '$displayName, $age'
                                                    : displayName,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                [city, country]
                                                        .whereType<String>()
                                                        .where(
                                                            (s) => s.isNotEmpty)
                                                        .join(', ')
                                                        .isNotEmpty
                                                    ? [city, country]
                                                        .whereType<String>()
                                                        .where(
                                                            (s) => s.isNotEmpty)
                                                        .join(', ')
                                                    : (distanceKm == null
                                                        ? 'Nearby'
                                                        : '$distanceKm km away'),
                                                style: const TextStyle(
                                                    color: YaaroColors.muted,
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: YaaroColors.teal,
                                                width: 2.5),
                                            color: YaaroColors.teal
                                                .withOpacity(0.08),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$compatibilityScore%',
                                              style: const TextStyle(
                                                color: YaaroColors.teal,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (isVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: YaaroColors.teal
                                              .withOpacity(0.12),
                                          border: Border.all(
                                              color: YaaroColors.teal
                                                  .withOpacity(0.24)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified,
                                                size: 14,
                                                color: YaaroColors.teal),
                                            SizedBox(width: 4),
                                            Text(
                                              'Verified',
                                              style: TextStyle(
                                                color: YaaroColors.teal,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Text(
                                      bio,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          color: Color(0xE6FFFFFF)),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text('Shared Interests',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: sharedInterests.isEmpty
                                          ? [
                                              const TagChip(
                                                  label:
                                                      'Discover more in chat'),
                                            ]
                                          : sharedInterests
                                              .map((interest) =>
                                                  TagChip(label: interest))
                                              .toList(),
                                    ),
                                    const SizedBox(height: 24),
                                    ..._buildProfileSections(profile),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              color: YaaroColors.surface.withOpacity(0.96),
                              child: Row(
                                children: [
                                  _profileActionIcon(
                                    icon: Icons.flag,
                                    label: 'Report',
                                    onPressed: () =>
                                        _handleReport(userId, displayName),
                                  ),
                                  const SizedBox(width: 10),
                                  _profileActionIcon(
                                    icon: Icons.block,
                                    label: 'Block',
                                    onPressed: () =>
                                        _handleBlock(userId, displayName),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: YaaroColors.rose,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: matchId.isNotEmpty
                                          ? () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatScreen(
                                                    matchId: matchId,
                                                    matchName: displayName,
                                                    matchPhotoUrl: photos
                                                            .isNotEmpty
                                                        ? photos.first['url']
                                                            ?.toString()
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.chat_bubble,
                                          size: 18),
                                      label: const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Message',
                                          maxLines: 1,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _profileActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: SizedBox(
        width: 56,
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: YaaroColors.line),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  List<Widget> _buildProfileSections(Map<String, dynamic> profile) {
    final List<Widget> widgets = [];
    final sections = [
      MapEntry('About', {
        'headline': profile['headline'],
        'pronouns': profile['pronouns'],
      }),
      MapEntry('Basics', profile['basics'] as Map<String, dynamic>?),
      MapEntry('Lifestyle', profile['lifestyle'] as Map<String, dynamic>?),
      MapEntry('Interests', profile['interests'] as Map<String, dynamic>?),
    ];

    for (final sec in sections) {
      final rows = _sectionRows(sec.value);
      if (rows.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sec.key,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.035),
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        _profileDetailRow(rows[i]),
                        if (i != rows.length - 1)
                          const Divider(height: 1, color: Colors.white10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _profileDetailRow(MapEntry<String, String> row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.key,
              style: const TextStyle(color: YaaroColors.muted, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBlock(String userId, String displayName) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: YaaroColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Block Member?',
              style: TextStyle(fontWeight: FontWeight.w900)),
          content: Text(
              'Are you sure you want to block $displayName? They will no longer be able to message you or view your profile.'),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: YaaroColors.rose),
              child: const Text('Block'),
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(this.context);
                try {
                  final api = YaaroScope.of(this.context);
                  await api.blockUser(userId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Blocked $displayName.'),
                      backgroundColor: YaaroColors.rose,
                    ),
                  );
                  _load();
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to block member.'),
                      backgroundColor: YaaroColors.rose,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleReport(String userId, String displayName) async {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: YaaroColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Report $displayName',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide details for your safety report:'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: YaaroColors.rose),
              child: const Text('Submit Report'),
              onPressed: () async {
                final details = textController.text.trim();
                if (details.isEmpty) return;
                Navigator.pop(context);
                Navigator.pop(this.context);
                try {
                  final api = YaaroScope.of(this.context);
                  await api.reportUser(userId, 'harassment', details);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Safety report submitted. Thank you.'),
                      backgroundColor: YaaroColors.teal,
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit report.'),
                      backgroundColor: YaaroColors.rose,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurredLikesSection() {
    return Container(
      height: 126,
      decoration: panelDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  3,
                  (index) => Container(
                        width: 72,
                        height: 96,
                        margin: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: const Center(
                          child: Icon(Icons.person,
                              color: Colors.white10, size: 36),
                        ),
                      )),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_likesCount people liked you',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: YaaroColors.rose,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          if (YaaroScope.of(context).user == null) {
                            widget.onOpenAuth();
                            return;
                          }
                          openMembershipScreen(context).then((_) => _load());
                        },
                        child: const Text(
                          'Upgrade to See',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikesList() {
    if (_likes.isEmpty) {
      return Container(
        height: 100,
        decoration: panelDecoration(),
        child: const Center(
          child: Text(
            'No likes yet. Keep swiping!',
            style: TextStyle(color: YaaroColors.muted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _likes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final like = _likes[index];
          return Container(
            width: 112,
            padding: const EdgeInsets.all(8),
            decoration: panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(like.userId, ''),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 72,
                      child: like.photoUrl != null
                          ? Image.network(like.photoUrl!, fit: BoxFit.cover)
                          : Container(
                              color: YaaroColors.surfaceAlt,
                              child: const Icon(Icons.person,
                                  color: Colors.white38),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  like.age != null ? '${like.name}, ${like.age}' : like.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: YaaroColors.rose,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.fromHeight(28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _likeBack(like.userId, like.name),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Like Back',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewMatchesSection() {
    final newMatches = _newMatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'New Matches', trailing: '${newMatches.length}'),
        const SizedBox(height: 10),
        if (newMatches.isEmpty)
          Container(
            height: 92,
            width: double.infinity,
            decoration: panelDecoration(),
            child: const Center(
              child: Text(
                'No new matches yet.',
                style: TextStyle(color: YaaroColors.muted),
              ),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newMatches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final match = newMatches[index];
                return GestureDetector(
                  onTap: () => _openProfile(match.userId, match.id),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: YaaroColors.surfaceAlt,
                        backgroundImage: match.photoUrl != null
                            ? NetworkImage(match.photoUrl!)
                            : null,
                        child: match.photoUrl == null
                            ? Text(
                                match.name
                                    .substring(
                                        0,
                                        match.name.length > 2
                                            ? 2
                                            : match.name.length)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white70),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMatches;

    return AppGradient(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: HeaderBar(
                title: 'Matches',
                actionLabel: YaaroScope.of(context).user == null ? 'Login' : '',
                onAction: widget.onOpenAuth,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                children: [
                  const Text(
                    'Start with the people who chose you back',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search Bar Input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: panelDecoration(),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _query = val;
                        });
                      },
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search,
                            color: YaaroColors.muted, size: 20),
                        hintText: 'Search matches',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (_message.isNotEmpty) StatusPill(text: _message),
                  const SizedBox(height: 18),

                  // Likes You Section
                  SectionTitle(title: 'Likes You', trailing: '$_likesCount'),
                  const SizedBox(height: 10),
                  _likesBlurred
                      ? _buildBlurredLikesSection()
                      : _buildLikesList(),
                  const SizedBox(height: 24),

                  // New Matches sub-row
                  _buildNewMatchesSection(),
                  const SizedBox(height: 24),

                  // Messages list
                  SectionTitle(
                      title: 'Messages', trailing: '${filtered.length} active'),
                  const SizedBox(height: 10),
                  if (!_loading && filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: panelDecoration(),
                      child: const Column(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 36, color: YaaroColors.muted),
                          SizedBox(height: 8),
                          Text('No matches yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Start swiping to find your match.',
                              style: TextStyle(
                                  color: YaaroColors.muted, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ...filtered.map(
                      (match) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchTile(
                          match: match,
                          onAvatarTap: () =>
                              _openProfile(match.userId, match.id),
                          onUnmatchTap: () => _showUnmatchConfirmation(match),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipPlan {
  const _MembershipPlan({
    required this.name,
    required this.tier,
    required this.price,
    required this.summary,
    required this.features,
    required this.icon,
    this.highlighted = false,
  });

  final String name;
  final String tier;
  final String price;
  final String summary;
  final List<String> features;
  final IconData icon;
  final bool highlighted;
}

const _membershipPlans = [
  _MembershipPlan(
    name: 'Free',
    tier: 'free',
    price: 'Rs 0',
    summary: 'Start matching with the core app.',
    icon: Icons.favorite_border,
    features: [
      'Limited daily likes',
      'One super like',
      'Blurred Likes You',
      'Basic discovery',
    ],
  ),
  _MembershipPlan(
    name: 'Standard',
    tier: 'plus',
    price: '\$9.99',
    summary: 'More control for serious daily use.',
    icon: Icons.bolt,
    features: [
      'Unlimited likes',
      'Rewind last swipe',
      'Passport location',
      'Incognito mode',
      'One boost every month',
    ],
  ),
  _MembershipPlan(
    name: 'Premium',
    tier: 'gold',
    price: '\$19.99',
    summary: 'Unlock the best matching signals.',
    icon: Icons.workspace_premium,
    highlighted: true,
    features: [
      'Everything in Standard',
      'See who liked you',
      'Daily top picks',
      'More super likes',
      'Monthly boost included',
    ],
  ),
];

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  SubscriptionStatus? _status;
  bool _loading = true;
  String _message = '';
  String? _busyTier;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final status = await YaaroScope.of(context).subscriptionStatus();
      if (mounted) {
        setState(() => _status = status);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message =
            e is ApiException ? e.message : 'Payments are unavailable.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startCheckout(_MembershipPlan plan) async {
    if (plan.tier == 'free') return;

    setState(() {
      _busyTier = plan.tier;
      _message = '';
    });
    try {
      final checkoutUrl =
          await YaaroScope.of(context).createCheckout(plan.tier);
      final opened = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw ApiException('Could not open checkout.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Complete checkout, then return to refresh your plan.'),
            backgroundColor: YaaroColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _message = e is ApiException ? e.message : 'Checkout failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _busyTier = null);
      }
    }
  }

  Future<void> _cancel() async {
    setState(() => _message = '');
    try {
      await YaaroScope.of(context).cancelSubscription();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription will cancel at the end of the period.'),
            backgroundColor: YaaroColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message =
            e is ApiException ? e.message : 'Could not cancel subscription.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Upgrade',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadStatus,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: panelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current plan',
                      style: TextStyle(
                          color: YaaroColors.muted,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loading
                                ? 'Checking...'
                                : status?.displayName ?? 'Free',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (status?.isPaid == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: YaaroColors.teal.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: YaaroColors.teal.withOpacity(0.34)),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                  color: YaaroColors.teal,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                    if (status?.endsAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        status!.cancelAtPeriodEnd
                            ? 'Cancels after ${status.endsAt!.toLocal().toString().split(' ').first}'
                            : 'Renews ${status.endsAt!.toLocal().toString().split(' ').first}',
                        style: const TextStyle(color: YaaroColors.muted),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Trial availability is controlled in Stripe or the app stores. Configure the trial there, then these plans can advertise and start it.',
                      style: TextStyle(color: YaaroColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 12),
                StatusPill(text: _message),
              ],
              const SizedBox(height: 18),
              ..._membershipPlans.map((plan) {
                final current = status?.tier == plan.tier ||
                    (status == null && plan.tier == 'free');
                final busy = _busyTier == plan.tier;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: YaaroColors.surface.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: plan.highlighted
                            ? YaaroColors.rose
                            : YaaroColors.line,
                        width: plan.highlighted ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(plan.icon,
                                color: plan.highlighted
                                    ? YaaroColors.rose
                                    : YaaroColors.teal),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                plan.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Text(
                              '${plan.price}/mo',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(plan.summary,
                            style: const TextStyle(color: YaaroColors.muted)),
                        const SizedBox(height: 12),
                        ...plan.features.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 16, color: YaaroColors.teal),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: current || busy
                              ? null
                              : () => _startCheckout(plan),
                          style: FilledButton.styleFrom(
                            backgroundColor: plan.highlighted
                                ? YaaroColors.rose
                                : YaaroColors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.white.withOpacity(0.10),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(current
                                  ? 'Current plan'
                                  : 'Start ${plan.name}'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (status?.isPaid == true &&
                  status?.cancelAtPeriodEnd != true) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: YaaroColors.line),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  label: const Text('Cancel renewal'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.onOpenAuth,
    required this.onLogout,
    super.key,
  });

  final VoidCallback onOpenAuth;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final api = YaaroScope.of(context);
    final user = api.user;

    return AppGradient(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            HeaderBar(
              title: 'Profile',
              actionLabel: user == null ? 'Login' : 'Logout',
              onAction: user == null ? widget.onOpenAuth : widget.onLogout,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: YaaroColors.rose,
                    child: Text(
                      user == null
                          ? 'Y0'
                          : user.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Build your Yaaro0 profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ??
                        'Add photos, intent, interests, and safety preferences from the connected API.',
                    style:
                        const TextStyle(color: YaaroColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  if (user == null)
                    FilledButton(
                      onPressed: widget.onOpenAuth,
                      style: FilledButton.styleFrom(
                          backgroundColor: YaaroColors.rose),
                      child: const Text('Login or create account'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingWizard(
                              mode: 'edit',
                              onComplete: () {
                                Navigator.pop(context);
                                setState(() {});
                              },
                              onLogout: () {
                                Navigator.pop(context);
                                widget.onLogout();
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      style: FilledButton.styleFrom(
                          backgroundColor: YaaroColors.rose),
                      label: const Text('Edit Profile'),
                    ),
                  if (user != null) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => openMembershipScreen(context),
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: YaaroColors.line),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      label: const Text('Upgrade & payments'),
                    ),
                  ],
                ],
              ),
            ),
            // const SizedBox(height: 18),
            // const SectionTitle(title: 'Readiness', trailing: 'Mobile'),
            // const SizedBox(height: 10),
            // const SettingsRow(
            //     icon: Icons.verified_user,
            //     title: 'Profile review',
            //     value: 'Ready'),
            // const SettingsRow(
            //     icon: Icons.security, title: 'Private by default', value: 'On'),
            // SettingsRow(
            //     icon: Icons.cloud_sync,
            //     title: 'API integration',
            //     value: apiBaseUrl),
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.profile, super.key});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: YaaroColors.surfaceAlt,
          border: Border.all(color: YaaroColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.42),
              blurRadius: 38,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
              Image.network(profile.photoUrl!, fit: BoxFit.cover)
            else
              Image.network(
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=70',
                fit: BoxFit.cover,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.84),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusPill(text: '${profile.compatibilityScore}% match'),
                  if (profile.isVerified)
                    const StatusPill(text: 'Verified', color: YaaroColors.teal),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.displayName}, ${profile.age}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 0.98,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(profile.location,
                      style: const TextStyle(color: YaaroColors.muted)),
                  const SizedBox(height: 8),
                  Text(profile.headline,
                      style: const TextStyle(fontSize: 16, height: 1.3)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.sharedInterests
                        .take(3)
                        .map((tag) => TagChip(label: tag))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactProfileTile extends StatelessWidget {
  const CompactProfileTile(
      {required this.profile,
      required this.onPass,
      required this.onLike,
      super.key});

  final DiscoveryProfile profile;
  final VoidCallback onPass;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: panelDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 82,
              height: 96,
              child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                  ? Image.network(
                      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=70',
                      fit: BoxFit.cover,
                    )
                  : Image.network(profile.photoUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.displayName}, ${profile.age}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.headline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: YaaroColors.muted),
                ),
                const SizedBox(height: 8),
                Text('${profile.compatibilityScore}% compatibility'),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onPass,
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: YaaroColors.line),
                ),
                icon: const Icon(Icons.close),
              ),
              IconButton.filled(
                onPressed: onLike,
                style: IconButton.styleFrom(backgroundColor: YaaroColors.rose),
                icon: const Icon(Icons.favorite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LikeTile extends StatelessWidget {
  const LikeTile({
    required this.like,
    required this.onTap,
    required this.onLikeBack,
    super.key,
  });

  final LikeItem like;
  final VoidCallback onTap;
  final VoidCallback onLikeBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(8),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 72,
                child: like.photoUrl != null && like.photoUrl!.isNotEmpty
                    ? Image.network(like.photoUrl!, fit: BoxFit.cover)
                    : Image.network(
                        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=70',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            like.age != null ? '${like.name}, ${like.age}' : like.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: YaaroColors.rose,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              minimumSize: const Size.fromHeight(28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onLikeBack,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Like Back',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchTile extends StatelessWidget {
  const MatchTile({
    required this.match,
    required this.onAvatarTap,
    required this.onUnmatchTap,
    super.key,
  });

  final MatchItem match;
  final VoidCallback onAvatarTap;
  final VoidCallback onUnmatchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: panelDecoration(),
      child: Row(
        children: [
          // Left: Interactive Avatar Tap
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: onAvatarTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: YaaroColors.surfaceAlt,
                      backgroundImage: match.photoUrl == null || match.photoUrl!.isEmpty
                          ? const NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=70')
                          : NetworkImage(match.photoUrl!),
                      child: null,
                    ),
                    if (match.unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                              color: YaaroColors.rose, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${match.unreadCount}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Middle: Interactive Row Body Tap -> Chat
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      matchId: match.id,
                      matchName: match.name,
                      matchPhotoUrl: match.photoUrl,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            match.age == null
                                ? match.name
                                : '${match.name}, ${match.age}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        if (match.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 16, color: YaaroColors.teal),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: YaaroColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right: Compatibility score & options menu
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (match.compatibilityScore > 0)
                  Text(
                    '${match.compatibilityScore}%',
                    style: const TextStyle(
                      color: YaaroColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: YaaroColors.muted, size: 20),
                  onPressed: onUnmatchTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final user = YaaroScope.of(context).user;

    return Row(
      children: [
        Image.asset(
          'assets/brand/logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        if (title != 'Yaaro0') ...[
          const SizedBox(width: 10),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        ],
        const Spacer(),
        if (user != null) ...[
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: YaaroColors.muted, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        if (actionLabel.isNotEmpty)
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class AppGradient extends StatelessWidget {
  const AppGradient({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark purple/indigo vertical gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF260D42), // Rich dark purple
                  Color(0xFF120524), // Deep indigo-violet
                  Color(0xFF06010B), // Midnight black-purple
                ],
              ),
            ),
          ),
        ),
        // Radial glow overlay at top-right (Magenta)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.8, -0.8),
                radius: 1.0,
                colors: [
                  Color(0x36FF4F6D), // Hot pink glow
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Radial glow overlay at bottom-left (Teal/Cyan)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, 0.8),
                radius: 1.2,
                colors: [
                  Color(0x2231D0B2), // Neon Teal glow
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Content child
        Positioned.fill(child: child),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.focusNode,
    this.hasError = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: hasError ? YaaroColors.rose : Colors.white54,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: hasError ? YaaroColors.rose : YaaroColors.rose.withOpacity(0.9),
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: hasError
            ? Colors.red.withOpacity(0.08)
            : Colors.white.withOpacity(0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? YaaroColors.rose : Colors.white.withOpacity(0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? YaaroColors.rose : Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? YaaroColors.rose : YaaroColors.rose.withOpacity(0.9),
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.text, this.color = Colors.white, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(color == Colors.white ? 0.11 : 0.18),
        border: Border.all(color: color.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class RoundAction extends StatelessWidget {
  const RoundAction({
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? YaaroColors.surface.withOpacity(0.45)
          : YaaroColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, required this.trailing, super.key});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        Text(trailing, style: const TextStyle(color: YaaroColors.muted)),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Row(
        children: [
          Icon(icon, color: YaaroColors.teal),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: YaaroColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                color: YaaroColors.saffron, size: 34),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: YaaroColors.muted)),
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

BoxDecoration panelDecoration() {
  return BoxDecoration(
    color: YaaroColors.surface.withOpacity(0.88),
    border: Border.all(color: YaaroColors.line),
    borderRadius: BorderRadius.circular(8),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<dynamic> _notifications = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final api = YaaroScope.of(context);
      final list = await api.getNotifications();
      setState(() {
        _notifications = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final api = YaaroScope.of(context);
      await api.markNotificationsAsRead();
      setState(() {
        _notifications = _notifications.map((item) {
          final n = Map<String, dynamic>.from(item as Map);
          n['read'] = true;
          return n;
        }).toList();
      });
    } catch (_) {
      // Silently handle
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final api = YaaroScope.of(context);
      await api.markNotificationAsRead(id);
      setState(() {
        _notifications = _notifications.map((item) {
          final n = Map<String, dynamic>.from(item as Map);
          if (n['id'] == id) {
            n['read'] = true;
          }
          return n;
        }).toList();
      });
    } catch (_) {
      // Silently handle
    }
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !(n['read'] as bool? ?? false));

    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: YaaroColors.muted, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (_notifications.isNotEmpty && hasUnread)
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: const Text(
                          'Mark all as read',
                          style: TextStyle(
                            color: YaaroColors.rose,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: YaaroColors.line, height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error,
                                    style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _loadNotifications,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _notifications.isEmpty
                            ? EmptyState(
                                title: 'All caught up!',
                                message: 'No new notifications to display right now.',
                                actionLabel: 'Refresh',
                                onAction: _loadNotifications,
                              )
                            : RefreshIndicator(
                                onRefresh: _loadNotifications,
                                color: YaaroColors.rose,
                                backgroundColor: YaaroColors.surface,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _notifications.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = _notifications[index];
                                    final id = item['id'] as String;
                                    final title = item['title'] as String? ?? '';
                                    final body = item['body'] as String? ?? '';
                                    final type = item['type'] as String? ?? '';
                                    final read = item['read'] as bool? ?? false;
                                    final createdAt =
                                        item['createdAt'] as String? ?? '';

                                    IconData icon;
                                    Color iconColor;
                                    switch (type) {
                                      case 'match':
                                        icon = Icons.people_alt;
                                        iconColor = YaaroColors.rose;
                                        break;
                                      case 'like':
                                        icon = Icons.favorite;
                                        iconColor = YaaroColors.saffron;
                                        break;
                                      case 'message':
                                        icon = Icons.chat_bubble;
                                        iconColor = YaaroColors.teal;
                                        break;
                                      default:
                                        icon = Icons.notifications;
                                        iconColor = YaaroColors.rose;
                                    }

                                    return InkWell(
                                      onTap: () {
                                        if (!read) {
                                          _markAsRead(id);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: panelDecoration().copyWith(
                                          color: read
                                              ? YaaroColors.surface.withOpacity(0.55)
                                              : YaaroColors.surfaceAlt.withOpacity(0.95),
                                          border: Border.all(
                                            color: read
                                                ? YaaroColors.line
                                                : YaaroColors.rose.withOpacity(0.4),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: iconColor.withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                icon,
                                                color: iconColor,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          title,
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight: read
                                                                ? FontWeight.w600
                                                                : FontWeight.w800,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!read)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: const BoxDecoration(
                                                            color: YaaroColors.rose,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    body,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: YaaroColors.muted,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    _formatTime(createdAt),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: read
                                                          ? YaaroColors.muted.withOpacity(0.6)
                                                          : YaaroColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExploreCategoryDetailScreen extends StatefulWidget {
  const ExploreCategoryDetailScreen({required this.category, super.key});

  final ExploreCategory category;

  @override
  State<ExploreCategoryDetailScreen> createState() =>
      _ExploreCategoryDetailScreenState();
}

class _ExploreCategoryDetailScreenState
    extends State<ExploreCategoryDetailScreen> {
  bool _loading = true;
  List<DiscoveryProfile> _allProfiles = [];
  List<DiscoveryProfile> _filteredProfiles = [];
  String _activeGoal = '';
  String _message = '';
  VibeQuestion? _vibeQuestion;
  bool _vibeLoading = false;
  List<DiscoveryProfile> _vibeProfiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final api = YaaroScope.of(context);
      final list = await api.exploreByInterest(widget.category.key);
      
      _vibeLoading = true;
      final q = await api.vibeToday();
      
      setState(() {
        _allProfiles = list;
        _vibeQuestion = q;
        _vibeProfiles = [];
        _applyFilter();
      });
      
      if (q != null && q.answer != null) {
        final vList = await api.respondToVibe(q.answer!);
        setState(() {
          _vibeProfiles = vList;
        });
      }
    } catch (_) {
      setState(() => _message = 'Unable to load this category.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _vibeLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_activeGoal.isEmpty) {
      _filteredProfiles = _allProfiles;
    } else {
      _filteredProfiles = _allProfiles
          .where((p) => p.relationshipGoal?.toLowerCase() == _activeGoal.toLowerCase())
          .toList();
    }
  }

  Future<void> _answerVibe(String answer) async {
    if (_vibeQuestion == null) return;
    setState(() => _vibeLoading = true);
    try {
      final list = await YaaroScope.of(context).respondToVibe(answer);
      setState(() {
        _vibeQuestion = VibeQuestion(
          id: _vibeQuestion!.id,
          prompt: _vibeQuestion!.prompt,
          answers: _vibeQuestion!.answers,
          answer: answer,
        );
        _vibeProfiles = list;
        _message = 'Vibe saved!';
      });
    } catch (_) {
      setState(() => _message = 'Failed to answer vibe.');
    } finally {
      if (mounted) {
        setState(() => _vibeLoading = false);
      }
    }
  }

  Future<void> _decide(DiscoveryProfile profile, SwipeAction action) async {
    setState(() {
      _allProfiles = _allProfiles.where((item) => item.id != profile.id).toList();
      _vibeProfiles = _vibeProfiles.where((item) => item.id != profile.id).toList();
      _applyFilter();
      _message = action == SwipeAction.like
          ? 'Liked ${profile.displayName}.'
          : 'Passed on ${profile.displayName}.';
    });

    try {
      final result = await YaaroScope.of(context).swipe(profile.id, action);
      if (result.matched) {
        setState(() => _message = "It's a match with ${profile.displayName}!");
      }
    } catch (_) {
      setState(() => _message = 'Action failed. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: YaaroColors.muted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Explore',
                    style: TextStyle(
                      color: YaaroColors.rose,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(widget.category.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text(
                    widget.category.label,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Browse shared interests, intent, nearby profiles, daily Vibes, and quick Hot Takes.',
                style: TextStyle(color: YaaroColors.muted, height: 1.35),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 14),
                StatusPill(text: _message),
              ],
              const SizedBox(height: 20),
              
              SectionTitle(
                title: 'People in this interest',
                trailing: _loading ? 'Loading' : 'Live',
              ),
              const SizedBox(height: 10),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Long-term', 'Casual', 'Friends', 'Not sure'].map((goal) {
                  final isSelected = _activeGoal.toLowerCase() == goal.toLowerCase();
                  return ChoiceChip(
                    label: Text(goal),
                    selected: isSelected,
                    selectedColor: YaaroColors.rose.withOpacity(0.26),
                    onSelected: (selected) {
                      setState(() {
                        _activeGoal = selected ? goal : '';
                        _applyFilter();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_filteredProfiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: panelDecoration(),
                  child: const Center(
                    child: Text(
                      'No profiles in this lane yet.',
                      style: TextStyle(color: YaaroColors.muted),
                    ),
                  ),
                )
              else
                ..._filteredProfiles.map((profile) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CompactProfileTile(
                    profile: profile,
                    onPass: () => _decide(profile, SwipeAction.pass),
                    onLike: () => _decide(profile, SwipeAction.like),
                  ),
                )),
                
              const SizedBox(height: 24),
              
              SectionTitle(
                title: 'Vibes',
                trailing: _vibeLoading ? 'Syncing' : 'Today',
              ),
              const SizedBox(height: 10),
              if (_vibeQuestion != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: panelDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vibeQuestion!.prompt,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _vibeQuestion!.answers
                            .map((answer) => ChoiceChip(
                                  label: Text(answer),
                                  selected: answer == _vibeQuestion!.answer,
                                  selectedColor: YaaroColors.teal.withOpacity(0.24),
                                  onSelected: (_) => _answerVibe(answer),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              if (_vibeProfiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._vibeProfiles.map((profile) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CompactProfileTile(
                    profile: profile,
                    onPass: () => _decide(profile, SwipeAction.pass),
                    onLike: () => _decide(profile, SwipeAction.like),
                  ),
                )),
              ],
              
              const SizedBox(height: 24),
              
              const SectionTitle(
                title: 'Hot Takes',
                trailing: 'Soon',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: panelDecoration(),
                child: const Text(
                  '30-second text dates are warming up. This speed chat lane is coming soon.',
                  style: TextStyle(color: YaaroColors.muted, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
