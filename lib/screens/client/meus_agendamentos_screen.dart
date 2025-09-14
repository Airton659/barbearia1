import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/agendamento.dart';

class MeusAgendamentosScreen extends StatefulWidget {
  const MeusAgendamentosScreen({super.key});

  @override
  State<MeusAgendamentosScreen> createState() => _MeusAgendamentosScreenState();
}

class _MeusAgendamentosScreenState extends State<MeusAgendamentosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Agendamento> _agendamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAgendamentos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAgendamentos() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final agendamentos = await apiService.getMyAgendamentos();

      setState(() {
        _agendamentos = agendamentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  List<Agendamento> get _proximosAgendamentos {
    return _agendamentos
        .where((a) => a.isProximo && !a.isCancelado)
        .toList()
      ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  List<Agendamento> get _historicoAgendamentos {
    return _agendamentos
        .where((a) => !a.isProximo || a.isCancelado)
        .toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.brown,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.brown,
          tabs: const [
            Tab(text: 'Próximos'),
            Tab(text: 'Histórico'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAgendamentos,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAgendamentosList(_proximosAgendamentos, true),
                      _buildAgendamentosList(_historicoAgendamentos, false),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAgendamentosList(List<Agendamento> agendamentos, bool isProximos) {
    if (agendamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isProximos ? Icons.calendar_today : Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isProximos
                  ? 'Nenhum agendamento próximo'
                  : 'Nenhum histórico encontrado',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agendamentos.length,
      itemBuilder: (context, index) {
        final agendamento = agendamentos[index];
        return _buildAgendamentoCard(agendamento, isProximos);
      },
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento, bool isProximo) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (agendamento.status.toLowerCase()) {
      case 'agendado':
        statusColor = Colors.blue;
        statusText = 'Agendado';
        statusIcon = Icons.schedule;
        break;
      case 'pendente':
        statusColor = Colors.orange;
        statusText = 'Pendente';
        statusIcon = Icons.pending;
        break;
      case 'confirmado':
        statusColor = Colors.green;
        statusText = 'Confirmado';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelado':
        statusColor = Colors.red;
        statusText = 'Cancelado';
        statusIcon = Icons.cancel;
        break;
      case 'realizado':
        statusColor = Colors.green;
        statusText = 'Realizado';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = agendamento.statusDisplay;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    agendamento.profissional?.nome ?? 'Barbeiro',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              agendamento.servico?.nome ?? 'Serviço',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(agendamento.dataHora),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(agendamento.dataHora),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (agendamento.servico != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'R\$ ${agendamento.servico!.preco.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (agendamento.motivoCancelamento != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motivo: ${agendamento.motivoCancelamento}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isProximo && agendamento.isAgendado) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelarAgendamento(agendamento),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Cancelar Agendamento'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarAgendamento(Agendamento agendamento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text(
          'Tem certeza que deseja cancelar este agendamento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.cancelAgendamento(agendamento.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento cancelado com sucesso'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAgendamentos();
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
  }
}