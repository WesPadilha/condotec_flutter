import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VagasScreen extends StatefulWidget {
  const VagasScreen({super.key});

  @override
  State<VagasScreen> createState() => _VagasScreenState();
}

class _VagasScreenState extends State<VagasScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _vagas = [];
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin().then((_) => _fetchUserVagas());
  }

  // Função para verificar se o usuário é admin
  Future<void> _checkIfAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          _isAdmin = snapshot.data()!['role'] == 'admin';
        });
      }
    }
  }

  // Função para buscar as vagas com base na role do usuário
  Future<void> _fetchUserVagas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot;

        if (_isAdmin) {
          // Administrador pode ver todas as vagas
          snapshot = await FirebaseFirestore.instance.collection('vagas').get();
        } else {
          // Usuário normal só vê suas próprias vagas
          snapshot = await FirebaseFirestore.instance
              .collection('vagas')
              .where('userId', isEqualTo: user.uid)
              .get();
        }

        List<Map<String, dynamic>> vagas = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        setState(() {
          _vagas = vagas;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erro ao buscar vagas: $e");
    }
  }

  Future<void> _addOrUpdateVaga({String? id, String? titulo, String? descricao}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        if (id == null) {
          await FirebaseFirestore.instance.collection('vagas').add({
            'titulo': titulo,
            'descricao': descricao,
            'userId': user.uid,
          });
        } else {
          await FirebaseFirestore.instance.collection('vagas').doc(id).update({
            'titulo': titulo,
            'descricao': descricao,
          });
        }
        _fetchUserVagas();
      } catch (e) {
        print("Erro ao adicionar ou atualizar vaga: $e");
      }
    }
  }

  Future<void> _removeVaga(String id) async {
    try {
      await FirebaseFirestore.instance.collection('vagas').doc(id).delete();
      _fetchUserVagas();
    } catch (e) {
      print("Erro ao remover vaga: $e");
    }
  }

  void _showAddOrEditVagaDialog({String? id, String? initialTitulo, String? initialDescricao}) {
    final tituloController = TextEditingController(text: initialTitulo);
    final descricaoController = TextEditingController(text: initialDescricao);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? "Adicionar Nova Vaga" : "Editar Vaga"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: "Descrição"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final titulo = tituloController.text;
                final descricao = descricaoController.text;
                if (titulo.isNotEmpty && descricao.isNotEmpty) {
                  _addOrUpdateVaga(id: id, titulo: titulo, descricao: descricao);
                }
                Navigator.of(context).pop();
              },
              child: Text(id == null ? "Adicionar" : "Salvar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vagas'),
        backgroundColor: const Color(0xFF003283),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/vagas.jpg'), // Substitua pelo caminho correto da imagem de fundo
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Container(
                    width: 700,
                    height: 500,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vagas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: List.generate(_vagas.length, (index) {
                                var vaga = _vagas[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200], // Cor de fundo das vagas
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    title: Text(vaga['titulo']),
                                    subtitle: Text(vaga['descricao']),
                                    trailing: !_isAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () => _showAddOrEditVagaDialog(
                                                  id: vaga['id'],
                                                  initialTitulo: vaga['titulo'],
                                                  initialDescricao: vaga['descricao'],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _removeVaga(vaga['id']),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        if (!_isAdmin)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () => _showAddOrEditVagaDialog(),
                              child: const Text("Adicionar Vaga"),
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
