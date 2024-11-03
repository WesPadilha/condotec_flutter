import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importando Firestore
import 'firebase_options.dart';
import 'signup.dart'; // Importa a tela de cadastro
import 'home.dart'; // Importa a tela homeAdm

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Exemplo de chamada da função para criar um admin
  //await createAdmin('admin2@gmail.com', '123456789', 'ADEMIRO', '1234567890');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CondoTec',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // Tela de login inicial
      routes: {
        '/signup': (context) => const SignupScreen(), // Rota para a tela de cadastro
        '/home': (context) => const HomeScreen(), // Rota para a tela inicial
        '/login': (context) => const LoginScreen(), // Rota para a tela de login
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/wallpaperHome.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 500,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CondoTec',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[200], // Azul mais fraco
                      minimumSize: const Size(double.infinity, 50), // Botão mais largo
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 20),
                  const Text("Não possui uma conta? Então"),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: const Text(
                      'Crie uma conta',
                      style: TextStyle(color: Colors.black), // Letra escura
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> createAdmin(String email, String password, String name, String phone) async {
  try {
    // Cria o usuário com o email e a senha
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Obter o ID do usuário recém-criado
    String uid = userCredential.user!.uid;

    // Adiciona o admin ao Firestore
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': email,
      'uid': uid,
      'name': name, // Nome do administrador
      'phone': phone, // Telefone do administrador
      'role': 'admin', // Identificação de ADM
      'createdAt': Timestamp.now(), // Data de criação
    });

    print('Admin created successfully: $uid');
  } catch (e) {
    print('Failed to create admin: $e');
  }
}
