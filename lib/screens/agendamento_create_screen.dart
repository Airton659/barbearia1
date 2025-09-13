import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/servico.dart';
import '../models/usuario.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';

class AgendamentoCreateScreen extends StatefulWidget {
  final Servico servico;
  final List<Usuario> profissionais;

  const AgendamentoCreateScreen({
    super.key,
    required this.servico,
    required this.profissionais,
  });

  @override
  State<AgendamentoCreateScreen> createState() => _AgendamentoCreateScreenState();
}

class _AgendamentoCreateScreenState extends State<AgendamentoCreateScreen> {
  final ApiService _apiService = ApiService();
  final _observacoesController = TextEditingController();

  Usuario? _profissionalSelecionado;
  DateTime? _dataSelecionada;
  DateTime? _horarioSelecionado;
  List<DateTime> _horariosDisponiveis = [];
  bool _isLoadingHorarios = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Selecionar o primeiro profissional que oferece este serviço
    final profissionaisServico = widget.profissionais
        .where((p) => p.role == 'profissional' && p.ativo)
        .toList();
    
    if (profissionaisServico.isNotEmpty) {
      _profissionalSelecionado = profissionaisServico.first;
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
        _horarioSelecionado = null;
        _horariosDisponiveis = [];
      });
      _carregarHorarios();
    }
  }

  Future<void> _carregarHorarios() async {
    if (_profissionalSelecionado == null || _dataSelecionada == null) return;

    setState(() {
      _isLoadingHorarios = true;
    });

    try {
      final horarios = await _apiService.getHorariosDisponiveis(
        _profissionalSelecionado!.id,
        widget.servico.id,
        _dataSelecionada!,
      );

      setState(() {
        _horariosDisponiveis = horarios;
        _isLoadingHorarios = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHorarios = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar horários: $e')),
        );
      }
    }
  }

  Future<void> _confirmarAgendamento() async {
    if (_profissionalSelecionado == null ||
        _dataSelecionada == null ||
        _horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione todos os dados necessários')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiService.createAgendamento({
        'profissional_id': _profissionalSelecionado!.id,
        'servico_id': widget.servico.id,
        'data_hora': _horarioSelecionado!.toIso8601String(),
        'preco': widget.servico.preco,
        'observacoes': _observacoesController.text.isNotEmpty 
            ? _observacoesController.text 
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento realizado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao agendar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Serviço'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do Serviço
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Serviço Selecionado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.content_cut,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.servico.nome,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.servico.descricao,
                                style: const TextStyle(
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    widget.servico.precoFormatado,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    widget.servico.duracaoFormatada,
                                    style: const TextStyle(
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Seleção do Profissional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione o Profissional',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Usuario>(
                      initialValue: _profissionalSelecionado,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: widget.profissionais
                          .where((p) => p.role == 'profissional' && p.ativo)
                          .map((profissional) => DropdownMenuItem(
                                value: profissional,
                                child: Text(profissional.nome),
                              ))
                          .toList(),
                      onChanged: (profissional) {
                        setState(() {
                          _profissionalSelecionado = profissional;
                          _dataSelecionada = null;
                          _horarioSelecionado = null;
                          _horariosDisponiveis = [];
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Seleção da Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecione a Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _profissionalSelecionado != null ? _selecionarData : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 12),
                            Text(
                              _dataSelecionada != null
                                  ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataSelecionada!)
                                  : 'Toque para selecionar uma data',
                              style: TextStyle(
                                color: _dataSelecionada != null
                                    ? AppColors.textDark
                                    : AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Seleção do Horário
            if (_dataSelecionada != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecione o Horário',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingHorarios)
                        const Center(child: CircularProgressIndicator())
                      else if (_horariosDisponiveis.isEmpty)
                        const Center(
                          child: Text(
                            'Nenhum horário disponível para esta data',
                            style: TextStyle(color: AppColors.textMedium),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _horariosDisponiveis.map((horario) {
                            final isSelected = _horarioSelecionado == horario;
                            return ChoiceChip(
                              label: Text(DateFormat('HH:mm').format(horario)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _horarioSelecionado = selected ? horario : null;
                                });
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              backgroundColor: Colors.grey.shade100,
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Observações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observações (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacoesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Alguma observação específica?',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botão Confirmar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _confirmarAgendamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmar Agendamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }
}