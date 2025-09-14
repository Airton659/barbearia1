import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/agendamento.dart';
import '../../models/servico.dart';
import '../../models/horario_trabalho.dart';
import '../../utils/app_constants.dart';
import '../../screens/profissional/profissional_agendamentos_screen.dart';
import '../client/notificacoes_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  List<Usuario> _usuarios = [];
  bool _loadingUsuarios = true;
  String _filterType = 'todos';
  bool _isBarberMode = false;

  // Barber mode data
  List<Agendamento> _agendamentos = [];
  List<Servico> _servicos = [];
  List<HorarioTrabalho> _horariosTrabalho = [];
  bool _loadingAgendamentos = true;
  bool _loadingServicos = true;
  bool _loadingHorarios = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _loadNotificationCount();
  }

  Future<void> _loadUsuarios() async {
    try {
      final usuarios = await _apiService.getNegocioUsuarios();
      setState(() {
        _usuarios = usuarios;
        _loadingUsuarios = false;
      });
    } catch (e) {
      setState(() => _loadingUsuarios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar usuários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAgendamentos() async {
    try {
      final agendamentos = await _apiService.getMyProfissionalAgendamentos();
      setState(() {
        _agendamentos = agendamentos;
        _loadingAgendamentos = false;
      });
    } catch (e) {
      setState(() => _loadingAgendamentos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar agendamentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadServicos() async {
    try {
      final servicos = await _apiService.getMyServicos();
      setState(() {
        _servicos = servicos;
        _loadingServicos = false;
      });
    } catch (e) {
      setState(() => _loadingServicos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar serviços: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadHorarios() async {
    try {
      final horarios = await _apiService.getMyHorariosTrabalho();
      setState(() {
        _horariosTrabalho = horarios;
        _loadingHorarios = false;
      });
    } catch (e) {
      setState(() => _loadingHorarios = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar horários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final count = await _apiService.getUnreadNotificationsCount();
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

    final pages = _isBarberMode ? [
      const ProfissionalAgendamentosScreen(),
      _buildServicosPage(),
      _buildHorariosPage(),
      _buildConfiguracoesPage(),
    ] : [
      _buildDashboardPage(),
      _buildEquipePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isBarberMode
          ? 'Barbeiro - ${authService.currentUser?.nome ?? ''}'
          : 'Admin - ${authService.currentUser?.nome ?? ''}'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          if (_isBarberMode) ...[
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
          ],
          IconButton(
            icon: Icon(_isBarberMode ? Icons.admin_panel_settings : Icons.work),
            onPressed: _toggleMode,
            tooltip: _isBarberMode ? 'Modo Admin' : 'Modo Barbeiro',
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        items: _isBarberMode ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cut),
            label: 'Serviços',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Horários',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ] : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Equipe',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    final admins = _usuarios.where((u) => u.isAdmin).length;
    final profissionais = _usuarios.where((u) => u.isProfissional).length;
    final clientes = _usuarios.where((u) => u.isCliente).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Administrativo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Total de Usuários',
                  _usuarios.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Administradores',
                  admins.toString(),
                  Icons.admin_panel_settings,
                  Colors.red,
                ),
                GestureDetector(
                  onTap: () => _filterAndSwitchToTeam('barbeiros'),
                  child: _buildMetricCard(
                    'Barbeiros',
                    profissionais.toString(),
                    Icons.work,
                    Colors.blue,
                  ),
                ),
                GestureDetector(
                  onTap: () => _filterAndSwitchToTeam('clientes'),
                  child: _buildMetricCard(
                    'Clientes',
                    clientes.toString(),
                    Icons.person,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipePage() {
    if (_loadingUsuarios) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadUsuarios,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestão da Equipe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _filterType == 'todos',
                      onSelected: (_) => _setFilter('todos'),
                    ),
                    FilterChip(
                      label: const Text('Barbeiros'),
                      selected: _filterType == 'barbeiros',
                      onSelected: (_) => _setFilter('barbeiros'),
                    ),
                    FilterChip(
                      label: const Text('Clientes'),
                      selected: _filterType == 'clientes',
                      onSelected: (_) => _setFilter('clientes'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _getFilteredUsers().isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _getFilteredUsers().length,
                    itemBuilder: (context, index) {
                      final usuario = _getFilteredUsers()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(usuario.roleForCurrentBusiness),
                            child: Text(
                              usuario.nome.isEmpty ? '?' : usuario.nome[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            usuario.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(usuario.email),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(usuario.roleForCurrentBusiness),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRoleLabel(usuario.roleForCurrentBusiness),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditRoleDialog(usuario),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Barber mode pages
  Widget _buildServicosPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cut, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Meus Serviços',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'Funcionalidade em desenvolvimento...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Horários de Trabalho',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'Funcionalidade em desenvolvimento...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracoesPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Configurações',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'Funcionalidade em desenvolvimento...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return Colors.red;
      case AppConstants.roleProfissional:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return 'Administrador';
      case AppConstants.roleProfissional:
        return 'Barbeiro';
      default:
        return 'Cliente';
    }
  }

  Future<void> _showEditRoleDialog(Usuario usuario) async {
    String selectedRole = usuario.roleForCurrentBusiness;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Role - ${usuario.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${usuario.email}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: AppConstants.roleCliente,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Cliente'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: AppConstants.roleProfissional,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Barbeiro'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) => selectedRole = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedRole),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && result != usuario.roleForCurrentBusiness) {
      await _updateUserRole(usuario, result);
    }
  }

  Future<void> _updateUserRole(Usuario usuario, String newRole) async {
    try {
      final updatedUser = await _apiService.updateUsuarioRole(usuario.id, newRole);

      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == usuario.id);
        if (index != -1) {
          _usuarios[index] = updatedUser;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role de ${usuario.nome} atualizado para ${_getRoleLabel(newRole)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Usuario> _getFilteredUsers() {
    List<Usuario> nonAdminUsers = _usuarios.where((u) => !u.isAdmin).toList();

    switch (_filterType) {
      case 'barbeiros':
        return nonAdminUsers.where((u) => u.isProfissional).toList();
      case 'clientes':
        return nonAdminUsers.where((u) => u.isCliente).toList();
      default:
        return nonAdminUsers;
    }
  }

  String _getEmptyMessage() {
    switch (_filterType) {
      case 'barbeiros':
        return 'Nenhum barbeiro encontrado';
      case 'clientes':
        return 'Nenhum cliente encontrado';
      default:
        return 'Nenhum usuário encontrado';
    }
  }

  void _setFilter(String filterType) {
    setState(() {
      _filterType = filterType;
    });
  }

  void _filterAndSwitchToTeam(String filterType) {
    setState(() {
      _filterType = filterType;
      _currentIndex = 1; // Switch to team management tab
    });
  }

  void _toggleMode() {
    setState(() {
      _isBarberMode = !_isBarberMode;
      _currentIndex = 0; // Reset to first tab when switching modes
    });

    // Load barber data when switching to barber mode
    if (_isBarberMode) {
      _loadAgendamentos();
      _loadServicos();
      _loadHorarios();
    }
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