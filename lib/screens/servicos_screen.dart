import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/servico.dart';
import '../utils/app_colors.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  List<Servico> _servicos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    print('🔍 [SERVICOS] Iniciando carregamento...');
    setState(() { _isLoading = true; });
    try {
      final apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
      final servicos = await apiService.getMeusServicos();
      print('🔍 [SERVICOS] Sucesso: ${servicos.length} serviços carregados');
      setState(() {
        _servicos = servicos;
        _isLoading = false;
      });
    } catch (e) {
      print('🔍 [SERVICOS] ERRO: $e');
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar serviços: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showServicoDialog({Servico? servico}) async {
    final isEdit = servico != null;
    final nomeController = TextEditingController(text: servico?.nome ?? '');
    final descricaoController = TextEditingController(text: servico?.descricao ?? '');
    final precoController = TextEditingController(text: servico?.preco.toString() ?? '');
    final duracaoController = TextEditingController(text: servico?.duracaoMinutos.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Editar Serviço' : 'Novo Serviço'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: duracaoController,
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos)',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isEmpty ||
                  precoController.text.isEmpty ||
                  duracaoController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
                );
                return;
              }

              try {
                final servicoData = {
                  'nome': nomeController.text,
                  'descricao': descricaoController.text,
                  'preco': double.parse(precoController.text.replaceAll(',', '.')),
                  'duracao_minutos': int.parse(duracaoController.text),
                  'ativo': true,
                };

                print('🔍 [SERVICOS] ${isEdit ? 'Atualizando' : 'Criando'} serviço...');
                print('🔍 [SERVICOS] Dados: $servicoData');

                final apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
                if (isEdit) {
                  print('🔍 [SERVICOS] ID do serviço: ${servico!.id}');
                  await apiService.updateServico(servico.id, servicoData);
                  print('🔍 [SERVICOS] Serviço atualizado com sucesso!');
                } else {
                  await apiService.createServico(servicoData);
                  print('🔍 [SERVICOS] Serviço criado com sucesso!');
                }

                Navigator.pop(context, true);
              } catch (e) {
                print('🔍 [SERVICOS] ERRO ao salvar: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao salvar serviço: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? 'Atualizar' : 'Criar'),
          ),
        ],
      ),
    );

    if (result == true) {
      _carregarServicos();
    }
  }

  Future<void> _confirmarExclusao(Servico servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o serviço "${servico.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🔍 [SERVICOS] Excluindo serviço ID: ${servico.id}');
        final apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
        await apiService.deleteServico(servico.id);
        print('🔍 [SERVICOS] Serviço excluído com sucesso!');
        _carregarServicos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço excluído com sucesso')),
          );
        }
      } catch (e) {
        print('🔍 [SERVICOS] ERRO ao excluir: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir serviço: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Serviços'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showServicoDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarServicos,
              child: _servicos.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _servicos.length,
                      itemBuilder: (context, index) {
                        final servico = _servicos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.room_service,
                                color: AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              servico.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (servico.descricao.isNotEmpty) ...[
                                  Text(servico.descricao),
                                  const SizedBox(height: 4),
                                ],
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
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: servico.ativo
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        servico.ativo ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: servico.ativo
                                              ? AppColors.success
                                              : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Editar'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, color: AppColors.error),
                                    title: Text('Excluir'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _showServicoDialog(servico: servico);
                                    break;
                                  case 'delete':
                                    _confirmarExclusao(servico);
                                    break;
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.room_service_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum serviço encontrado',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre seus serviços para começar',
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showServicoDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Serviço'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}