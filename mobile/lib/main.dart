import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api_client.dart';
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
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      emailVerified: json['emailVerified'] == true,
      onboardingCompleted: json['onboardingCompleted'] == true,
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
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.preview,
    required this.unreadCount,
    required this.compatibilityScore,
    required this.isVerified,
  });

  final String id;
  final String name;
  final int? age;
  final String? photoUrl;
  final String preview;
  final int unreadCount;
  final int compatibilityScore;
  final bool isVerified;

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map<String, dynamic>
        ? json['lastMessage'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MatchItem(
      id: json['id']?.toString() ?? '',
      name: user['displayName']?.toString() ?? 'Match',
      age: int.tryParse(user['age']?.toString() ?? ''),
      photoUrl: user['mainPhotoUrl']?.toString(),
      preview: lastMessage['preview']?.toString() ?? 'Start the conversation.',
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
      compatibilityScore:
          int.tryParse(json['compatibilityScore']?.toString() ?? '') ?? 82,
      isVerified: user['isVerified'] == true,
    );
  }
}

class LikeItem {
  const LikeItem({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.action,
    required this.isVerified,
  });

  final String id;
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
      name: user['displayName']?.toString() ?? 'Someone new',
      age: int.tryParse(user['age']?.toString() ?? ''),
      photoUrl: user['mainPhotoUrl']?.toString(),
      action: json['action']?.toString() ?? 'like',
      isVerified: user['isVerified'] == true,
    );
  }
}

final demoProfiles = [
  const DiscoveryProfile(
    id: 'demo-aaravi',
    displayName: 'Aaravi',
    age: 26,
    city: 'Colombo',
    country: 'Sri Lanka',
    headline: 'Values-led, curious, weekend cafe hunter.',
    photoUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=82',
    compatibilityScore: 92,
    distanceKm: 4,
    isVerified: true,
    sharedInterests: ['Tamil music', 'Food walks', 'Family values'],
    bio: 'Looking for honest conversation, shared rituals, and a little spark.',
    relationshipGoal: 'Long-term',
    loveLanguage: 'Quality time',
  ),
  const DiscoveryProfile(
    id: 'demo-naveen',
    displayName: 'Naveen',
    age: 29,
    city: 'Toronto',
    country: 'Canada',
    headline: 'Engineer, dosa loyalist, long-term minded.',
    photoUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=82',
    compatibilityScore: 88,
    distanceKm: null,
    isVerified: true,
    sharedInterests: ['Travel', 'Fitness', 'Tamil cinema'],
    bio: 'Here for a connection that can move from chat to real life.',
    relationshipGoal: 'Long-term',
    loveLanguage: 'Acts of service',
  ),
  const DiscoveryProfile(
    id: 'demo-maya',
    displayName: 'Maya',
    age: 25,
    city: 'London',
    country: 'United Kingdom',
    headline: 'Creative, grounded, and serious about kindness.',
    photoUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=82',
    compatibilityScore: 85,
    distanceKm: 12,
    isVerified: false,
    sharedInterests: ['Art', 'Brunch', 'Books'],
    bio: 'Ask me about the last film that made me rethink everything.',
    relationshipGoal: 'Friends',
    loveLanguage: 'Words of affirmation',
  ),
];

final demoCategories = [
  const ExploreCategory(
      key: 'music', label: 'Tamil music', count: 28, emoji: '♪'),
  const ExploreCategory(
      key: 'food', label: 'Food lovers', count: 42, emoji: '◐'),
  const ExploreCategory(
      key: 'faith', label: 'Shared values', count: 19, emoji: '✦'),
  const ExploreCategory(
      key: 'travel', label: 'Travel plans', count: 31, emoji: '⌁'),
];

final demoMatches = [
  const MatchItem(
    id: 'match-aaravi',
    name: 'Aaravi',
    age: 26,
    photoUrl:
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=82',
    preview: 'That coffee place looks perfect.',
    unreadCount: 2,
    compatibilityScore: 92,
    isVerified: true,
  ),
  const MatchItem(
    id: 'match-kavin',
    name: 'Kavin',
    age: 31,
    photoUrl:
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=500&q=82',
    preview: 'Voice note received.',
    unreadCount: 0,
    compatibilityScore: 81,
    isVerified: true,
  ),
];

final demoLikes = [
  const LikeItem(
    id: 'like-maya',
    name: 'Maya',
    age: 25,
    photoUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=500&q=82',
    action: 'superlike',
    isVerified: false,
  ),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  bool _showLanding = true;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final api = YaaroScope.of(context);
    final user = api.user;

    if (_showLanding && user == null) {
      return LandingScreen(
        onLogin: () => _openAuth(),
        onCreateAccount: () => _openAuth(createAccount: true),
        onPreviewApp: () => setState(() => _showLanding = false),
      );
    }

    if (user != null && !user.onboardingCompleted) {
      return OnboardingWizard(
        onComplete: () {
          setState(() {
            // Re-render and navigate into the main app tabs once onboarding is completed
          });
        },
        onLogout: () async {
          await api.logout();
          setState(() {
            _showLanding = true;
          });
        },
      );
    }

    final screens = [
      DiscoverScreen(onOpenAuth: _openAuth),
      ExploreScreen(onOpenAuth: _openAuth),
      MatchesScreen(onOpenAuth: _openAuth),
      ProfileScreen(onOpenAuth: _openAuth),
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
    required this.onPreviewApp,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;
  final VoidCallback onPreviewApp;

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
                    name: 'Aaravi',
                    imageUrl:
                        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=82',
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 156,
                child: Transform.rotate(
                  angle: -0.12,
                  child: const _LandingPreviewCard(
                    name: 'Naveen',
                    imageUrl:
                        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=82',
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [YaaroColors.rose, YaaroColors.teal],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Yaaro0',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
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
                        TextButton(
                          onPressed: onPreviewApp,
                          child: const Text('Preview the mobile app'),
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
    required this.name,
    required this.imageUrl,
  });

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: Container(
        width: 148,
        height: 198,
        decoration: BoxDecoration(
          color: YaaroColors.surfaceAlt,
          border: Border.all(color: YaaroColors.line),
          borderRadius: BorderRadius.circular(8),
          image:
              DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(10),
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
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
  List<DiscoveryProfile> _profiles = demoProfiles;
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
      if (cards.isNotEmpty) {
        setState(() {
          _profiles = cards;
          _message = '';
        });
      }
    } catch (_) {
      setState(
          () => _message = 'Showing demo profiles until the API is available.');
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
                  actionLabel: 'Login',
                  onAction: widget.onOpenAuth),
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
              const SizedBox(height: 14),
              _buildActions(),
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
                                    : _drag.dy < -120
                                        ? SwipeAction.superlike
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
            icon: Icons.star,
            color: YaaroColors.teal,
            onPressed: _swiping ? null : () => _swipe(SwipeAction.superlike)),
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
    if (profile == null) {
      return;
    }

    setState(() {
      _swiping = true;
      _profiles = _profiles.skip(1).toList();
      _drag = Offset.zero;
    });

    try {
      final result = await YaaroScope.of(context).swipe(profile.id, action);
      if (result.matched) {
        setState(() => _message = "It's a match with ${profile.displayName}.");
      } else if (action == SwipeAction.like ||
          action == SwipeAction.superlike) {
        setState(() => _message =
            'Sent ${action == SwipeAction.superlike ? 'a superlike' : 'a like'} to ${profile.displayName}.');
      }
    } catch (_) {
      if (profile.id.startsWith('demo-')) {
        return;
      }
      setState(() {
        _profiles = [profile, ..._profiles];
        _message = 'Could not send that swipe. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _swiping = false);
      }
    }
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
  List<ExploreCategory> _categories = demoCategories;
  List<DiscoveryProfile> _profiles = demoProfiles;
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
      setState(() => _message = 'Explore is using local preview data.');
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
                actionLabel: 'Login',
                onAction: widget.onOpenAuth),
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
                        'Your perfect Sunday starts with...',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_vibeQuestion?.answers.isNotEmpty == true
                            ? _vibeQuestion!.answers
                            : [
                                'Family lunch',
                                'A long drive',
                                'Temple and tea',
                                'Movie night'
                              ])
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
            const SizedBox(height: 22),
            SectionTitle(
                title: 'Interests', trailing: '${_categories.length} groups'),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isActive = category.key == _activeInterest;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _loadByInterest(category),
                    child: Container(
                      width: 148,
                      padding: const EdgeInsets.all(14),
                      decoration: panelDecoration().copyWith(
                        border: Border.all(
                          color: isActive ? YaaroColors.rose : YaaroColors.line,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category.emoji,
                              style: const TextStyle(fontSize: 18)),
                          Text(category.label,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
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

  Future<void> _loadByInterest(ExploreCategory category) async {
    setState(() {
      _profilesLoading = true;
      _activeGoal = '';
      _activeInterest = category.key;
    });
    try {
      final profiles =
          await YaaroScope.of(context).exploreByInterest(category.key);
      setState(() {
        _profiles = profiles;
        _message = '';
      });
    } catch (_) {
      setState(() => _message = 'No profiles found for ${category.label} yet.');
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

    if (!profile.id.startsWith('demo-')) {
      try {
        final result = await YaaroScope.of(context).swipe(profile.id, action);
        if (result.matched) {
          setState(
              () => _message = "It's a match with ${profile.displayName}.");
        }
      } catch (_) {
        setState(() => _message = 'Action failed. Try again.');
      }
    }
  }
}

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({required this.onOpenAuth, super.key});

  final VoidCallback onOpenAuth;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchItem> _matches = demoMatches;
  List<LikeItem> _likes = demoLikes;
  String _message = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = YaaroScope.of(context);
      final results = await Future.wait<dynamic>([
        api.matches(),
        api.likesReceived(),
      ]);
      setState(() {
        _matches = results[0] as List<MatchItem>;
        _likes = results[1] as List<LikeItem>;
        _message = '';
      });
    } catch (_) {
      setState(
          () => _message = 'Showing saved match previews until you connect.');
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
                title: 'Matches',
                actionLabel: 'Login',
                onAction: widget.onOpenAuth),
            const SizedBox(height: 18),
            Text(
              'Start with the people who chose you back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
            const SizedBox(height: 14),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_message.isNotEmpty) StatusPill(text: _message),
            const SizedBox(height: 18),
            SectionTitle(title: 'Likes you', trailing: '${_likes.length} new'),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _likes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => LikeTile(like: _likes[index]),
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(
                title: 'Messages', trailing: '${_matches.length} active'),
            const SizedBox(height: 10),
            ..._matches.map(
              (match) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchTile(match: match),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.onOpenAuth, super.key});

  final VoidCallback onOpenAuth;

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
              onAction: user == null
                  ? widget.onOpenAuth
                  : () {
                      api.logout();
                      setState(() {});
                    },
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
                  FilledButton(
                    onPressed: user == null ? widget.onOpenAuth : null,
                    style: FilledButton.styleFrom(
                        backgroundColor: YaaroColors.rose),
                    child: Text(
                        user == null ? 'Login or create account' : 'Signed in'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Readiness', trailing: 'Mobile'),
            const SizedBox(height: 10),
            const SettingsRow(
                icon: Icons.verified_user,
                title: 'Profile review',
                value: 'Ready'),
            const SettingsRow(
                icon: Icons.security, title: 'Private by default', value: 'On'),
            SettingsRow(
                icon: Icons.cloud_sync,
                title: 'API integration',
                value: apiBaseUrl),
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
            if (profile.photoUrl != null)
              Image.network(profile.photoUrl!, fit: BoxFit.cover)
            else
              const ColoredBox(color: YaaroColors.surfaceAlt),
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
              child: profile.photoUrl == null
                  ? const ColoredBox(color: YaaroColors.surfaceAlt)
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
  const LikeTile({required this.like, super.key});

  final LikeItem like;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(10),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: YaaroColors.surfaceAlt,
                backgroundImage:
                    like.photoUrl == null ? null : NetworkImage(like.photoUrl!),
                child: like.photoUrl == null
                    ? Text(like.name.characters.first)
                    : null,
              ),
              if (like.action == 'superlike')
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.star, color: YaaroColors.teal, size: 18),
                ),
            ],
          ),
          const Spacer(),
          Text(
            like.age == null ? like.name : '${like.name}, ${like.age}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            like.action == 'superlike' ? 'Super liked you' : 'Liked you',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: YaaroColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class MatchTile extends StatelessWidget {
  const MatchTile({required this.match, super.key});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: panelDecoration(),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: YaaroColors.surfaceAlt,
                  backgroundImage: match.photoUrl == null
                      ? null
                      : NetworkImage(match.photoUrl!),
                  child: match.photoUrl == null
                      ? Text(match.name.characters.first)
                      : null,
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
                              fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  Text(match.preview,
                      style: const TextStyle(color: YaaroColors.muted)),
                ],
              ),
            ),
            Text('${match.compatibilityScore}%'),
          ],
        ),
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [YaaroColors.rose, YaaroColors.saffron]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('Y',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        const Spacer(),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 0.95,
          colors: [Color(0x45FF4F6D), YaaroColors.black],
          stops: [0, 0.62],
        ),
      ),
      child: child,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
