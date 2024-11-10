import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class EventosScreen extends StatefulWidget {
  const EventosScreen({Key? key}) : super(key: key);

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final TextEditingController _eventController = TextEditingController();
  bool _isLoading = false;

  Future<void> postEvent() async {
    setState(() {
      _isLoading = true;
    });

    String eventText = _eventController.text.trim();

    if (eventText.isNotEmpty) {
      // Salvar o evento no Firestore
      await FirebaseFirestore.instance.collection('events').add({
        'event': eventText,
        'createdAt': Timestamp.now(),
      });

      // Buscar todos os números de telefone dos usuários
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Enviar o evento para todos os números de telefone
      for (var doc in userSnapshot.docs) {
        String? phoneNumber = doc['phone'];
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          await sendWhatsAppMessage(eventText, phoneNumber);
        }
      }

      setState(() {
        _isLoading = false;
        _eventController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento publicado e enviado via WhatsApp!')),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
    }
  }

  Future<void> sendWhatsAppMessage(String message, String recipientNumber) async {
    var headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    var body = {
      'token': 'jmmkczkf7s7v9ojy',
      'to': recipientNumber,
      'body': message,
    };

    var response = await http.post(
      Uri.parse('https://api.ultramsg.com/instance99235/messages/chat'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      print('Mensagem enviada para $recipientNumber');
    } else {
      print('Falha ao enviar mensagem para $recipientNumber: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                labelText: 'Escreva o evento',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: postEvent,
                    child: const Text('Publicar Evento'),
                  ),
          ],
        ),
      ),
    );
  }
}
