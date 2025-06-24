import 'package:flutter/material.dart';
import 'package:lojinha_flutter/models/user_provider.dart';
import 'package:lojinha_flutter/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../models/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showEditNameDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.username;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alterar Nome'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Digite seu nome"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () async {
                await userProvider.setUsername(_nameController.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome alterado com sucesso!')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await Provider.of<UserProvider>(context, listen: false).logout();

    // Navega para a tela de login e remove todas as outras telas da pilha
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                title: const Text('Modo Escuro'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (isOn) {
                    themeProvider.toggleTheme(isOn);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Alterar Nome'),
                onTap: _showEditNameDialog,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sair (Logout)',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          );
        },
      ),
    );
  }
}
