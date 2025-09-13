import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/horario_trabalho.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class HorariosTrabalhoScreen extends StatefulWidget {
  const HorariosTrabalhoScreen({super.key});

  @override
  State<HorariosTrabalhoScreen> createState() => _HorariosTrabalhoScreenState();
}

class _HorariosTrabalhoScreenState extends State<HorariosTrabalhoScreen> {
  late final ApiService _apiService;
  bool _isLoading = true;
  String _error = '';
  List<HorarioTrabalho> _horarios = [];

  // Mapa para agrupar horários por dia da semana
  Map<int, List<HorarioTrabalho>> _horariosPorDia = {};

  @override
  void initState() {
    super.initState();
    // Defer ApiService initialization to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiService = ApiService(authService: Provider.of<AuthService>(context, listen: false));
    _carregarHorarios();
  }

  Future<void> _carregarHorarios() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final horarios = await _apiService.getHorariosTrabalho();
      setState(() {
        _horarios = horarios;
        _agruparHorariosPorDia();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar horários: $e';
        _isLoading = false;
      });
    }
  }

  void _agruparHorariosPorDia() {
    _horariosPorDia = {};
    for (var horario in _horarios) {
      if (!_horariosPorDia.containsKey(horario.diaSemana)) {
        _horariosPorDia[horario.diaSemana] = [];
      }
      _horariosPorDia[horario.diaSemana]!.add(horario);
    }
  }

  Future<void> _salvarHorarios() async {
    // TODO: Implementar a lógica de salvar os horários
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de salvar em desenvolvimento.')),
    );
  }

  String _diaDaSemana(int dia) {
    switch (dia) {
      case 1: return 'Segunda-feira';
      case 2: return 'Terça-feira';
      case 3: return 'Quarta-feira';
      case 4: return 'Quinta-feira';
      case 5: return 'Sexta-feira';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Horários de Trabalho'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarHorarios,
            tooltip: 'Salvar Horários',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7, // 7 dias da semana
                  itemBuilder: (context, index) {
                    final dia = index + 1;
                    final horariosDoDia = _horariosPorDia[dia] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _diaDaSemana(dia),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (horariosDoDia.isEmpty)
                              const Text('Fechado', style: TextStyle(color: Colors.grey))
                            else
                              ...horariosDoDia.map((h) => Text('${h.inicio} - ${h.fim}')),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () {
                                  // TODO: Implementar dialog de edição
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
