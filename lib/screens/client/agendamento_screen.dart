import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/usuario.dart';
import '../../models/servico.dart';
import '../../models/agendamento.dart';
import '../../models/horario_disponivel.dart';
import '../../utils/app_constants.dart';

class AgendamentoScreen extends StatefulWidget {
  final Usuario? profissionalSelecionado;

  const AgendamentoScreen({
    super.key,
    this.profissionalSelecionado,
  });

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  List<Usuario> _profissionais = [];
  List<Servico> _servicos = [];
  List<HorarioDisponivel> _horariosDisponiveis = [];

  Usuario? _profissionalSelecionado;
  Servico? _servicoSelecionado;
  DateTime? _dataSelecionada;
  HorarioDisponivel? _horarioSelecionado;

  bool _isLoading = false;
  bool _isLoadingHorarios = false;

  @override
  void initState() {
    super.initState();
    _profissionalSelecionado = widget.profissionalSelecionado;
    _loadProfissionais();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfissionais() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profissionais = await apiService.getProfissionais();

      setState(() {
        _profissionais = profissionais;
        _isLoading = false;
      });

      if (_profissionalSelecionado != null) {
        _loadServicosProfissional(_profissionalSelecionado!.id);
        _nextStep();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar barbeiros: $e');
    }
  }

  Future<void> _loadServicosProfissional(String profissionalId) async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Buscar os serviços reais do profissional
      final servicos = await apiService.getServicosProfissional(profissionalId);

      setState(() {
        _servicos = servicos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erro ao carregar serviços: $e');
    }
  }

  Future<void> _loadHorarios(DateTime data) async {
    if (_profissionalSelecionado == null || _servicoSelecionado == null) return;

    setState(() => _isLoadingHorarios = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final horarios = await apiService.getHorariosDisponiveis(
        _profissionalSelecionado!.id,
        DateFormat('yyyy-MM-dd').format(data),
        _servicoSelecionado!.duracao,
      );

      setState(() {
        _horariosDisponiveis = horarios;
        _isLoadingHorarios = false;
      });
    } catch (e) {
      setState(() => _isLoadingHorarios = false);
      _showError('Erro ao carregar horários: $e');
    }
  }

  void _nextStep() {
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
    if (_profissionalSelecionado == null ||
        _servicoSelecionado == null ||
        _horarioSelecionado == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final agendamento = Agendamento(
        id: '',
        clienteId: authService.currentUser!.id,
        profissionalId: _profissionalSelecionado!.id,
        servicoId: _servicoSelecionado!.id,
        dataHora: _horarioSelecionado!.dataHora,
        status: AppConstants.statusAgendado,
        negocioId: AppConstants.negocioId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await apiService.createAgendamento(agendamento);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Erro ao agendar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Agendamento'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicador de progresso
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? Colors.brown : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Conteúdo das páginas
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildProfissionalStep(),
                _buildServicoStep(),
                _buildDataHoraStep(),
                _buildConfirmacaoStep(),
              ],
            ),
          ),

          // Botões de navegação
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
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_getNextButtonText()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfissionalStep() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha um barbeiro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _profissionais.length,
              itemBuilder: (context, index) {
                final profissional = _profissionais[index];
                final isSelected = _profissionalSelecionado?.id == profissional.id;

                return Card(
                  color: isSelected ? Colors.brown.shade50 : null,
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
                    subtitle: const Text('Barbeiro'),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.brown)
                        : null,
                    onTap: () {
                      setState(() {
                        _profissionalSelecionado = profissional;
                        _servicoSelecionado = null; // Reset service selection
                      });
                      _loadServicosProfissional(profissional.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicoStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha um serviço',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_servicos.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Nenhum serviço disponível para este barbeiro',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _servicos.length,
                itemBuilder: (context, index) {
                  final servico = _servicos[index];
                  final isSelected = _servicoSelecionado?.id == servico.id;

                  return Card(
                    color: isSelected ? Colors.brown.shade50 : null,
                    child: ListTile(
                      title: Text(servico.nome),
                      subtitle: Text(
                        '${servico.duracao} min - R\$ ${servico.preco.toStringAsFixed(2)}',
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: Colors.brown)
                          : null,
                      onTap: () {
                        setState(() {
                          _servicoSelecionado = servico;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataHoraStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Escolha data e horário',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Calendário
          CalendarDatePicker(
            initialDate: DateTime.now().add(const Duration(days: 1)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: (date) {
              setState(() {
                _dataSelecionada = date;
                _horarioSelecionado = null;
              });
              _loadHorarios(date);
            },
          ),

          const SizedBox(height: 16),

          // Horários disponíveis
          if (_dataSelecionada != null) ...[
            const Text(
              'Horários disponíveis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingHorarios)
              const Center(child: CircularProgressIndicator())
            else if (_horariosDisponiveis.isEmpty)
              const Text(
                'Nenhum horário disponível para esta data',
                style: TextStyle(color: Colors.grey),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _horariosDisponiveis.length,
                  itemBuilder: (context, index) {
                    final horario = _horariosDisponiveis[index];
                    final isSelected = _horarioSelecionado?.dataHora == horario.dataHora;

                    return GestureDetector(
                      onTap: horario.disponivel
                          ? () {
                              setState(() {
                                _horarioSelecionado = horario;
                              });
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: !horario.disponivel
                              ? Colors.grey.shade300
                              : isSelected
                                  ? Colors.brown
                                  : Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.brown : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            horario.horaFormatada,
                            style: TextStyle(
                              color: !horario.disponivel
                                  ? Colors.grey
                                  : isSelected
                                      ? Colors.white
                                      : Colors.brown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmacaoStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmar agendamento',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfirmacaoItem(
                    'Barbeiro',
                    _profissionalSelecionado?.nome ?? '',
                    Icons.person,
                  ),
                  const Divider(),
                  _buildConfirmacaoItem(
                    'Serviço',
                    _servicoSelecionado?.nome ?? '',
                    Icons.cut,
                  ),
                  const Divider(),
                  _buildConfirmacaoItem(
                    'Data',
                    _dataSelecionada != null
                        ? DateFormat('dd/MM/yyyy').format(_dataSelecionada!)
                        : '',
                    Icons.calendar_today,
                  ),
                  const Divider(),
                  _buildConfirmacaoItem(
                    'Horário',
                    _horarioSelecionado?.horaFormatada ?? '',
                    Icons.access_time,
                  ),
                  const Divider(),
                  _buildConfirmacaoItem(
                    'Preço',
                    'R\$ ${_servicoSelecionado?.preco.toStringAsFixed(2) ?? '0,00'}',
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmacaoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentStep) {
      case 0:
        return _profissionalSelecionado != null ? _nextStep : null;
      case 1:
        return _servicoSelecionado != null ? _nextStep : null;
      case 2:
        return _horarioSelecionado != null ? _nextStep : null;
      case 3:
        return _confirmarAgendamento;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
        return 'Continuar';
      case 3:
        return 'Confirmar Agendamento';
      default:
        return 'Continuar';
    }
  }
}