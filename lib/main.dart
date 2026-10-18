import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'core/constants/app_colors.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';

/// Global provider for managing the app's active locale (English, Amharic, Afaan Oromoo)
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Connection
  await Supabase.initialize(
    url: 'https://ifwqzixrwslwounzknhm.supabase.co',
    anonKey: 'sb_publishable_9nK3Gzmdj-32mIT4_z27Jw_FA7iBKYj',
  );

  runApp(const ProviderScope(child: BisheApp()));
}

/// Custom Material Localization Delegate for Afaan Oromoo ('om')
/// Falls back to DefaultMaterialLocalizations (English) for Material UI controls
class OmMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const OmMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'om';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(
      const DefaultMaterialLocalizations(),
    );
  }

  @override
  bool shouldReload(OmMaterialLocalizationsDelegate old) => false;
}

/// Custom Cupertino Localization Delegate for Afaan Oromoo ('om')
class OmCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const OmCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'om';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(
      const DefaultCupertinoLocalizations(),
    );
  }

  @override
  bool shouldReload(OmCupertinoLocalizationsDelegate old) => false;
}

class BisheApp extends ConsumerWidget {
  const BisheApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'BISHE Car Wash',
      debugShowCheckedModeBanner: false,
      locale: activeLocale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('am'), // Amharic (አማርኛ)
        Locale('om'), // Afaan Oromoo
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        OmMaterialLocalizationsDelegate(),
        OmCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.iceBackground,
        primaryColor: AppColors.primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          surface: AppColors.iceBackground,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
