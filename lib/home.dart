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
  bool _isAdmin = false; // Verifica se o usuário é admin
  bool _showRequests = false; // Controla a exibição do menu expansível
  double _containerWidth = 0.05; // Largura inicial do menu expansível
  Set<String> _hoveredItems = {}; // Para controle de hover

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Verifica na coleção de administradores
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        setState(() {
          _userName = adminDoc['name'];
          _isAdmin = true; // Define como admin se o documento existir
        });
      } else {
        // Verifica na coleção de usuários
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'];
          });
        }
      }
    }
    setState(() {
      _isLoading = false; // Finaliza o carregamento
    });
  }

  void _toggleRequests() {
    setState(() {
      _showRequests = !_showRequests;
      _containerWidth = _showRequests ? 0.2 : 0.05; // Alterna entre 5% e 20% da tela
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
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
              Navigator.of(context).pushReplacementNamed('/login'); // Redireciona para a tela de login
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Exibe carregando
          : Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16), // Espaço entre a faixa e o conteúdo
                    Center(
                      child: Text(
                        'Bem-vindo${_isAdmin ? ', ADM' : ''}, $_userName!', // Exibe o nome do usuário ou ADM
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
                // Menu expansível no canto superior esquerdo
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: screenWidth * _containerWidth, // Largura variável entre 5% e 20% da tela
                    height: MediaQuery.of(context).size.height, // Altura fixa para ocupar toda a tela
                    decoration: BoxDecoration(
                      color: const Color(0xFF003283), // Mesma cor do cabeçalho
                      borderRadius: const BorderRadius.all(Radius.circular(0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _toggleRequests,
                        ),
                        if (_showRequests)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMenuItem(
                                title: 'Home',
                                icon: Icons.home,
                                route: '/home',
                              ),
                              if (_isAdmin) ...[
                                _buildMenuItem(
                                  title: 'Solicitações',
                                  icon: Icons.report,
                                  route: '/solicitacoes',
                                ),
                                _buildMenuItem(
                                  title: 'Vagas',
                                  icon: Icons.business_center,
                                  route: '/vagas',
                                ),
                              ] else ...[
                                _buildMenuItem(
                                  title: 'Chamados',
                                  icon: Icons.report,
                                  route: '/chamados',
                                ),
                                _buildMenuItem(
                                  title: 'Vagas',
                                  icon: Icons.business_center,
                                  route: '/vagas',
                                ),
                                _buildMenuItem(
                                  title: 'Requisições',
                                  icon: Icons.request_page,
                                  route: '/requisicoes',
                                ),
                              ],
                              _buildMenuItem(
                                title: 'Eventos',
                                icon: Icons.event,
                                route: '/eventos',
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
          _hoveredItems.add(title); // Adiciona o item ao conjunto de hover
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredItems.remove(title); // Remove o item do conjunto de hover
        });
      },
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushNamed(route); // Navega para a página correspondente
        },
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: TextStyle(
              color: _hoveredItems.contains(title) ? Colors.white : Colors.white, // Mantém a cor do texto
              fontWeight: _hoveredItems.contains(title) ? FontWeight.bold : FontWeight.normal, // Negrito ao passar o mouse
            ),
          ),
        ),
      ),
    );
  }
}
