import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _addNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Nota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (user != null &&
                  titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('notes').add({
                  'uid': user.uid,
                  'title': titleController.text,
                  'content': contentController.text,
                  'timestamp': Timestamp.now(),
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:  Text('Bienvenido $email'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNoteDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('uid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs;
          if (notes.isEmpty) {
            return const Center(child: Text('No hay notas aún.'));
          }
          print(notes[0]['timestamp']);
          print(notes.toString());
          

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (_, i) {
              final note = notes[i];
              return ListTile(
                title: Text(note['title']),
                subtitle: Text(note['content']),
                trailing: Text(
                  note['timestamp'] != null
                      ? (note['timestamp'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString()
                          .substring(0, 10)
                      : '',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}