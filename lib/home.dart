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
                // Imagem de fundo
                Positioned.fill(
                  child: Image.asset(
                    'assets/home.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                SingleChildScrollView( // Adiciona o scroll ao conteúdo
                  padding: const EdgeInsets.only(left: 200), // Deixa espaço para o menu
                  child: Column(
                    children: [
                      const SizedBox(height: 50), // Ajusta o espaço no topo para o texto de boas-vindas
                      Center(
                        child: Container(
                          width: 900,
                          height: 1000,
                          decoration: BoxDecoration(
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            color: Colors.white, // Fundo branco para o container
                          ),
                          padding: const EdgeInsets.all(40), // Adiciona padding de 40px para o conteúdo
                          child: Column(
                            children: [
                              // Texto "Bem-vindo ADM" antes das imagens
                              Text(
                                'Bem-vindo${_isAdmin ? ', ADM' : ''} $_userName!',
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Colors.black, // Texto em preto
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/imagem1.jpg', width: 405, height: 500), // Substitua com suas imagens
                                  const SizedBox(width: 8), // Diminuindo a distância entre as imagens
                                  Image.asset('assets/imagem2.jpg', width: 400, height: 300), // Substitua com suas imagens
                                ],
                              ),
                              const SizedBox(height: 10), // Ajusta o espaço entre as imagens e os textos abaixo
                              const Text(
                                'Bem-vindo ao site de condomínios!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Texto em preto
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Este site permite que você faça solicitações ao síndico, visualize as solicitações existentes e adicione vagas para seu carro no estacionamento. Aproveite a experiência e se precisar de alguma coisa, não hesite em nos contatar.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black, // Texto em preto
                                ),
                                textAlign: TextAlign.justify, // Justificando o texto
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Menu fixo na lateral
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
                              if (!_isAdmin)
                                _buildMenuItem(
                                  title: 'Chamados', // Para usuários comuns
                                  icon: Icons.call,
                                  route: '/chamados',
                                ),
                              _buildMenuItem(
                                title: 'Vagas', // Para todos os usuários
                                icon: Icons.business_center,
                                route: '/vagas',
                              ),
                              if (_isAdmin)
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
