import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/usuario.dart';
import '../../models/servico.dart';
import '../../models/horario_disponivel.dart';
import '../../models/agendamento.dart';
import '../../utils/app_constants.dart';

class AgendamentoPorHorarioScreen extends StatefulWidget {
  const AgendamentoPorHorarioScreen({super.key});

  @override
  State<AgendamentoPorHorarioScreen> createState() => _AgendamentoPorHorarioScreenState();
}

class _AgendamentoPorHorarioScreenState extends State<AgendamentoPorHorarioScreen> {
  PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Escolher serviço
  List<Servico> _servicos = [];
  Servico? _servicoSelecionado;

  // Step 2: Escolher data
  DateTime? _dataSelecionada;

  // Step 3: Escolher horário e profissional
  List<Map<String, dynamic>> _horariosDisponiveis = [];
  String? _horarioSelecionado;
  Usuario? _profissionalSelecionado;

  bool _isLoading = false;
  bool _isCreatingAppointment = false;

  @override
  void initState() {
    super.initState();
    print('🔥 AgendamentoPorHorarioScreen: initState chamado');
    _loadServicos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadServicos() async {
    print('🔥 AgendamentoPorHorarioScreen: _loadServicos chamado');
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Buscar todos os serviços únicos de todos os profissionais
      print('🔥 AgendamentoPorHorarioScreen: Buscando serviços únicos...');
      _servicos = await apiService.getAllServicosUnicos();
      print('🔥 AgendamentoPorHorarioScreen: Serviços carregados: ${_servicos.length}');
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

  Future<void> _loadHorariosDisponiveis() async {
    if (_dataSelecionada == null || _servicoSelecionado == null) return;

    print('🔥 Iniciando busca de horários para data: ${_dataSelecionada!.toIso8601String().split('T')[0]} e serviço: ${_servicoSelecionado!.nome}');

    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profissionais = await apiService.getProfissionais();

      print('🔥 Profissionais encontrados: ${profissionais.length}');
      for (final prof in profissionais) {
        print('🔥 Profissional: ${prof.nome} (ID: ${prof.id})');
      }

      _horariosDisponiveis.clear();

      // Para cada profissional, buscar horários disponíveis
      for (final profissional in profissionais) {
        try {
          print('🔥 Buscando horários para ${profissional.nome}...');
          final horarios = await apiService.getHorariosDisponiveis(
            profissional.id,
            _dataSelecionada!.toIso8601String().split('T')[0],
            _servicoSelecionado!.duracao,
          );

          print('🔥 Horários retornados para ${profissional.nome}: ${horarios.length}');
          for (final h in horarios) {
            print('🔥 Horário: ${h.horaFormatada} - Disponível: ${h.disponivel}');
          }

          for (final horario in horarios) {
            if (horario.disponivel) {
              _horariosDisponiveis.add({
                'horario': horario.horaFormatada,
                'dataHora': horario.dataHora,
                'profissional': profissional,
              });
            }
          }
        } catch (e) {
          // Mostrar erro específico para cada profissional
          print('🔥 ERRO detalhado ao carregar horários para ${profissional.nome}: $e');
          print('🔥 Stack trace: ${StackTrace.current}');
        }
      }

      print('🔥 Total de horários disponíveis encontrados: ${_horariosDisponiveis.length}');

      // Ordenar por horário usando DateTime para garantir ordenação correta
      _horariosDisponiveis.sort((a, b) {
        final dateTimeA = a['dataHora'] as DateTime;
        final dateTimeB = b['dataHora'] as DateTime;
        return dateTimeA.compareTo(dateTimeB);
      });

    } catch (e) {
      print('🔥 ERRO GERAL ao carregar horários: $e');
      print('🔥 Stack trace geral: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar horários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 1 && _dataSelecionada != null) {
      _loadHorariosDisponiveis();
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmarAgendamento() async {
    print('🔥 Confirmar agendamento iniciado');
    print('🔥 Serviço selecionado: ${_servicoSelecionado?.nome} (${_servicoSelecionado?.id})');
    print('🔥 Data selecionada: $_dataSelecionada');
    print('🔥 Horário selecionado: $_horarioSelecionado');
    print('🔥 Profissional selecionado: ${_profissionalSelecionado?.nome} (${_profissionalSelecionado?.id})');

    if (_servicoSelecionado == null ||
        _dataSelecionada == null ||
        _horarioSelecionado == null ||
        _profissionalSelecionado == null) {
      print('🔥 ERRO: Algum campo obrigatório está nulo');
      return;
    }

    setState(() => _isCreatingAppointment = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Criar data/hora completa
      print('🔥 Convertendo horário: $_horarioSelecionado');
      final timeComponents = _horarioSelecionado!.split(':');
      final dataHora = DateTime(
        _dataSelecionada!.year,
        _dataSelecionada!.month,
        _dataSelecionada!.day,
        int.parse(timeComponents[0]),
        int.parse(timeComponents[1]),
      );
      print('🔥 Data/hora completa criada: $dataHora');

      final agendamento = Agendamento(
        id: '',
        clienteId: '',
        profissionalId: _profissionalSelecionado!.id,
        servicoId: _servicoSelecionado!.id,
        negocioId: AppConstants.negocioId,  // Usar constante correta
        dataHora: dataHora,
        status: 'agendado',
        motivoCancelamento: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cliente: null,
        profissional: _profissionalSelecionado,
        servico: _servicoSelecionado,
      );

      print('🔥 Agendamento criado, enviando para API...');
      await apiService.createAgendamento(agendamento);
      print('🔥 Agendamento salvo com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar agendamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingAppointment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontrar Horário'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stepper indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Serviço'),
                Expanded(child: Container(height: 2, color: _currentStep > 0 ? Colors.brown : Colors.grey.shade300)),
                _buildStepIndicator(1, 'Data'),
                Expanded(child: Container(height: 2, color: _currentStep > 1 ? Colors.brown : Colors.grey.shade300)),
                _buildStepIndicator(2, 'Horário'),
                Expanded(child: Container(height: 2, color: _currentStep > 2 ? Colors.brown : Colors.grey.shade300)),
                _buildStepIndicator(3, 'Confirmar'),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServicoStep(),
                _buildDataStep(),
                _buildHorarioStep(),
                _buildConfirmacaoStep(),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Voltar'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getNextButtonAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    child: _getNextButtonChild(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Container(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.brown : Colors.grey.shade300,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.brown : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicoStep() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha o Serviço',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecione o tipo de serviço que você deseja',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _servicos.length,
                  itemBuilder: (context, index) {
                    final servico = _servicos[index];
                    return Card(
                      child: RadioListTile<Servico>(
                        value: servico,
                        groupValue: _servicoSelecionado,
                        onChanged: (value) {
                          setState(() => _servicoSelecionado = value);
                        },
                        title: Text(servico.nome),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (servico.descricao != null)
                              Text(servico.descricao!),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 16),
                                const SizedBox(width: 4),
                                Text('${servico.duracao} min'),
                                const SizedBox(width: 16),
                                const Icon(Icons.attach_money, size: 16),
                                const SizedBox(width: 4),
                                Text('R\$ ${servico.preco.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: servico.descricao != null,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildDataStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha a Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione o dia para seu agendamento',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            child: CalendarDatePicker(
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
              onDateChanged: (date) {
                setState(() => _dataSelecionada = date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioStep() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha o Horário e Profissional',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Horários disponíveis para o dia selecionado',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (_horariosDisponiveis.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Nenhum horário disponível para este dia. Tente outra data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _horariosDisponiveis.length,
                    itemBuilder: (context, index) {
                      final item = _horariosDisponiveis[index];
                      final horario = item['horario'] as String;
                      final profissional = item['profissional'] as Usuario;
                      final isSelected = _horarioSelecionado == horario &&
                                       _profissionalSelecionado?.id == profissional.id;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown.shade100,
                            backgroundImage: profissional.profileImage != null && profissional.profileImage!.isNotEmpty
                                ? NetworkImage(profissional.profileImage!)
                                : null,
                            onBackgroundImageError: profissional.profileImage != null && profissional.profileImage!.isNotEmpty
                                ? (exception, stackTrace) {
                                    print('Erro ao carregar imagem do profissional ${profissional.nome}: $exception');
                                  }
                                : null,
                            child: profissional.profileImage == null || profissional.profileImage!.isEmpty
                                ? Icon(Icons.person, color: Colors.brown.shade700)
                                : null,
                          ),
                          title: Text(profissional.nome),
                          subtitle: Text('Disponível às $horario'),
                          trailing: Radio<String>(
                            value: '${horario}_${profissional.id}',
                            groupValue: _horarioSelecionado != null && _profissionalSelecionado != null
                                ? '${_horarioSelecionado}_${_profissionalSelecionado!.id}'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _horarioSelecionado = horario;
                                _profissionalSelecionado = profissional;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _horarioSelecionado = horario;
                              _profissionalSelecionado = profissional;
                            });
                          },
                          selected: isSelected,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
  }

  Widget _buildConfirmacaoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmar Agendamento',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique os detalhes do seu agendamento',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmationRow('Serviço', _servicoSelecionado?.nome ?? ''),
                  _buildConfirmationRow('Duração', '${_servicoSelecionado?.duracao ?? 0} minutos'),
                  _buildConfirmationRow('Preço', 'R\$ ${_servicoSelecionado?.preco.toStringAsFixed(2) ?? '0.00'}'),
                  const Divider(),
                  _buildConfirmationRow('Data', _dataSelecionada != null
                      ? '${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'
                      : ''),
                  _buildConfirmationRow('Horário', _horarioSelecionado ?? ''),
                  _buildConfirmationRow('Profissional', _profissionalSelecionado?.nome ?? ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentStep) {
      case 0:
        return _servicoSelecionado != null ? _nextStep : null;
      case 1:
        return _dataSelecionada != null ? _nextStep : null;
      case 2:
        return _horarioSelecionado != null && _profissionalSelecionado != null ? _nextStep : null;
      case 3:
        return !_isCreatingAppointment ? _confirmarAgendamento : null;
      default:
        return null;
    }
  }

  Widget _getNextButtonChild() {
    if (_currentStep == 3) {
      return _isCreatingAppointment
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              'Confirmar Agendamento',
              style: TextStyle(fontSize: 14),
            );
    }
    return const Text('Continuar');
  }
}