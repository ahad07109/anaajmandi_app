import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String supabaseUrl =
    'https://lebmrjudwrmgqatmmbuz.supabase.co';

const String supabaseAnonKey =
    'sb_publishable_c4qeCAF8OCKRUcqXphm97w_UKr-MoD5';

const Color mandiGreen = Color(0xFF167A3A);
const Color darkGreen = Color(0xFF123D27);
const Color mandiGold = Color(0xFFF2A900);
const Color cream = Color(0xFFF8F7F2);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language') ?? 'en';

  runApp(
    AnaajMandiApp(
      initialLanguage: savedLanguage,
    ),
  );
}

// =====================================================
// LANGUAGE CONTROLLER
// =====================================================

class LanguageController extends ChangeNotifier {
  String language;

  LanguageController(this.language);

  bool get isUrdu => language == 'ur';

  String tr(String english, String urdu) {
    return isUrdu ? urdu : english;
  }

  Future<void> changeLanguage(String value) async {
    if (language == value) return;

    language = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);

    notifyListeners();
  }
}

class LanguageScope
    extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<
            LanguageScope>();

    assert(scope != null, 'LanguageScope not found');

    return scope!.notifier!;
  }
}

// =====================================================
// APP
// =====================================================

class AnaajMandiApp extends StatefulWidget {
  final String initialLanguage;

  const AnaajMandiApp({
    super.key,
    required this.initialLanguage,
  });

  @override
  State<AnaajMandiApp> createState() =>
      _AnaajMandiAppState();
}

class _AnaajMandiAppState extends State<AnaajMandiApp> {
  late final LanguageController languageController;

  @override
  void initState() {
    super.initState();

    languageController =
        LanguageController(widget.initialLanguage);
  }

  @override
  void dispose() {
    languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: languageController,
      child: AnimatedBuilder(
        animation: languageController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Anaaj Mandi',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: mandiGreen,
              ),
              scaffoldBackgroundColor: cream,
            ),
            builder: (context, child) {
              return Directionality(
                textDirection:
                    languageController.isUrdu
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                child: child!,
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// =====================================================
// LANGUAGE PILL
// =====================================================

class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF39764E),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageButton(
              text: 'EN',
              selected: !lang.isUrdu,
              onTap: () => lang.changeLanguage('en'),
            ),
            _languageButton(
              text: 'اردو',
              selected: lang.isUrdu,
              onTap: () => lang.changeLanguage('ur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color:
                selected ? mandiGold : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            style: TextStyle(
              color:
                  selected ? darkGreen : Colors.white,
              fontSize: text == 'EN' ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// COMMON APP BAR
// =====================================================

class AnaajAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;

  const AnaajAppBar({
    super.key,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: cream,
      surfaceTintColor: Colors.transparent,
      title: title == null
          ? null
          : Text(
              title!,
              style: const TextStyle(
                color: darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
      actions: const [
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: 12,
          ),
          child: Center(
            child: LanguagePill(),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// SPLASH SCREEN (WITH SESSION CHECK)
// =====================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;
      final phone =
          await _getStoredPhone();

      if (phone != null && phone.isNotEmpty) {
        // User exists — go to home
        final response = await supabase
            .from('users')
            .select()
            .eq('phone', phone)
            .single();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: response['name'],
              role:
                  _getRoleFromId(response['role']),
            ),
          ),
        );
      } else {
        // New user — go to welcome
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const WelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      // No user found — go to welcome
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
      );
    }
  }

  Future<String?> _getStoredPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mandiGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/anaaj_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 25),
              const Text(
                'Anaaj Mandi',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pakistan Agricultural Marketplace',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: mandiGold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// WELCOME SCREEN
// =====================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            18,
            24,
            28,
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: LanguagePill(),
              ),
              const Spacer(),
              Image.asset(
                'assets/anaaj_logo.png',
                width: 125,
                height: 125,
              ),
              const SizedBox(height: 25),
              Text(
                lang.tr(
                  'Welcome to Anaaj Mandi',
                  'اناج منڈی میں خوش آمدید',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lang.tr(
                  'Pakistan\'s Agricultural Marketplace',
                  'پاکستان کی زرعی منڈی',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF69736C),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              MainButton(
                text: lang.tr(
                  'Create New Account',
                  'نیا اکاؤنٹ بنائیں',
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PhoneScreen(
                        isRegistering: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PhoneScreen(
                          isRegistering: false,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: mandiGreen,
                    side: const BorderSide(
                      color: mandiGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    lang.tr(
                      'Login',
                      'لاگ اِن',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lang.tr(
                  'Buy • Sell • Trade • Grow',
                  'خریدیں • بیچیں • تجارت کریں • ترقی کریں',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF858E88),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PHONE SCREEN (OTP + SAVE TO SUPABASE)
// =====================================================

class PhoneScreen extends StatefulWidget {
  final bool isRegistering;

  const PhoneScreen({
    super.key,
    required this.isRegistering,
  });

  @override
  State<PhoneScreen> createState() =>
      _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool showOTP = false;
  bool isLoading = false;

  void _sendOTP() {
    final lang = LanguageScope.of(context);

    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Please enter your WhatsApp number.',
              'براہ کرم اپنا واٹس ایپ نمبر درج کریں۔',
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      showOTP = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.tr(
            'Development mode: use OTP 123456',
            'ڈیولپمنٹ موڈ: او ٹی پی 123456 استعمال کریں',
          ),
        ),
      ),
    );
  }

  void _verifyOTP() async {
    final lang = LanguageScope.of(context);

    if (otpController.text.trim() != '123456') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Incorrect OTP. For now use 123456.',
              'غلط او ٹی پی۔ فی الحال 123456 استعمال کریں۔',
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final phone = phoneController.text.trim();

      if (widget.isRegistering) {
        // Create new user in Supabase
        await supabase.from('users').insert({
          'phone': phone,
          'name': '',
          'role': '',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Save phone to SharedPreferences
      final prefs =
          await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (widget.isRegistering) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NameScreen(phone: phone),
          ),
        );
      } else {
        String? savedName;
        UserRole? savedRole;

        try {
          final existing = await supabase
              .from('users')
              .select()
              .eq('phone', phone)
              .maybeSingle();

          if (existing != null) {
            final storedName =
                existing['name']?.toString().trim() ?? '';

            if (storedName.isNotEmpty) {
              savedName = storedName;
            }

            savedRole = _getRoleFromId(
              existing['role']?.toString(),
            );
          }
        } catch (_) {}

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: savedName,
              role: savedRole,
            ),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Error: ${e.toString()}',
              'خرابی: ${e.toString()}',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Scaffold(
      appBar: const AnaajAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            15,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/anaaj_logo.png',
                  width: 82,
                  height: 82,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                widget.isRegistering
                    ? lang.tr(
                        'Create your account',
                        'اپنا اکاؤنٹ بنائیں',
                      )
                    : lang.tr(
                        'Welcome back',
                        'دوبارہ خوش آمدید',
                      ),
                style: const TextStyle(
                  color: darkGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                showOTP
                    ? lang.tr(
                        'Enter the verification code sent to your WhatsApp.',
                        'اپنے واٹس ایپ پر بھیجا گیا تصدیقی کوڈ درج کریں۔',
                      )
                    : lang.tr(
                        'Enter your WhatsApp number to continue.',
                        'جاری رکھنے کے لیے اپنا واٹس ایپ نمبر درج کریں۔',
                      ),
                style: const TextStyle(
                  color: Color(0xFF69736C),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              if (!showOTP) ...[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: lang.tr(
                        'WhatsApp Number',
                        'واٹس ایپ نمبر',
                      ),
                      hintText: '+92 3XX XXXXXXX',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: mandiGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                MainButton(
                  text: lang.tr(
                    'Send OTP on WhatsApp',
                    'واٹس ایپ پر او ٹی پی بھیجیں',
                  ),
                  onPressed: _sendOTP,
                ),
              ] else ...[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: otpController,
                    keyboardType:
                        TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: lang.tr(
                        'Verification Code',
                        'تصدیقی کوڈ',
                      ),
                      hintText: '123456',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: mandiGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                MainButton(
                  text: isLoading
                      ? lang.tr(
                          'Verifying...',
                          'تصدیق جاری ہے...',
                        )
                      : lang.tr(
                          'Verify & Continue',
                          'تصدیق کریں اور آگے بڑھیں',
                        ),
                  onPressed:
                      isLoading ? () {} : _verifyOTP,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showOTP = false;
                        otpController.clear();
                      });
                    },
                    child: Text(
                      lang.tr(
                        'Change WhatsApp number',
                        'واٹس ایپ نمبر تبدیل کریں',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }
}

// =====================================================
// NAME SCREEN (SAVE TO SUPABASE)
// =====================================================

class NameScreen extends StatefulWidget {
  final String phone;

  const NameScreen({
    super.key,
    required this.phone,
  });

  @override
  State<NameScreen> createState() =>
      _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final nameController = TextEditingController();
  bool isLoading = false;

  void _continue() async {
    final lang = LanguageScope.of(context);

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Please enter your name.',
              'براہ کرم اپنا نام درج کریں۔',
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final name = nameController.text.trim();

      // Update user in Supabase
      await supabase
          .from('users')
          .update({'name': name}).eq('phone', widget.phone);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleScreen(
            phone: widget.phone,
            userName: name,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr(
            'Error saving name',
            'نام محفوظ کرنے میں خرابی',
          )),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Scaffold(
      appBar: AnaajAppBar(
        title: lang.tr(
          'Create Profile',
          'پروفائل بنائیں',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Text(
              lang.tr(
                'What should we call you?',
                'آپ کا نام کیا ہے؟',
              ),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lang.tr(
                'Start with just your basic information. You can complete your profile later.',
                'ابھی صرف بنیادی معلومات درج کریں۔ باقی پروفائل آپ بعد میں مکمل کر سکتے ہیں۔',
              ),
              style: const TextStyle(
                color: Color(0xFF69736C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: nameController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: lang.tr(
                  'Full Name',
                  'پورا نام',
                ),
                prefixIcon:
                    const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: mandiGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            MainButton(
              text: isLoading
                  ? lang.tr(
                      'Saving...',
                      'محفوظ ہو رہا ہے...',
                    )
                  : lang.tr(
                      'Continue',
                      'آگے بڑھیں',
                    ),
              onPressed: isLoading ? () {} : _continue,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}

// =====================================================
// ROLE MODEL
// =====================================================

class UserRole {
  final String id;
  final String emoji;
  final String englishName;
  final String urduName;
  final String englishDescription;
  final String urduDescription;

  const UserRole({
    required this.id,
    required this.emoji,
    required this.englishName,
    required this.urduName,
    required this.englishDescription,
    required this.urduDescription,
  });
}

const List<UserRole> availableRoles = [
  UserRole(
    id: 'farmer',
    emoji: '🌾',
    englishName: 'Farmer',
    urduName: 'کسان',
    englishDescription:
        'Grow and sell crops',
    urduDescription:
        'فصل اگائیں اور فروخت کریں',
  ),
  UserRole(
    id: 'arhti',
    emoji: '🏪',
    englishName: 'Mandi / Arhti',
    urduName: 'منڈی / آڑھتی',
    englishDescription:
        'Buy and sell in the mandi',
    urduDescription:
        'منڈی میں خرید و فروخت کریں',
  ),
  UserRole(
    id: 'trader',
    emoji: '🤝',
    englishName: 'Crop Trader',
    urduName: 'فصل کا تاجر',
    englishDescription:
        'Trade agricultural commodities',
    urduDescription:
        'زرعی اجناس کی تجارت کریں',
  ),
  UserRole(
    id: 'buyer',
    emoji: '🏭',
    englishName: 'Buyer / Mill / Exporter',
    urduName: 'خریدار / مل / برآمد کنندہ',
    englishDescription:
        'Purchase agricultural produce',
    urduDescription:
        'زرعی پیداوار خریدیں',
  ),
  UserRole(
    id: 'machinery',
    emoji: '🚜',
    englishName: 'Machinery',
    urduName: 'زرعی مشینری',
    englishDescription:
        'Buy, sell or rent machinery',
    urduDescription:
        'مشینری خریدیں، بیچیں یا کرائے پر دیں',
  ),
  UserRole(
    id: 'transport',
    emoji: '🚛',
    englishName: 'Transport',
    urduName: 'ٹرانسپورٹ',
    englishDescription:
        'Provide agricultural transport',
    urduDescription:
        'زرعی ٹرانسپورٹ فراہم کریں',
  ),
  UserRole(
    id: 'land',
    emoji: '🏡',
    englishName: 'Agricultural Land',
    urduName: 'زرعی زمین',
    englishDescription:
        'Lease or offer agricultural land',
    urduDescription:
        'زرعی زمین کرائے پر لیں یا دیں',
  ),
];

// =====================================================
// ROLE SCREEN (SAVE TO SUPABASE)
// =====================================================

class RoleScreen extends StatefulWidget {
  final String phone;
  final String userName;

  const RoleScreen({
    super.key,
    required this.phone,
    required this.userName,
  });

  @override
  State<RoleScreen> createState() =>
      _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String? selectedRoleId;

  void _continue() async {
    final lang = LanguageScope.of(context);

    if (selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Please select your field.',
              'براہ کرم اپنا شعبہ منتخب کریں۔',
            ),
          ),
        ),
      );

      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // Update user role in Supabase
      await supabase
          .from('users')
          .update({'role': selectedRoleId})
          .eq('phone', widget.phone);

      if (!mounted) return;

      final role = availableRoles.firstWhere(
        (item) => item.id == selectedRoleId,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BasicInfoScreen(
            phone: widget.phone,
            userName: widget.userName,
            role: role,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr(
            'Error saving role',
            'شعبہ محفوظ کرنے میں خرابی',
          )),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Scaffold(
      appBar: AnaajAppBar(
        title: lang.tr(
          'Your Field',
          'آپ کا شعبہ',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16,
            ),
            child: Align(
              alignment:
                  AlignmentDirectional.centerStart,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.tr(
                      'What do you do?',
                      'آپ کیا کام کرتے ہیں؟',
                    ),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.tr(
                      'Choose the option that best describes you.',
                      'وہ آپشن منتخب کریں جو آپ کے کام کو بہتر بیان کرتا ہو۔',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF69736C),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              itemCount: availableRoles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final role = availableRoles[index];

                final selected =
                    selectedRoleId == role.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedRoleId = role.id;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(17),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE8F3EB)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(17),
                      border: Border.all(
                        color: selected
                            ? mandiGreen
                            : const Color(0xFFE5E9E6),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF4F7F4),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Text(
                            role.emoji,
                            style: const TextStyle(
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.isUrdu
                                    ? role.urduName
                                    : role.englishName,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: darkGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang.isUrdu
                                    ? role.urduDescription
                                    : role
                                        .englishDescription,
                                style:
                                    const TextStyle(
                                  fontSize: 13,
                                  color:
                                      Color(0xFF737B76),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: mandiGreen,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MainButton(
              text: lang.tr(
                'Continue',
                'آگے بڑھیں',
              ),
              onPressed: _continue,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// BASIC FIELD INFORMATION (SAVE TO SUPABASE)
// =====================================================

class BasicInfoScreen extends StatefulWidget {
  final String phone;
  final String userName;
  final UserRole role;

  const BasicInfoScreen({
    super.key,
    required this.phone,
    required this.userName,
    required this.role,
  });

  @override
  State<BasicInfoScreen> createState() =>
      _BasicInfoScreenState();
}

class _BasicInfoScreenState
    extends State<BasicInfoScreen> {
  final cityController = TextEditingController();
  final fieldController = TextEditingController();
  bool isLoading = false;

  String _fieldEnglishLabel() {
    switch (widget.role.id) {
      case 'farmer':
        return 'Main Crop';

      case 'arhti':
        return 'Mandi / Shop Name';

      case 'trader':
        return 'Main Crop You Trade';

      case 'buyer':
        return 'Business / Mill Name';

      case 'machinery':
        return 'Machinery Type';

      case 'transport':
        return 'Vehicle Type';

      case 'land':
        return 'Land Interest';

      default:
        return 'Business Information';
    }
  }

  String _fieldUrduLabel() {
    switch (widget.role.id) {
      case 'farmer':
        return 'اہم فصل';

      case 'arhti':
        return 'منڈی / دکان کا نام';

      case 'trader':
        return 'اہم فصل جس کی تجارت کرتے ہیں';

      case 'buyer':
        return 'کاروبار / مل کا نام';

      case 'machinery':
        return 'مشینری کی قسم';

      case 'transport':
        return 'گاڑی کی قسم';

      case 'land':
        return 'زمین سے متعلق دلچسپی';

      default:
        return 'کاروباری معلومات';
    }
  }

  IconData _fieldIcon() {
    switch (widget.role.id) {
      case 'farmer':
      case 'trader':
        return Icons.grass_outlined;

      case 'arhti':
        return Icons.storefront_outlined;

      case 'buyer':
        return Icons.business_outlined;

      case 'machinery':
        return Icons.agriculture_outlined;

      case 'transport':
        return Icons.local_shipping_outlined;

      case 'land':
        return Icons.landscape_outlined;

      default:
        return Icons.info_outline;
    }
  }

  void _finish() async {
    final lang = LanguageScope.of(context);

    if (cityController.text.trim().isEmpty ||
        fieldController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.tr(
              'Please complete the basic information.',
              'براہ کرم بنیادی معلومات مکمل کریں۔',
            ),
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Update user location and field in Supabase
      await supabase.from('users').update({
        'location': cityController.text.trim(),
        'field': fieldController.text.trim(),
      }).eq('phone', widget.phone);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: widget.userName,
            role: widget.role,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr(
            'Error saving information',
            'معلومات محفوظ کرنے میں خرابی',
          )),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    return Scaffold(
      appBar: AnaajAppBar(
        title: lang.tr(
          'Basic Information',
          'بنیادی معلومات',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EB),
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text(
                    widget.role.emoji,
                    style:
                        const TextStyle(fontSize: 35),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr(
                            'Selected Field',
                            'منتخب شعبہ',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF69736C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lang.isUrdu
                              ? widget.role.urduName
                              : widget
                                  .role.englishName,
                          style: const TextStyle(
                            color: darkGreen,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              lang.tr(
                'Just a little more...',
                'بس تھوڑی سی مزید معلومات...',
              ),
              style: const TextStyle(
                color: darkGreen,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.tr(
                'Keep it simple. You can add more details to your profile later.',
                'صرف بنیادی معلومات دیں۔ مزید تفصیلات آپ بعد میں پروفائل میں شامل کر سکتے ہیں۔',
              ),
              style: const TextStyle(
                color: Color(0xFF69736C),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: cityController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: lang.tr(
                  'City / District',
                  'شہر / ضلع',
                ),
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: mandiGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fieldController,
              textCapitalization:
                  TextCapitalization.words,
              decoration: InputDecoration(
                labelText: lang.tr(
                  _fieldEnglishLabel(),
                  _fieldUrduLabel(),
                ),
                prefixIcon: Icon(
                  _fieldIcon(),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: mandiGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            MainButton(
              text: isLoading
                  ? lang.tr(
                      'Saving...',
                      'محفوظ ہو رہا ہے...',
                    )
                  : lang.tr(
                      'Complete Profile',
                      'پروفائل مکمل کریں',
                    ),
              onPressed: isLoading ? () {} : _finish,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                lang.tr(
                  'You can edit this information later.',
                  'آپ یہ معلومات بعد میں تبدیل کر سکتے ہیں۔',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF858E88),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cityController.dispose();
    fieldController.dispose();
    super.dispose();
  }
}

// =====================================================
// HOME SCREEN
// =====================================================

class HomeScreen extends StatelessWidget {
  final String? userName;
  final UserRole? role;

  const HomeScreen({
    super.key,
    this.userName,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LanguageScope.of(context);

    final categories = [
      ('Wheat', 'گندم', '🌾'),
      ('Rice', 'چاول', '🍚'),
      ('Maize', 'مکئی', '🌽'),
      ('Cotton', 'کپاس', '🧵'),
      ('Sugarcane', 'گنا', '🌱'),
      ('Machinery', 'مشینری', '🚜'),
      ('Transport', 'ٹرانسپورٹ', '🚛'),
      ('Land', 'زمین', '🏡'),
      ('Seeds', 'بیج', '🌿'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mandiGreen,
        foregroundColor: Colors.white,
        title: Text(
          lang.tr(
            'Anaaj Mandi',
            'اناج منڈی',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding:
                EdgeInsetsDirectional.only(
              end: 8,
            ),
            child: Center(
              child: LanguagePill(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE7E9E7),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/anaaj_logo.png',
                    width: 92,
                    height: 92,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    lang.tr(
                      'Welcome to Anaaj Mandi',
                      'اناج منڈی میں خوش آمدید',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.tr(
                      'Pakistan\'s Agricultural Marketplace',
                      'پاکستان کی زرعی منڈی',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF69736C),
                      fontSize: 14,
                    ),
                  ),
                  if (userName != null &&
                      userName!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      lang.tr(
                        'Assalam-o-Alaikum, $userName',
                        'السلام علیکم، $userName',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: mandiGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (role != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${role!.emoji} ${lang.isUrdu ? role!.urduName : role!.englishName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF69736C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  Text(
                    lang.tr(
                      'Buy • Sell • Trade • Grow',
                      'خریدیں • بیچیں • تجارت کریں • ترقی کریں',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF858E88),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.tr(
                      'Live Mandi Rates',
                      'آج کے منڈی ریٹس',
                    ),
                    style: const TextStyle(
                      color: mandiGold,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RateRow(
                    name: lang.tr(
                      'Wheat • Lahore',
                      'گندم • لاہور',
                    ),
                    price: 'Rs 2,450 / 40kg',
                  ),
                  RateRow(
                    name: lang.tr(
                      'Rice • Karachi',
                      'چاول • کراچی',
                    ),
                    price: 'Rs 5,200 / bag',
                  ),
                  RateRow(
                    name: lang.tr(
                      'Maize • Multan',
                      'مکئی • ملتان',
                    ),
                    price: 'Rs 1,850 / bag',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              lang.tr(
                'Explore Marketplace',
                'مارکیٹ دیکھیں',
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = categories[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          const Color(0xFFE7E9E7),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$3,
                        style: const TextStyle(
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.isUrdu
                            ? item.$2
                            : item.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: mandiGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          lang.tr(
            'Post Listing',
            'اشتہار دیں',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// RATE ROW
// =====================================================

class RateRow extends StatelessWidget {
  final String name;
  final String price;

  const RateRow({
    super.key,
    required this.name,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// MAIN BUTTON
// =====================================================

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MainButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: mandiGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// HELPER: GET ROLE FROM ID
// =====================================================

UserRole? _getRoleFromId(String? roleId) {
  if (roleId == null) return null;

  try {
    return availableRoles
        .firstWhere((r) => r.id == roleId);
  } catch (e) {
    return null;
  }
}