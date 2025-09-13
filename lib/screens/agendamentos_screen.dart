import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/agendamento.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  List<Agendamento> _agendamentos = [];
  bool _isLoading = true;
  String _filtroStatus = 'todos';

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    print('🔍 [AGENDAMENTOS] Iniciando carregamento...');
    setState(() { _isLoading = true; });
    try {
      final apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
      final agendamentos = await apiService.getAgendamentosProfissional();
      print('🔍 [AGENDAMENTOS] Sucesso: ${agendamentos.length} agendamentos carregados');
      setState(() {
        _agendamentos = agendamentos;
        _isLoading = false;
      });
    } catch (e) {
      print('🔍 [AGENDAMENTOS] ERRO: $e');
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar agendamentos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Agendamento> get _agendamentosFiltrados {
    if (_filtroStatus == 'todos') {
      return _agendamentos;
    }
    return _agendamentos.where((a) => a.status == _filtroStatus).toList();
  }

  Future<void> _cancelarAgendamento(Agendamento agendamento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Text(
          'Tem certeza que deseja cancelar o agendamento de ${agendamento.clienteNome ?? 'Cliente'} para ${DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🔍 [AGENDAMENTOS] Cancelando agendamento ID: ${agendamento.id}');
        final apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
        await apiService.cancelarAgendamentoProfissional(agendamento.id);
        print('🔍 [AGENDAMENTOS] Agendamento cancelado com sucesso!');
        _carregarAgendamentos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento cancelado com sucesso')),
          );
        }
      } catch (e) {
        print('🔍 [AGENDAMENTOS] ERRO ao cancelar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cancelar agendamento: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'agendado':
        return AppColors.info;
      case 'concluido':
        return AppColors.success;
      case 'cancelado':
        return AppColors.error;
      case 'em_andamento':
        return AppColors.warning;
      default:
        return AppColors.textMedium;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'agendado':
        return 'Agendado';
      case 'concluido':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case 'em_andamento':
        return 'Em Andamento';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todos', 'todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Agendados', 'agendado'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Concluídos', 'concluido'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cancelados', 'cancelado'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarAgendamentos,
              child: _agendamentosFiltrados.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _agendamentosFiltrados.length,
                      itemBuilder: (context, index) {
                        final agendamento = _agendamentosFiltrados[index];
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
                                    Expanded(
                                      child: Text(
                                        agendamento.clienteNome ?? 'Cliente',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(agendamento.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(agendamento.status),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getStatusColor(agendamento.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.room_service, size: 16, color: AppColors.textMedium),
                                    const SizedBox(width: 4),
                                    Text(
                                      agendamento.servicoNome ?? 'Serviço',
                                      style: const TextStyle(color: AppColors.textMedium),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 16, color: AppColors.textMedium),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora),
                                      style: const TextStyle(color: AppColors.textMedium),
                                    ),
                                    if (agendamento.servicoDuracao != null) ...[
                                      const SizedBox(width: 16),
                                      const Icon(Icons.timer, size: 16, color: AppColors.textMedium),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${agendamento.servicoDuracao}min',
                                        style: const TextStyle(color: AppColors.textMedium),
                                      ),
                                    ],
                                  ],
                                ),
                                if (agendamento.preco != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 16, color: AppColors.textMedium),
                                      const SizedBox(width: 4),
                                      Text(
                                        agendamento.precoFormatado,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (agendamento.observacoes != null && agendamento.observacoes!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    width: double.infinity,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Observações:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMedium,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          agendamento.observacoes!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (agendamento.status == 'agendado' && agendamento.podeSerCancelado) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _cancelarAgendamento(agendamento),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                        ),
                                        child: const Text('Cancelar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroStatus = value;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _filtroStatus == 'todos' 
              ? 'Nenhum agendamento encontrado'
              : 'Nenhum agendamento ${_getStatusText(_filtroStatus).toLowerCase()}',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Os agendamentos aparecerão aqui',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}