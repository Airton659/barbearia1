# 💈 App de Barbearia

Um aplicativo moderno para gestão de barbearias, desenvolvido em Flutter e integrado com a API de Gestão Clínica.

## 🚀 Funcionalidades

### Para Clientes
- ✅ **Login seguro** com Firebase Authentication
- ✅ **Visualização de serviços** disponíveis com preços e duração
- ✅ **Agendamento de serviços** com seleção de profissional, data e horário
- ✅ **Histórico de agendamentos** com status em tempo real
- ✅ **Interface moderna** com tema personalizado para barbearia

### Para Profissionais e Administradores
- ✅ **Dashboard administrativo** com visão geral do negócio
- ✅ **Gestão de profissionais** (visualização e controle de status)
- ✅ **Gestão de serviços** (CRUD completo - criar, editar, excluir)
- ✅ **Visualização de agendamentos** com filtros por status
- ✅ **Cancelamento de agendamentos** pelo profissional

## 🛠️ Tecnologias Utilizadas

- **Flutter** - Framework de desenvolvimento mobile
- **Firebase Auth** - Autenticação segura
- **HTTP** - Comunicação com API REST
- **Provider** - Gerenciamento de estado
- **Intl** - Internacionalização e formatação de datas

## 🎨 Design

- **Cores Principais**: Tons de marrom e dourado (tema barbearia)
- **Logo Provisória**: Ícone de tesoura em um círculo elegante
- **Interface**: Material Design com elementos customizados
- **Responsiva**: Adapta-se a diferentes tamanhos de tela

## 📱 Telas Implementadas

1. **Login Screen** - Tela de autenticação moderna
2. **Dashboard Screen** - Painel administrativo para profissionais
3. **Client Home Screen** - Tela inicial para clientes
4. **Profissionais Screen** - Gestão de profissionais
5. **Serviços Screen** - CRUD de serviços
6. **Agendamentos Screen** - Visualização e gestão de agendamentos
7. **Agendamento Create Screen** - Criação de novos agendamentos

## 🔧 Configuração

### Pré-requisitos
- Flutter SDK instalado
- Conta Google (para Firebase)
- API de Gestão Clínica rodando

### Instalação
1. Clone o repositório
2. Execute `flutter pub get` para instalar dependências
3. **IMPORTANTE**: Configure o Firebase seguindo o guia `FIREBASE_SETUP.md`
4. Atualize a URL da API no arquivo `lib/services/api_service.dart` (se necessário)
5. Execute `flutter run` para iniciar o app

### 🔥 Configuração do Firebase (OBRIGATÓRIO)

O app **NÃO funciona sem Firebase configurado**! Siga estas etapas:

1. **Leia o arquivo `FIREBASE_SETUP.md`** para instruções detalhadas
2. **Configure o projeto "teste-notificacao-barbearia"** no Firebase Console
3. **Habilite Email/Password Authentication**
4. **Para Android**: Baixe o `google-services.json` e coloque em `android/app/`
5. **Para Web**: Configure as credenciais em `lib/firebase_options.dart`
6. **Crie um usuário de teste**: `admin@com.br` com senha `123456`

### ⚡ Início Rápido

1. Depois de configurar Firebase, execute o app
2. Use credenciais de teste:
   - **Email**: `admin@com.br`
   - **Senha**: `123456` 
3. Se aparecer tela de código de convite, use: `75EB94F1`
4. Agora você é o administrador da barbearia!

## 🌐 Integração com API

O app se conecta com a API de Gestão Clínica em:
```
https://barbearia-backend-service-862082955632.southamerica-east1.run.app
```

### Principais Endpoints Utilizados:
- `POST /users/sync-profile` - Sincronização de perfil
- `GET /servicos` - Listar serviços
- `GET /profissionais` - Listar profissionais
- `POST /agendamentos` - Criar agendamento
- `GET /me/agendamentos` - Agendamentos do profissional
- `GET /agendamentos/me` - Agendamentos do cliente

## 👥 Tipos de Usuário

### Cliente
- Visualiza serviços disponíveis
- Agenda horários
- Acompanha seus agendamentos

### Profissional
- Gerencia seus serviços
- Visualiza agendamentos
- Cancela agendamentos quando necessário

### Admin
- Acesso completo ao sistema
- Gerencia profissionais
- Supervisiona todos os agendamentos

## 🚧 Funcionalidades Futuras

- [ ] Push notifications para lembrar agendamentos
- [ ] Sistema de avaliações
- [ ] Chat entre cliente e profissional
- [ ] Relatórios financeiros
- [ ] Gestão de horários de trabalho
- [ ] Sistema de fidelidade

## 📝 Notas de Desenvolvimento

- O projeto utiliza arquitetura limpa com separação entre models, services e screens
- Firebase Options configurado para multiplataforma
- Tratamento de erros implementado em todas as chamadas de API
- Interface responsiva que funciona em diferentes tamanhos de tela
- Código preparado para internacionalização (pt-BR)

---

*Desenvolvido com ❤️ para revolucionar a gestão de barbearias*
