import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importando Firestore
import 'firebase_options.dart';
import 'signup.dart'; // Importa a tela de cadastro
import 'home.dart'; // Importa a tela homeAdm
import 'vagas.dart'; // Importa a tela de gerenciamento de vagas
import 'chamados.dart'; // Importa a tela de chamados
import 'solicitacoes.dart';
import 'eventos.dart'; // Importa a tela de solicitações

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Criar administrador (temporário, remova após a criação)
  //await createAdmin("wes@gmail.com", "123456789", "Wesley", "123456789");

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
        '/vagas': (context) => const VagasScreen(), // Rota para a tela de gerenciamento de vagas
        '/chamados': (context) => const ChamadosScreen(), // Rota para a tela de chamados
        '/solicitacoes': (context) => const SolicitacoesScreen(),
        '/eventos': (context) => const EventosScreen(),
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
  bool _obscurePassword = true; // Variável para controlar a visibilidade da senha

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
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'senha ou e-mail incorreto!'; // Mensagem padrão para erro desconhecido
        if (e.code == 'user-not-found') {
          errorMessage = 'E-mail não encontrado. Verifique seu e-mail e tente novamente.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Senha incorreta. Verifique sua senha e tente novamente.';
        }
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocorreu um erro inesperado: $e';
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Usando a variável para controlar a visibilidade
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.lock // Cadeado fechado quando a senha está oculta
                              : Icons.lock_open, // Cadeado aberto quando a senha está visível
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword; // Alterna a visibilidade da senha
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003283),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white, // Cor do texto dentro do botão
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                    child: const Text('Criar Conta'),
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

// Função para criar administrador, sem exibição na tela
Future<void> createAdmin(String email, String password, String name, String phone) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': email,
      'uid': uid,
      'name': name,
      'phone': phone,
      'role': 'admin',
      'createdAt': Timestamp.now(),
    });

    print('Admin created successfully: $uid');
  } catch (e) {
    print('Failed to create admin: $e');
  }
}
