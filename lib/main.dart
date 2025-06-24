import 'package:flutter/material.dart';
import 'package:lojinha_flutter/models/theme_provider.dart';
import 'package:lojinha_flutter/models/user_provider.dart';
import 'package:lojinha_flutter/screens/login_screen.dart';
import 'package:lojinha_flutter/screens/pagina_principal_screen.dart';
import 'package:lojinha_flutter/services/database_service.dart';
import 'screens/minhas_receitas_screen.dart';
import 'screens/insumos_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.database;

  final prefs = await SharedPreferences.getInstance();
  final String? username = prefs.getString('username');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MyApp(
        initialScreen: username == null || username.isEmpty
            ? const LoginScreen()
            : PaginaPrincipalScreen(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({required this.initialScreen, super.key});

  @override
  Widget build(BuildContext context) {
    final baseColorScheme = ColorScheme.fromSeed(seedColor: Colors.purple);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme.copyWith(
        brightness: Brightness.dark,
        primary: Colors.purple.shade300,
        surface: Colors.grey.shade900,
      ),
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Lojinha App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: initialScreen,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyAppError extends StatelessWidget {
  final String error;
  const MyAppError({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Ocorreu um erro fatal ao iniciar o app:\\n\\n$error',
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo à Lojinha!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo à Lojinha Flutter!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('Catálogo de Receitas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MinhasReceitasScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Insumos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsumosScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Espaço para futuras opções:
              ElevatedButton.icon(
                icon: const Icon(Icons.inventory),
                label: const Text('Ficha Técnica (em breve)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.grey,
                ),
                onPressed: null, // Desabilitado por enquanto
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Vendas (em breve)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.grey,
                ),
                onPressed: null, // Desabilitado por enquanto
              ),
            ],
          ),
        ),
      ),
    );
  }
}
