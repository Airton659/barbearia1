import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/agendamento.dart';
import '../../models/servico.dart';
import '../../models/horario_trabalho.dart';
import '../../utils/app_constants.dart';
import '../../screens/profissional/profissional_agendamentos_screen.dart';
import '../../screens/profissional/profile_edit_screen.dart';
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
  bool _notificacoesAtivas = true;

  // Controladores para a alteração de senha
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsuarios();
    _loadNotificationCount();
  }

  @override
  void dispose() {
    // Limpando os controladores de senha
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

    final pages = _isBarberMode
        ? [
            const ProfissionalAgendamentosScreen(),
            _buildServicosPage(),
            _buildHorariosPage(),
            _buildConfiguracoesPage(),
          ]
        : [
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
        items: _isBarberMode
            ? const [
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
              ]
            : const [
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

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
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
              color.withOpacity(0.1),
              color.withOpacity(0.05),
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
                          const Icon(Icons.people, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
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
                              backgroundColor:
                                  _getRoleColor(usuario.roleForCurrentBusiness),
                              child: Text(
                                usuario.nome.isEmpty
                                    ? '?'
                                    : usuario.nome[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              usuario.nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                                    color: _getRoleColor(
                                        usuario.roleForCurrentBusiness),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleLabel(
                                        usuario.roleForCurrentBusiness),
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
    if (_loadingServicos) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadServicos,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meus Serviços',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showServicoDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _servicos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cut, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum serviço cadastrado',
                              style: TextStyle(color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toque em "Novo" para adicionar',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _servicos.length,
                        itemBuilder: (context, index) {
                          final servico = _servicos[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.brown,
                                child: Text(
                                  servico.nome.isEmpty
                                      ? '?'
                                      : servico.nome[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                servico.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (servico.descricao != null &&
                                      servico.descricao!.isNotEmpty)
                                    Text(servico.descricao!),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${servico.duracao}min'),
                                      const SizedBox(width: 16),
                                      Icon(Icons.attach_money,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                          'R\$ ${servico.preco.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showServicoDialog(servico: servico);
                                  } else if (value == 'delete') {
                                    _deleteServico(servico);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorariosPage() {
    if (_loadingHorarios) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadHorarios,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Horários de Trabalho',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure seus horários de funcionamento para cada dia da semana',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 7, // 7 dias da semana
                  itemBuilder: (context, index) {
                    final diaSemana = index + 1; // 1 = segunda, 7 = domingo
                    final horario = _horariosTrabalho.firstWhere(
                      (h) => h.diaSemana == diaSemana,
                      orElse: () => HorarioTrabalho(
                        id: '',
                        profissionalId: '',
                        diaSemana: diaSemana,
                        horaInicio: '09:00',
                        horaFim: '18:00',
                        trabalhaNesteDia: false,
                        negocioId: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );

                    return _buildHorarioDiaCard(horario);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHorarios,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Salvar Horários',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracoesPage() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
            ),
            const SizedBox(height: 24),

            // Seção do Perfil
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Foto de perfil
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.brown, width: 2),
                          ),
                          child: user?.profileImage != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.profileImage!,
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      // Fallback para iniciais se a imagem falhar
                                      return user.nome.isNotEmpty
                                          ? Center(
                                              child: Text(
                                                user.nome[0].toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                            )
                                          : const Icon(Icons.person,
                                              color: Colors.brown, size: 30);
                                    },
                                  ),
                                )
                              : user?.nome?.isNotEmpty == true
                                  ? Center(
                                      child: Text(
                                        user!.nome[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      color: Colors.brown, size: 30),
                        ),
                        const SizedBox(width: 16),

                        // Informações do usuário
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.nome ?? 'Nome não definido',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'Email não definido',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Barbeiro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.brown[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botão editar perfil
                        IconButton(
                          onPressed: _editarPerfil,
                          icon: const Icon(Icons.edit, color: Colors.brown),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Opções de configuração
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.brown,
                    ),
                    title: const Text(
                      'Notificações',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _notificacoesAtivas
                          ? 'Receber notificações de agendamentos'
                          : 'Notificações desativadas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Switch(
                      value: _notificacoesAtivas,
                      onChanged: (value) {
                        setState(() {
                          _notificacoesAtivas = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value
                                ? 'Notificações ativadas'
                                : 'Notificações desativadas'),
                            backgroundColor:
                                value ? Colors.green : Colors.orange,
                          ),
                        );
                      },
                      activeTrackColor: Colors.brown,
                    ),
                  ),
                  _buildConfigItem(
                    icon: Icons.lock_outline,
                    title: 'Alterar Senha',
                    subtitle: 'Atualize sua senha de acesso',
                    onTap: _showChangePasswordDialog,
                  ),
                  _buildConfigItem(
                    icon: Icons.info_outline,
                    title: 'Sobre o App',
                    subtitle: 'Versão e informações',
                    onTap: _mostrarSobre,
                  ),
                  const Divider(),
                  _buildConfigItem(
                    icon: Icons.logout,
                    title: 'Sair',
                    subtitle: 'Fazer logout da conta',
                    onTap: _logout,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
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
              value: selectedRole,
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
                        decoration: const BoxDecoration(
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
                        decoration: const BoxDecoration(
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
      final updatedUser =
          await _apiService.updateUsuarioRole(usuario.id, newRole);

      setState(() {
        final index = _usuarios.indexWhere((u) => u.id == usuario.id);
        if (index != -1) {
          _usuarios[index] = updatedUser;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Role de ${usuario.nome} atualizado para ${_getRoleLabel(newRole)}'),
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

  Future<void> _showServicoDialog({Servico? servico}) async {
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final descricaoController =
        TextEditingController(text: servico?.descricao ?? '');
    final duracaoController =
        TextEditingController(text: servico?.duracao.toString() ?? '');
    final precoController =
        TextEditingController(text: servico?.preco.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(servico == null ? 'Novo Serviço' : 'Editar Serviço'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Serviço*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: duracaoController,
                  decoration: const InputDecoration(
                    labelText: 'Duração (minutos)*',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 30, 60, 90',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }
                    final duracao = int.tryParse(value);
                    if (duracao == null || duracao <= 0) {
                      return 'Digite apenas números positivos';
                    }
                    if (duracao > 480) {
                      return 'Duração máxima: 480 minutos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precoController,
                  decoration: const InputDecoration(
                    labelText: 'Preço (R\$)*',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 30,00 ou 50.50',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obrigatório';
                    }

                    // Normalizar para usar ponto como separador decimal
                    final normalizedValue = value.replaceAll(',', '.');
                    final preco = double.tryParse(normalizedValue);

                    if (preco == null || preco <= 0) {
                      return 'Digite um valor válido (ex: 30,00)';
                    }

                    if (preco > 9999.99) {
                      return 'Valor máximo: R\$ 9.999,99';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Normalizar preço para usar ponto como separador decimal
      final precoNormalizado = precoController.text.replaceAll(',', '.');

      final novoServico = Servico(
        id: servico?.id ?? '',
        nome: nomeController.text,
        descricao:
            descricaoController.text.isEmpty ? null : descricaoController.text,
        duracao: int.parse(duracaoController.text),
        preco: double.parse(precoNormalizado),
        profissionalId: '',
        negocioId: '',
        createdAt: servico?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (servico == null) {
        await _createServico(novoServico);
      } else {
        await _updateServico(servico.id, novoServico);
      }
    }

    nomeController.dispose();
    descricaoController.dispose();
    duracaoController.dispose();
    precoController.dispose();
  }

  Future<void> _createServico(Servico servico) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profissionalId = authService.currentUser?.id ?? '';

      final newServico =
          await _apiService.createServico(servico, profissionalId);

      setState(() {
        _servicos.add(newServico);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Erro ao criar serviço';

      if (e.toString().contains('422')) {
        errorMessage = 'Dados inválidos. Verifique os campos e tente novamente.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Não autorizado. Faça login novamente.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erro interno do servidor. Tente novamente.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\nDetalhes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateServico(String servicoId, Servico servico) async {
    try {
      final updatedServico =
          await _apiService.updateServico(servicoId, servico);
      setState(() {
        final index = _servicos.indexWhere((s) => s.id == servicoId);
        if (index != -1) {
          _servicos[index] = updatedServico;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço atualizado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteServico(Servico servico) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            Text('Tem certeza que deseja excluir o serviço "${servico.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _apiService.deleteServico(servico.id);

        setState(() {
          _servicos.removeWhere((s) => s.id == servico.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Serviço excluído com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir serviço: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHorarioDiaCard(HorarioTrabalho horario) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  horario.nomeDia,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: horario.trabalhaNesteDia,
                  onChanged: (value) {
                    setState(() {
                      final index = _horariosTrabalho.indexWhere(
                        (h) => h.diaSemana == horario.diaSemana,
                      );
                      if (index >= 0) {
                        final updatedHorario = HorarioTrabalho(
                          id: _horariosTrabalho[index].id,
                          profissionalId:
                              _horariosTrabalho[index].profissionalId,
                          diaSemana: _horariosTrabalho[index].diaSemana,
                          horaInicio: _horariosTrabalho[index].horaInicio,
                          horaFim: _horariosTrabalho[index].horaFim,
                          trabalhaNesteDia: value,
                          negocioId: _horariosTrabalho[index].negocioId,
                          createdAt: _horariosTrabalho[index].createdAt,
                          updatedAt: DateTime.now(),
                        );
                        _horariosTrabalho[index] = updatedHorario;
                      } else {
                        _horariosTrabalho.add(HorarioTrabalho(
                          id: '',
                          profissionalId: '',
                          diaSemana: horario.diaSemana,
                          horaInicio: '09:00',
                          horaFim: '18:00',
                          trabalhaNesteDia: value,
                          negocioId: '',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ));
                      }
                    });
                  },
                  activeTrackColor: Colors.brown,
                ),
              ],
            ),
            if (horario.trabalhaNesteDia) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Início',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(context, true, horario),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(_formatTime(horario.horaInicio ?? '09:00')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fim',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(context, false, horario),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Text(_formatTime(horario.horaFim ?? '18:00')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Fechado',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
      BuildContext context, bool isStartTime, HorarioTrabalho horario) async {
    final currentTime = isStartTime
        ? TimeOfDay.fromDateTime(
            DateTime.parse('2023-01-01 ${horario.horaInicio ?? '09:00'}:00'))
        : TimeOfDay.fromDateTime(
            DateTime.parse('2023-01-01 ${horario.horaFim ?? '18:00'}:00'));

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Colors.brown,
                  ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      final timeString =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

      setState(() {
        final index = _horariosTrabalho.indexWhere(
          (h) => h.diaSemana == horario.diaSemana,
        );
        if (index >= 0) {
          final updatedHorario = HorarioTrabalho(
            id: _horariosTrabalho[index].id,
            profissionalId: _horariosTrabalho[index].profissionalId,
            diaSemana: _horariosTrabalho[index].diaSemana,
            horaInicio: isStartTime
                ? timeString
                : _horariosTrabalho[index].horaInicio,
            horaFim:
                isStartTime ? _horariosTrabalho[index].horaFim : timeString,
            trabalhaNesteDia: _horariosTrabalho[index].trabalhaNesteDia,
            negocioId: _horariosTrabalho[index].negocioId,
            createdAt: _horariosTrabalho[index].createdAt,
            updatedAt: DateTime.now(),
          );
          _horariosTrabalho[index] = updatedHorario;
        } else {
          _horariosTrabalho.add(HorarioTrabalho(
            id: '',
            profissionalId: '',
            diaSemana: horario.diaSemana,
            horaInicio: isStartTime ? timeString : '09:00',
            horaFim: isStartTime ? '18:00' : timeString,
            trabalhaNesteDia: true,
            negocioId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      });
    }
  }

  Future<void> _saveHorarios() async {
    try {
      final horariosAtivos =
          _horariosTrabalho.where((h) => h.trabalhaNesteDia).toList();

      await _apiService.updateHorariosTrabalho(horariosAtivos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horários salvos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadHorarios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar horários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(String time) {
    if (time.length > 5 && time.contains(':')) {
      return time.substring(0, 5);
    }
    return time;
  }

  Widget _buildConfigItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.brown,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor?.withOpacity(0.7) ?? Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: textColor ?? Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _editarPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileEditScreen(),
      ),
    );
  }

  void _showChangePasswordDialog() {
    // Limpar controladores antes de abrir o dialog
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Alterar Senha'),
              content: Form(
                key: _passwordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Senha Atual',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        obscureText: obscureCurrent,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Senha atual é obrigatória';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Nova Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        obscureText: obscureNew,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Nova senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nova Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () => setDialogState(
                                () => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        obscureText: obscureConfirm,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_passwordFormKey.currentState!.validate()) {
                            setDialogState(() => isLoading = true);
                            final authService = context.read<AuthService>();
                            try {
                              await authService.changePassword(
                                _currentPasswordController.text,
                                _newPasswordController.text,
                              );

                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Senha alterada com sucesso!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authService
                                            .getAuthErrorMessage(e) ??
                                        'Erro ao alterar senha'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(() => isLoading = false);
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarSobre() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo/Ícone da empresa
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.brown, width: 2),
              ),
              child: const Center(
                child: Text(
                  'YGG',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do app
            const Text(
              'Barbearia App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Versão: 1.0.0'),
            const SizedBox(height: 8),
            const Text(
              'Sistema de gerenciamento para profissionais de barbearia',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Powered by
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Ygg',
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}