import 'package:condotec/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  Set<String> _hoveredItems = {}; // Armazena os itens que estão sendo "hovered"
  Map<String, double> _itemScales = {}; // Armazena o tamanho de cada item

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    final weather = await _weatherService.getWeather('São Paulo');
    setState(() {
      _weatherData = weather;
    });
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
                Positioned.fill(
                  child: Image.asset(
                    'assets/home.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.only(left: _isMenuExpanded ? 200 : 50),
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
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
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Text(
                                'Bem-vindo${_isAdmin ? ', ADM' : ''} $_userName!',
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CarouselSlider(
                                options: CarouselOptions(
                                  height: 400.0,
                                  autoPlay: true,
                                  enlargeCenterPage: true,
                                  enableInfiniteScroll: true,
                                  autoPlayInterval: Duration(seconds: 3),
                                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                                ),
                                items: [
                                  'assets/imagem1.jpg',
                                  'assets/imagem2.jpg',
                                  'assets/imagem3.jpeg',
                                ].map((item) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(item, fit: BoxFit.cover, width: double.infinity),
                                  ),
                                )).toList(),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: _isAdmin ? MainAxisAlignment.center : MainAxisAlignment.start, // Centraliza os cards quando for ADM
                                children: [
                                  if (_isAdmin) ...[ // Para o Admin, exibe "Solicitações" e "Vagas" lado a lado
                                    _buildCard('Solicitações', Icons.assignment, '/solicitacoes'),
                                    const SizedBox(width: 10), // Espaço pequeno entre os cards
                                    _buildCard('Vagas', Icons.business_center, '/vagas'),
                                  ] else ...[ // Para os outros usuários, mantém o layout como estava
                                    _buildCard('Solicitações', Icons.assignment, '/solicitacoes'),
                                    _buildCard('Chamados', Icons.call, '/chamados'),
                                    _buildCard('Vagas', Icons.business_center, '/vagas'),
                                  ]
                                ],
                              ),
                              const SizedBox(height: 20), 
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Previsão do tempo
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Clima de hoje em Guarapuava :)',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _weatherData != null
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.thermostat, color: Colors.blue),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'Temperatura: ${_weatherData!['main']['temp']}°C',
                                                          style: const TextStyle(fontSize: 18),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.cloud, color: Colors.grey),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'Condição: ${_weatherData!['weather'][0]['description']}',
                                                          style: const TextStyle(fontSize: 18),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : const CircularProgressIndicator(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Contatos
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Contatos',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
                                              SizedBox(width: 10),
                                              Text(
                                                '+55 11 98765-4321',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(Icons.email, color: Colors.red),
                                              SizedBox(width: 10),
                                              Text(
                                                'contato@condotec.com',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: const [
                                              Icon(Icons.phone, color: Colors.blue),
                                              SizedBox(width: 10),
                                              Text(
                                                '(11) 1234-5678',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isMenuExpanded ? screenWidth * 0.2 : screenWidth * 0.05,
                    height: MediaQuery.of(context).size.height,
                    decoration: const BoxDecoration(
                      color: Color(0xFF003283),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: _toggleMenu,
                        ),
                        if (_isMenuExpanded)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMenuItem(
                                title: 'Home',
                                icon: Icons.home,
                                route: '/home',
                              ),
                              _buildMenuItem(
                                title: 'Solicitações',
                                icon: Icons.assignment,
                                route: '/solicitacoes',
                              ),
                              if (!_isAdmin)
                                _buildMenuItem(
                                  title: 'Chamados',
                                  icon: Icons.call,
                                  route: '/chamados',
                                ),
                              _buildMenuItem(
                                title: 'Vagas',
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

  Widget _buildCard(String title, IconData icon, String route) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(route);
        },
        child: Container(
          width: 250,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4)),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Color(0xFF003283)),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003283),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      child: AnimatedScale(
        scale: _itemScales[title] ?? 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(route);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
