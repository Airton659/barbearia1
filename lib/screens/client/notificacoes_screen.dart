import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/notificacao.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  List<Notificacao> _notificacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificacoes();
  }

  Future<void> _loadNotificacoes() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final notificacoes = await apiService.getNotificacoes();

      setState(() {
        _notificacoes = notificacoes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notificações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          if (_notificacoes.any((n) => !n.lida))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Marcar todas como lidas',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotificacoes,
              child: _notificacoes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma notificação encontrada',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notificacoes.length,
                      itemBuilder: (context, index) {
                        final notificacao = _notificacoes[index];
                        return _buildNotificacaoCard(notificacao);
                      },
                    ),
            ),
    );
  }

  Widget _buildNotificacaoCard(Notificacao notificacao) {
    IconData icon;
    Color iconColor;

    switch (notificacao.tipo) {
      case 'agendamento':
        icon = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'cancelamento':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'lembrete':
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case 'confirmacao':
        icon = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notificacao.lida ? 1 : 3,
      color: notificacao.lida ? null : Colors.blue.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _markAsRead(notificacao),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificacao.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notificacao.lida
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notificacao.lida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificacao.mensagem,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notificacao.tempoRelativo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(Notificacao notificacao) async {
    if (notificacao.lida) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markNotificationAsRead(notificacao.id);

      setState(() {
        final index = _notificacoes.indexWhere((n) => n.id == notificacao.id);
        if (index != -1) {
          _notificacoes[index] = Notificacao(
            id: notificacao.id,
            usuarioId: notificacao.usuarioId,
            titulo: notificacao.titulo,
            mensagem: notificacao.mensagem,
            tipo: notificacao.tipo,
            lida: true,
            dadosAdicionais: notificacao.dadosAdicionais,
            negocioId: notificacao.negocioId,
            createdAt: notificacao.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao marcar notificação como lida: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markAllNotificationsAsRead();

      setState(() {
        _notificacoes = _notificacoes.map((n) => Notificacao(
          id: n.id,
          usuarioId: n.usuarioId,
          titulo: n.titulo,
          mensagem: n.mensagem,
          tipo: n.tipo,
          lida: true,
          dadosAdicionais: n.dadosAdicionais,
          negocioId: n.negocioId,
          createdAt: n.createdAt,
          updatedAt: DateTime.now(),
        )).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas as notificações foram marcadas como lidas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao marcar notificações como lidas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}