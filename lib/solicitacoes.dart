import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SolicitacoesScreen extends StatefulWidget {
  const SolicitacoesScreen({super.key});

  @override
  State<SolicitacoesScreen> createState() => _SolicitacoesScreenState();
}

class _SolicitacoesScreenState extends State<SolicitacoesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _solicitacoes = [];

  @override
  void initState() {
    super.initState();
    _fetchUserSolicitacoes();
  }

  // Função para verificar se o usuário é admin
  Future<bool> _isAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['role'] == 'admin';
      }
    }
    return false;
  }

  // Função para buscar as solicitações com base na role do usuário
  Future<void> _fetchUserSolicitacoes() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool isAdmin = await _isAdmin();

        QuerySnapshot snapshot;
        if (isAdmin) {
          // Admin pode ver apenas solicitações que ainda não foram respondidas
          snapshot = await FirebaseFirestore.instance
              .collection('chamados')
              .where('resposta', isEqualTo: null)
              .get();
        } else {
          // Usuário normal vê todas as suas próprias solicitações
          snapshot = await FirebaseFirestore.instance
              .collection('chamados')
              .where('userId', isEqualTo: user.uid)
              .get();
        }

        List<Map<String, dynamic>> solicitacoes = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        setState(() {
          _solicitacoes = solicitacoes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erro ao buscar solicitações: $e");
    }
  }

  // Função para Administrador responder a uma solicitação
  void _responderChamado(Map<String, dynamic> solicitacao) {
    TextEditingController respostaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Responder Solicitação'),
          content: TextField(
            controller: respostaController,
            decoration: const InputDecoration(labelText: 'Resposta'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Atualizar Firestore com a resposta
                  await FirebaseFirestore.instance.collection('chamados').doc(solicitacao['id']).update({
                    'resposta': respostaController.text,
                  });

                  // Remover a solicitação da lista local após responder
                  setState(() {
                    _solicitacoes.removeWhere((item) => item['id'] == solicitacao['id']);
                  });

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resposta enviada com sucesso!')),
                  );
                } catch (e) {
                  print("Erro ao responder solicitação: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao responder solicitação!')),
                  );
                }
              },
              child: const Text('Enviar Resposta'),
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
        title: const Text('Solicitações'),
        backgroundColor: const Color(0xFF003283), // Cor de fundo do header (azul)
        foregroundColor: Colors.white, // Cor da escrita no header (branca)
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/solicitacao.jpg'),
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
                          'Solicitações',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          child: Column(
                            children: List.generate(_solicitacoes.length, (index) {
                              var solicitacao = _solicitacoes[index];
                              bool isAdmin = _solicitacoes[index]['userId'] != FirebaseAuth.instance.currentUser?.uid;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200], // Cor de fundo das solicitações
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text(solicitacao['titulo']),
                                  subtitle: solicitacao['resposta'] != null
                                      ? Text("Resposta: ${solicitacao['resposta']}")
                                      : Text(solicitacao['descricao']),
                                  trailing: isAdmin
                                      ? IconButton(
                                          icon: const Icon(Icons.message),
                                          onPressed: () => _responderChamado(solicitacao),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () => _editChamado(solicitacao),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('chamados')
                                                    .doc(solicitacao['id'])
                                                    .delete();
                                                setState(() {
                                                  _solicitacoes.removeWhere((item) => item['id'] == solicitacao['id']);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            }),
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

  // Função para editar uma solicitação para usuários normais
  void _editChamado(Map<String, dynamic> solicitacao) {
    TextEditingController tituloController = TextEditingController(text: solicitacao['titulo']);
    TextEditingController descricaoController = TextEditingController(text: solicitacao['descricao']);
    bool isUrgent = solicitacao['urgente'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Solicitação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
              Row(
                children: [
                  Checkbox(
                    value: isUrgent,
                    onChanged: (bool? value) {
                      setState(() {
                        isUrgent = value!;
                      });
                    },
                  ),
                  const Text('Urgente'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('chamados').doc(solicitacao['id']).update({
                    'titulo': tituloController.text,
                    'descricao': descricaoController.text,
                    'urgente': isUrgent,
                  });
                  Navigator.of(context).pop();
                  setState(() {
                    _fetchUserSolicitacoes();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitação atualizada com sucesso!')),
                  );
                } catch (e) {
                  print("Erro ao editar solicitação: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao editar solicitação!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}
