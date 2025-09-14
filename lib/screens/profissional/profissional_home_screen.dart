import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/servico.dart';
import '../../models/agendamento.dart';
import '../../models/horario_trabalho.dart';
import 'profile_edit_screen.dart';
import 'profissional_agendamentos_screen.dart';
import '../client/notificacoes_screen.dart';

class ProfissionalHomeScreen extends StatefulWidget {
  const ProfissionalHomeScreen({super.key});

  @override
  State<ProfissionalHomeScreen> createState() => _ProfissionalHomeScreenState();
}

class _ProfissionalHomeScreenState extends State<ProfissionalHomeScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();
  List<Servico> _servicos = [];
  bool _loadingServicos = true;
  List<Agendamento> _agendamentos = [];
  bool _loadingAgendamentos = true;
  List<HorarioTrabalho> _horariosTrabalho = [];
  bool _loadingHorarios = true;
  bool _notificacoesAtivas = true;
  int _unreadNotifications = 0;

  // Controladores para a alteração de senha
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadServicos();
    _loadAgendamentos();
    _loadHorarios();
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

    final pages = [
      const ProfissionalAgendamentosScreen(),
      _buildServicosPage(),
      _buildHorariosPage(),
      _buildConfiguracoesPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, // Aumentei a altura da AppBar
        title: Consumer<AuthService>(
          builder: (context, authService, child) {
            final user = authService.currentUser;
            return Row(
              children: [
                CircleAvatar(
                  radius: 28, // Aumentei o raio do avatar
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: user != null &&
                          user.profileImage != null &&
                          user.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            user.profileImage!,
                            width: 56, // 2 * raio
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 32, // Aumentei o ícone
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 32, // Aumentei o ícone
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Olá, ${user?.nome ?? ''}',
                        style: const TextStyle(
                          fontSize: 20, // Aumentei a fonte
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Permite quebrar em 2 linhas
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
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
        items: const [
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
        ],
      ),
    );
  }

  Widget _buildAgendaPage() {
    if (_loadingAgendamentos) {
      return const Center(child: CircularProgressIndicator());
    }

    final hoje = DateTime.now();
    final agendamentosHoje = _agendamentos.where((a) =>
      DateFormat('yyyy-MM-dd').format(a.dataHora) == DateFormat('yyyy-MM-dd').format(hoje)
    ).toList();

    final proximosAgendamentos = _agendamentos.where((a) =>
      a.dataHora.isAfter(hoje) && !agendamentosHoje.contains(a)
    ).toList();

    return RefreshIndicator(
      onRefresh: _loadAgendamentos,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minha Agenda',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 16),
            if (agendamentosHoje.isNotEmpty) ...[
              Text(
                'Hoje (${DateFormat('dd/MM').format(hoje)})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              ...agendamentosHoje.map((agendamento) => _buildAgendamentoCard(agendamento)),
              const SizedBox(height: 16),
            ],
            if (proximosAgendamentos.isNotEmpty) ...[
              const Text(
                'Próximos Agendamentos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: proximosAgendamentos.length,
                  itemBuilder: (context, index) {
                    return _buildAgendamentoCard(proximosAgendamentos[index]);
                  },
                ),
              ),
            ] else if (agendamentosHoje.isEmpty) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum agendamento encontrado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento) {
    Color statusColor;
    String statusText;

    switch (agendamento.status) {
      case 'agendado':
        statusColor = Colors.blue;
        statusText = 'Agendado';
        break;
      case 'confirmado':
        statusColor = Colors.green;
        statusText = 'Confirmado';
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusText = 'Cancelado';
        break;
      case 'realizado':
        statusColor = Colors.grey;
        statusText = 'Realizado';
        break;
      default:
        statusColor = Colors.grey;
        statusText = agendamento.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Text(
            agendamento.cliente?.nome.isEmpty == true ? '?'
                : agendamento.cliente?.nome[0].toUpperCase() ?? '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          agendamento.cliente?.nome ?? 'Cliente não informado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agendamento.servico?.nome ?? 'Serviço não informado'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: agendamento.status == 'agendado' || agendamento.status == 'confirmado'
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cancel') {
                    _showCancelAgendamentoDialog(agendamento);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cancelar'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

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
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                                  servico.nome.isEmpty ? '?' : servico.nome[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                servico.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (servico.descricao != null && servico.descricao!.isNotEmpty)
                                    Text(servico.descricao!),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${servico.duracao}min'),
                                      const SizedBox(width: 16),
                                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('R\$ ${servico.preco.toStringAsFixed(2)}'),
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
                                        Text('Excluir', style: TextStyle(color: Colors.red)),
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
                                    errorBuilder: (context, error, stackTrace) {
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
                                          : const Icon(Icons.person, color: Colors.brown, size: 30);
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
                                  : const Icon(Icons.person, color: Colors.brown, size: 30),
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
                            content: Text(
                              value
                                ? 'Notificações ativadas'
                                : 'Notificações desativadas'
                            ),
                            backgroundColor: value ? Colors.green : Colors.orange,
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

  Future<void> _showServicoDialog({Servico? servico}) async {
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final descricaoController = TextEditingController(text: servico?.descricao ?? '');
    final duracaoController = TextEditingController(text: servico?.duracao.toString() ?? '');
    final precoController = TextEditingController(text: servico?.preco.toString() ?? '');
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

      print('🔥 Dados do serviço a serem enviados:');
      print('Nome: ${nomeController.text}');
      print('Descrição: ${descricaoController.text}');
      print('Duração: ${duracaoController.text}');
      print('Preço original: ${precoController.text}');
      print('Preço normalizado: $precoNormalizado');

      final novoServico = Servico(
        id: servico?.id ?? '',
        nome: nomeController.text,
        descricao: descricaoController.text.isEmpty ? null : descricaoController.text,
        duracao: int.parse(duracaoController.text),
        preco: double.parse(precoNormalizado),
        profissionalId: '',
        negocioId: '',
        createdAt: servico?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🔥 JSON que será enviado: ${novoServico.toCreateJson()}');

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
      print('🔥 Iniciando criação de serviço...');
      print('🔥 Dados do serviço: ${servico.toCreateJson()}');

      final authService = Provider.of<AuthService>(context, listen: false);
      final profissionalId = authService.currentUser?.id ?? '';

      print('🔥 ID do profissional: $profissionalId');

      final newServico = await _apiService.createServico(servico, profissionalId);

      print('🔥 Serviço criado com sucesso: ${newServico.toJson()}');

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
      print('🔥 ERRO ao criar serviço: $e');
      print('🔥 Tipo do erro: ${e.runtimeType}');

      String errorMessage = 'Erro ao criar serviço';

      if (e.toString().contains('422')) {
        errorMessage = 'Dados inválidos. Verifique os campos e tente novamente.';
        print('🔥 Erro 422 - Dados inválidos enviados para API');
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
      final updatedServico = await _apiService.updateServico(servicoId, servico);
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
        content: Text('Tem certeza que deseja excluir o serviço "${servico.nome}"?'),
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
        print('🔥 Tentando deletar serviço: ${servico.id}');
        await _apiService.deleteServico(servico.id);
        print('🔥 Serviço deletado da API com sucesso!');

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

  Future<void> _showCancelAgendamentoDialog(Agendamento agendamento) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${agendamento.cliente?.nome}'),
              Text('Serviço: ${agendamento.servico?.nome}'),
              Text('Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Agendamento'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _apiService.cancelProfissionalAgendamento(
          agendamento.id,
          motivoController.text,
        );

        await _loadAgendamentos();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento cancelado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar agendamento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    motivoController.dispose();
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
                          profissionalId: _horariosTrabalho[index].profissionalId,
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

  Future<void> _selectTime(BuildContext context, bool isStartTime, HorarioTrabalho horario) async {
    final currentTime = isStartTime
        ? TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 ${horario.horaInicio ?? '09:00'}:00'))
        : TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 ${horario.horaFim ?? '18:00'}:00'));

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
      final timeString = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

      setState(() {
        final index = _horariosTrabalho.indexWhere(
          (h) => h.diaSemana == horario.diaSemana,
        );
        if (index >= 0) {
          final updatedHorario = HorarioTrabalho(
            id: _horariosTrabalho[index].id,
            profissionalId: _horariosTrabalho[index].profissionalId,
            diaSemana: _horariosTrabalho[index].diaSemana,
            horaInicio: isStartTime ? timeString : _horariosTrabalho[index].horaInicio,
            horaFim: isStartTime ? _horariosTrabalho[index].horaFim : timeString,
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
      print('🔥 Salvando horários...');

      // Filtrar apenas os horários onde trabalha_neste_dia = true
      final horariosAtivos = _horariosTrabalho
          .where((h) => h.trabalhaNesteDia)
          .toList();

      print('🔥 Total de horários: ${_horariosTrabalho.length}');
      print('🔥 Horários ativos (trabalha_neste_dia = true): ${horariosAtivos.length}');
      print('🔥 Horários a serem salvos: ${horariosAtivos.map((h) => h.toCreateJson()).toList()}');

      await _apiService.updateHorariosTrabalho(horariosAtivos);

      print('🔥 Horários salvos com sucesso!');

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
      print('🔥 ERRO ao salvar horários: $e');
      print('🔥 Tipo do erro: ${e.runtimeType}');

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
    // Remove segundos se existirem (10:00:00 -> 10:00)
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

  void _configurarNotificacoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificações'),
        content: const Text('Configurações de notificações serão implementadas em breve.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
                            icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
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
                            icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
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
                            icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
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
                  onPressed: isLoading ? null : () async {
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
                              content: Text('Senha alterada com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                         if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authService.getAuthErrorMessage(e) ?? 'Erro ao alterar senha'),
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
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