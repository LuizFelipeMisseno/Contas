import 'package:contas/homepage/components/homepage_calendar.dart';
import 'package:contas/homepage/page/homepage.dart';
import 'package:contas/new_transations/components/calendar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DatePicker>(create: (context) => DatePicker()),
        ChangeNotifierProvider<HomePageDatePicker>(
            create: (context) => HomePageDatePicker()),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale("pt", "BR")],
        title: 'Contas',
        theme: ThemeData(
          fontFamily: 'Schyler',
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(),
        /* routes: {
        AppRoutes.HOMEPAGE: (_) => HomePage(),
        AppRoutes.PROFILE: (_) => ProfilePage(),
        AppRoutes.CHAT: (_) => ChatPage(),
        AppRoutes.CART: (_) => CartPage(),
        AppRoutes.SEEMORE: (_) => SeeMorePage(),
        AppRoutes.MYSHOPPING: (_) => MyShoppingPage(),
        AppRoutes.FAVORITES: (_) => FavoritesPage(),
        AppRoutes.PROMOTIONS: (_) => PromotionsPage(),
        AppRoutes.SETTINGS: (_) =>
            SettingsPage(), 
      }, */
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
