import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isMenuExpanded = false; // Controle de expansão do menu
  final Set<String> _hoveredItems = {}; // Controle para hover de itens
  final Map<String, double> _itemScales = {}; // Mapeia cada item com seu tamanho individual

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        setState(() {
          _userName = adminDoc['name'];
          _isAdmin = true;
        });
      } else {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'];
          });
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Condo',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'Tec',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF003283),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Bem-vindo${_isAdmin ? ', ADM' : ''}, $_userName!',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isMenuExpanded ? screenWidth * 0.2 : screenWidth * 0.05, // Menu fechado mais estreito
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Color(0xFF003283),
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _toggleMenu, // Ação de expandir/contrair o menu
                        ),
                        if (_isMenuExpanded) // Mostrar o conteúdo expandido quando o menu estiver aberto
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMenuItem(
                                title: 'Home',
                                icon: Icons.home,
                                route: '/home',
                              ),
                              _buildMenuItem(
                                title: 'Solicitações', // Para todos os usuários
                                icon: Icons.assignment,
                                route: '/solicitacoes',
                              ),
                              if (!_isAdmin) ...[
                                _buildMenuItem(
                                  title: 'Chamados', // Para usuários comuns
                                  icon: Icons.call,
                                  route: '/chamados',
                                ),
                              ],
                              _buildMenuItem(
                                title: 'Vagas', // Para todos os usuários
                                icon: Icons.business_center,
                                route: '/vagas',
                              ),
                              _buildMenuItem(
                                title: 'Eventos',
                                icon: Icons.event,
                                route: _isAdmin ? '/eventos' : '',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuItem({required String title, required IconData icon, required String route}) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredItems.add(title);
          _itemScales[title] = 1.1; // Aumenta o tamanho do item específico
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredItems.remove(title);
          _itemScales[title] = 1.0; // Retorna ao tamanho normal
        });
      },
      child: GestureDetector(
        onTap: () {
          if (route.isNotEmpty) {
            Navigator.of(context).pushNamed(route);
          }
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _itemScales[title] ?? 1.0, // Aplica a escala individual do item
          child: ListTile(
            leading: Icon(icon, color: Colors.white),
            title: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: _hoveredItems.contains(title) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
