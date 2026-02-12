import 'package:flutter/material.dart';
import 'package:sggm/views/escalas_page.dart';
import 'package:sggm/views/eventos_page.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SGGM'),
        centerTitle: true,
        backgroundColor: Colors.green[900],
        actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.logout))],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.green[900]),
                child: Column(
                  children: [
                    const Text(
                      'SGGM',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Image.network('https://www.ipb.org.br/img/logo_ipb2.png', width: 100),
                  ],
                ),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.music_note),
              title: Text(
                'Cifras',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const ListTile(
                leading: Icon(Icons.question_answer),
                title: Text(
                  'Solicitações',
                  style: TextStyle(color: Colors.white),
                )),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                'Configurações',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 350,
              height: 200,
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.all(10),
                color: Colors.grey[100],
                shadowColor: Colors.black,
                child: Column(
                  children: [
                    const Text('Escala da Semana',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (bc) => const EscalasPage())),
                      child: const Text('Ir a Escalas', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 350,
              height: 200,
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.all(10),
                color: Colors.grey[100],
                shadowColor: Colors.black,
                child: Column(
                  children: [
                    const Text('Próximos Eventos',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (bc) => const EventosPage())),
                      child: const Text('Ir a eventos', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 350,
              height: 200,
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.all(10),
                color: Colors.grey[100],
                shadowColor: Colors.black,
                child: const Column(
                  children: [
                    Text('Avisos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    ListTile(
                      leading: Icon(
                        Icons.info,
                        color: Colors.green,
                      ),
                      title: Text(
                        'Sem aviso',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
