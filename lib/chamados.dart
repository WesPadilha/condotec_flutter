import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChamadosScreen extends StatefulWidget {
  const ChamadosScreen({super.key});

  @override
  State<ChamadosScreen> createState() => _ChamadosScreenState();
}

class _ChamadosScreenState extends State<ChamadosScreen> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _isUrgent = false;

  Future<void> _createChamado() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('chamados').add({
          'titulo': _tituloController.text,
          'descricao': _descricaoController.text,
          'urgente': _isUrgent,
          'userId': user.uid,
          'dataCriacao': FieldValue.serverTimestamp(),
        });
        _tituloController.clear();
        _descricaoController.clear();
        setState(() {
          _isUrgent = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação criada com sucesso!')),
        );
      } catch (e) {
        print("Erro ao criar chamado: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao criar solicitação!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fazer Solicitação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            Row(
              children: [
                Checkbox(
                  value: _isUrgent,
                  onChanged: (bool? value) {
                    setState(() {
                      _isUrgent = value!;
                    });
                  },
                ),
                const Text('Urgente'),
              ],
            ),
            ElevatedButton(
              onPressed: _createChamado,
              child: const Text('Criar Solicitação'),
            ),
          ],
        ),
      ),
    );
  }
}
