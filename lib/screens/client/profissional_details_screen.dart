import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/servico.dart';
import 'agendamento_screen.dart';

class ProfissionalDetailsScreen extends StatefulWidget {
  final Usuario profissional;

  const ProfissionalDetailsScreen({
    super.key,
    required this.profissional,
  });

  @override
  State<ProfissionalDetailsScreen> createState() => _ProfissionalDetailsScreenState();
}

class _ProfissionalDetailsScreenState extends State<ProfissionalDetailsScreen> {
  List<Servico> _servicos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServicos();
  }

  Future<void> _loadServicos() async {
    setState(() => _isLoading = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Buscar os serviços do profissional
      _servicos = await apiService.getServicosProfissional(widget.profissional.id);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar serviços: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profissional.nome),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServicos,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header com informações do profissional
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.brown.shade100,
                              backgroundImage: widget.profissional.profileImage != null && widget.profissional.profileImage!.isNotEmpty
                                  ? NetworkImage(widget.profissional.profileImage!)
                                  : null,
                              onBackgroundImageError: widget.profissional.profileImage != null && widget.profissional.profileImage!.isNotEmpty
                                  ? (exception, stackTrace) {
                                      print('Erro ao carregar imagem do profissional ${widget.profissional.nome}: $exception');
                                    }
                                  : null,
                              child: widget.profissional.profileImage == null || widget.profissional.profileImage!.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.brown.shade700,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.profissional.nome,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Profissional',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Lista de serviços
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Serviços Oferecidos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_servicos.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.content_cut,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhum serviço disponível no momento',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Este profissional ainda não cadastrou seus serviços.',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _servicos.length,
                        itemBuilder: (context, index) {
                          final servico = _servicos[index];
                          return _buildServicoCard(servico);
                        },
                      ),

                    // Placeholder enquanto não temos serviços reais - mostrar alguns exemplos
                    if (_servicos.isEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Serviços Típicos:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPlaceholderServicoCard('Corte Masculino', 30, 25.0),
                      _buildPlaceholderServicoCard('Barba', 20, 15.0),
                      _buildPlaceholderServicoCard('Corte + Barba', 45, 35.0),
                      _buildPlaceholderServicoCard('Degradê', 40, 30.0),
                    ],
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AgendamentoScreen(
                profissionalSelecionado: widget.profissional,
              ),
            ),
          );
        },
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calendar_month),
        label: Text('Agendar com ${widget.profissional.nome.split(' ').first}'),
      ),
    );
  }

  Widget _buildServicoCard(Servico servico) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.content_cut,
            color: Colors.brown.shade700,
          ),
        ),
        title: Text(
          servico.nome,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (servico.descricao != null && servico.descricao!.isNotEmpty)
              Text(servico.descricao!),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${servico.duracao} min'),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${servico.preco.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: servico.descricao != null && servico.descricao!.isNotEmpty,
      ),
    );
  }

  Widget _buildPlaceholderServicoCard(String nome, int duracao, double preco) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.content_cut,
            color: Colors.grey.shade400,
          ),
        ),
        title: Text(
          nome,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text('$duracao min', style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(width: 16),
            Icon(Icons.attach_money, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'R\$ ${preco.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        enabled: false,
      ),
    );
  }
}