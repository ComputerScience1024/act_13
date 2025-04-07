import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      home: StreamBuilder(
        stream: _authService.userChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
          return snapshot.hasData
              ? ProfileScreen(authService: _authService)
              : AuthScreen(authService: _authService);
        },
      ),
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  User? get currentUser => _auth.currentUser;
}

class AuthScreen extends StatefulWidget {
  final AuthService authService;

  const AuthScreen({super.key, required this.authService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true;
  String message = "";

  void _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      setState(() => message = "Invalid email or password (min 6 chars)");
      return;
    }

    try {
      isLogin
          ? await widget.authService.signIn(email, password)
          : await widget.authService.register(email, password);
    } catch (e) {
      setState(() => message = 'Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            ElevatedButton(onPressed: _submit, child: Text(isLogin ? 'Login' : 'Register')),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Don't have an account? Register" : "Already have an account? Login"),
            ),
            if (message.isNotEmpty) Text(message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final AuthService authService;
  final TextEditingController _passwordController = TextEditingController();

  ProfileScreen({super.key, required this.authService});

  void _changePassword(BuildContext context) async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    try {
      await authService.changePassword(password);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password changed successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = authService.currentUser?.email ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Welcome, $email", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "New Password")),
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
