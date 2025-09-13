import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../models/agendamento.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'agendamento_create_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  List<Servico> _servicos = [];
  List<Usuario> _profissionais = [];
  List<Agendamento> _meusAgendamentos = [];
  bool _isLoading = true;
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final futures = await Future.wait([
        _apiService.getProfile(),
        _apiService.getServicos(),
        _apiService.getProfissionais(),
        _apiService.getMeusAgendamentos(),
      ]);

      setState(() {
        _nomeUsuario = (futures[0] as Usuario).nome;
        _servicos = futures[1] as List<Servico>;
        _profissionais = futures[2] as List<Usuario>;
        _meusAgendamentos = futures[3] as List<Agendamento>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Barbearia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => <PopupMenuEntry>[
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_nomeUsuario),
                  subtitle: const Text('Cliente'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: _logout,
                child: const ListTile(
                  leading: Icon(Icons.logout, color: AppColors.error),
                  title: Text('Sair'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boas-vindas
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $_nomeUsuario!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agende seu próximo corte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Meus Agendamentos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meus Agendamentos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_meusAgendamentos.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        // TODO: Ver todos os agendamentos
                      },
                      child: const Text('Ver todos'),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              if (_meusAgendamentos.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum agendamento encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Que tal agendar seu próximo corte?',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _meusAgendamentos.length,
                    itemBuilder: (context, index) {
                      final agendamento = _meusAgendamentos[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  agendamento.servicoNome ?? 'Serviço',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  agendamento.profissionalNome ?? 'Profissional',
                                  style: const TextStyle(
                                    color: AppColors.textMedium,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${agendamento.dataHora.day}/${agendamento.dataHora.month} ${agendamento.dataHora.hour}:${agendamento.dataHora.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: agendamento.status == 'agendado'
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    agendamento.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: agendamento.status == 'agendado'
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 32),

              // Serviços Disponíveis
              Text(
                'Nossos Serviços',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _servicos.length,
                itemBuilder: (context, index) {
                  final servico = _servicos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.content_cut,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(servico.nome),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(servico.descricao),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                servico.precoFormatado,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                servico.duracaoFormatada,
                                style: const TextStyle(
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AgendamentoCreateScreen(
                                servico: servico,
                                profissionais: _profissionais,
                              ),
                            ),
                          ).then((_) => _carregarDados());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Agendar'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}