import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/agendamento.dart';
import 'agendamento_screen.dart';
import 'meus_agendamentos_screen.dart';
import 'client_profile_screen.dart';
import 'profissional_details_screen.dart';
import 'agendamento_por_horario_screen.dart';
import 'notificacoes_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;
  List<Usuario> _profissionais = [];
  List<Agendamento> _proximosAgendamentos = [];
  bool _isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Load professionals first
      print('🔥 ClientHome: Loading professionals...');
      List<Usuario> profissionais;
      try {
        profissionais = await apiService.getProfissionais();
        print('🔥 ClientHome: Professionals loaded: ${profissionais.length}');
        print('🔥 ClientHome: Professionals data: $profissionais');
      } catch (profError) {
        print('🔥 ClientHome: Error loading professionals: $profError');
        rethrow;
      }

      // Try to load appointments, but don't fail if it doesn't work
      List<Agendamento> agendamentos = [];
      try {
        print('🔥 ClientHome: Loading my appointments...');
        agendamentos = await apiService.getMyAgendamentos();
        print('🔥 ClientHome: Appointments loaded: ${agendamentos.length}');
      } catch (appointmentError) {
        print('🔥 ClientHome: Error loading appointments (continuing): $appointmentError');
        // Continue without appointments - user might not have any
      }

      // Try to load notification count
      int unreadCount = 0;
      try {
        unreadCount = await apiService.getUnreadNotificationsCount();
      } catch (notificationError) {
        print('🔥 ClientHome: Error loading notification count (continuing): $notificationError');
        // Continue without notification count
      }

      final proximosAgendamentos = agendamentos
          .where((a) => a.isProximo && a.isAgendado)
          .take(3)
          .toList();

      setState(() {
        _profissionais = profissionais;
        _proximosAgendamentos = proximosAgendamentos;
        _unreadNotifications = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('🔥 ClientHome: Critical error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final count = await apiService.getUnreadNotificationsCount();
      setState(() {
        _unreadNotifications = count;
      });
    } catch (e) {
      // Ignore errors when loading notification count
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    final pages = [
      _buildHomePage(),
      const MeusAgendamentosScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${authService.currentUser?.nome ?? ''}'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificacoesScreen(),
                    ),
                  );
                  // Recarregar contador após voltar da tela de notificações
                  _loadNotificationCount();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ClientProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agendamentos',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AgendamentoScreen(),
                  ),
                );
              },
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Novo Agendamento'),
            )
          : null,
    );
  }

  Widget _buildHomePage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botão de ação rápida
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AgendamentoPorHorarioScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.brown.shade400, Colors.brown.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Encontrar Horário Disponível',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Escolha primeiro o horário que te convém',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Próximos agendamentos
            if (_proximosAgendamentos.isNotEmpty) ...[
              const Text(
                'Seus Próximos Agendamentos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proximosAgendamentos.length,
                  itemBuilder: (context, index) {
                    final agendamento = _proximosAgendamentos[index];
                    return _buildAgendamentoCard(agendamento);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Nossos profissionais
            const Text(
              'Nossos Profissionais',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_profissionais.isEmpty)
              const Center(
                child: Text(
                  'Nenhum profissional disponível no momento',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _profissionais.length,
                itemBuilder: (context, index) {
                  final profissional = _profissionais[index];
                  return _buildProfissionalCard(profissional);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agendamento.profissional?.nome ?? 'Barbeiro',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              agendamento.servico?.nome ?? 'Serviço',
              style: const TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.brown),
                const SizedBox(width: 4),
                Text(
                  '${agendamento.dataHora.day}/${agendamento.dataHora.month} às ${agendamento.dataHora.hour}:${agendamento.dataHora.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfissionalCard(Usuario profissional) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfissionalDetailsScreen(
                profissional: profissional,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.brown.shade100,
                backgroundImage: profissional.profileImage != null && profissional.profileImage!.isNotEmpty
                    ? NetworkImage(profissional.profileImage!)
                    : null,
                onBackgroundImageError: profissional.profileImage != null && profissional.profileImage!.isNotEmpty
                    ? (exception, stackTrace) {
                        print('Erro ao carregar imagem do profissional ${profissional.nome}: $exception');
                      }
                    : null,
                child: profissional.profileImage == null || profissional.profileImage!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.brown.shade700,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                profissional.nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Profissional',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}