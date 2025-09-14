import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    if (user != null && mounted) {
      setState(() {
        _nomeController.text = user.nome;
        // Aplicar a máscara no telefone existente
        final telefone = user.telefone ?? '';
        _telefoneController.text = _phoneMaskFormatter.maskText(telefone);
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Escolher foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8D6E63), width: 2),
            ),
            child: Icon(
              icon,
              size: 40,
              color: const Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        print('🔥 Imagem selecionada: ${image.path}');
        print('🔥 Fonte: ${source == ImageSource.camera ? 'Câmera' : 'Galeria'}');

        // Abrir o editor com máscara circular
        await _openImageEditor(image);
      }
    } catch (e) {
      print('🔥 Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _openImageEditor(XFile imageFile) async {
    try {
      print('🔥 Abrindo editor de imagem...');

      final bytes = await imageFile.readAsBytes();

      if (!mounted) return;

      // Abrir o pro image editor com callbacks corretos
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProImageEditor.memory(
            bytes,
            configs: ProImageEditorConfigs(
              designMode: ImageEditorDesignModeE.material,
              theme: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF8D6E63),
                ),
              ),
              imageEditorTheme: const ImageEditorTheme(
                background: Colors.black,
                appBarForegroundColor: Colors.white,
                appBarBackgroundColor: Color(0xFF8D6E63),
              ),
              cropRotateEditorConfigs: const CropRotateEditorConfigs(
                enabled: true,
                canChangeAspectRatio: false,
                initAspectRatio: 1.0, // 1:1 para quadrado (fica bom no avatar circular)
              ),
              paintEditorConfigs: const PaintEditorConfigs(
                enabled: true, // Permitir desenho
              ),
              textEditorConfigs: const TextEditorConfigs(
                enabled: true, // Permitir texto
              ),
              stickerEditorConfigs: StickerEditorConfigs(
                enabled: false, // Desabilitar stickers
                buildStickers: (setLayer, scrollController) => const SizedBox.shrink(),
              ),
              filterEditorConfigs: const FilterEditorConfigs(
                enabled: true, // Permitir filtros
              ),
              blurEditorConfigs: const BlurEditorConfigs(
                enabled: true, // Permitir blur
              ),
            ),
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (bytes) async {
                print('🔥 Callback: Imagem editada recebida!');
                print('🔥 Tamanho da imagem editada: ${bytes.length} bytes');
                print('🔥 Estado atual de _imageBytes antes: ${_imageBytes?.length ?? 'null'}');

                if (mounted) {
                  setState(() {
                    _selectedImage = imageFile;
                    _imageBytes = bytes;
                  });

                  print('🔥 Estado após setState: _imageBytes = ${_imageBytes?.length ?? 'null'}');

                  // Fechar o editor primeiro
                  Navigator.pop(context);

                  // Aguardar um pouco antes de mostrar o feedback
                  await Future.delayed(const Duration(milliseconds: 300));

                  // Mostrar feedback ao usuário se ainda montado
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Imagem editada com sucesso!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print('🔥 Erro ao editar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao editar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    print('🔥 _saveProfile iniciado');

    if (!_formKey.currentState!.validate()) {
      print('🔥 Validação falhou');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      final apiService = ApiService();

      if (user == null) {
        print('🔥 ERRO: usuário não logado');
        return;
      }

      // ✅ Para /me/profile só enviamos o que queremos atualizar
      final updateData = <String, dynamic>{
        'nome': _nomeController.text.trim(),
        'telefone': _phoneMaskFormatter.getUnmaskedText().trim(),
      };

      print('🔥 Dados preparados para enviar: $updateData');

      final updatedUser = await apiService.updateUserProfile(
        updateData,
        imageBytes: _imageBytes,
      );

      print('🔥 Usuário atualizado com sucesso: ${updatedUser.toJson()}');

      // ✅ CRUCIAL: Atualizar o AuthService com os novos dados
      await authService.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('🔥 ERRO ao salvar perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 BUILD: _imageBytes = ${_imageBytes?.length ?? 'null'}');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar para seleção de foto
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(color: const Color(0xFF8D6E63), width: 3),
                  ),
                  child: _imageBytes != null
                      ? ClipOval(
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('🔥 ERRO ao carregar imagem editada: $error');
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.red,
                              );
                            },
                          ),
                        )
                      : Consumer<AuthService>(
                          builder: (context, authService, child) {
                            final user = authService.currentUser;
                            return user?.profileImage != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.profileImage!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF8D6E63),
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Color(0xFF8D6E63),
                                  );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para alterar foto',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneMaskFormatter],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D6E63),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }
}