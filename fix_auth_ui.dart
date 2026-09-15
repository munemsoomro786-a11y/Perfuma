import 'dart:io';

void main() {
  String content = File('lib/main.dart').readAsStringSync();
  
  // Add auth.dart and firebase_auth imports if not exist
  if (!content.contains("import 'auth.dart';")) {
    content = content.replaceFirst("import 'products.dart';", "import 'products.dart';\nimport 'auth.dart';\nimport 'package:firebase_auth/firebase_auth.dart';");
  }

  String authActionWidget = """
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              final user = snapshot.data;
              if (user != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: PopupMenuButton<String>(
                    tooltip: 'Account',
                    icon: const Icon(Icons.person, color: Colors.black, size: 28),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(user.email ?? 'User', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (c) => const AuthDialog());
                  },
                  icon: const Icon(Icons.login, color: Colors.black),
                  label: const Text('Login', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              );
            }
          ),
          """;

  // In HomePage:
  content = content.replaceFirst(
    "const SizedBox(width: 20),", 
    authActionWidget + "\n          const SizedBox(width: 20),"
  );
  
  // In ProductDetailsScreen, wait ProductDetailsScreen is at the end of the file.
  // There are two "const SizedBox(width: 20)," inside actions. I need to be careful.
  
  File('lib/main.dart').writeAsStringSync(content);
}
