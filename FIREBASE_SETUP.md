# 🔥 Configuração do Firebase para o App de Barbearia

## ⚠️ IMPORTANTE: Você precisa configurar o Firebase antes de usar o app!

### 📋 Passos para Configurar:

#### 1. Acesse o Console do Firebase
- Vá para: https://console.firebase.google.com
- Faça login com sua conta Google

#### 2. Crie/Configure seu Projeto
- **Se já tem projeto**: Abra "teste-notificacao-barbearia"
- **Se não tem projeto**: Clique em "Criar projeto" e use o nome "teste-notificacao-barbearia"

#### 3. Configure a Autenticação
1. No menu lateral, clique em **Authentication**
2. Clique em **Get started**
3. Vá na aba **Sign-in method**
4. Clique em **Email/Password**
5. **Habilite** a primeira opção (Email/Password)
6. Clique em **Save**

#### 4. Adicione seu App Android
1. No menu lateral, clique em **Project Settings** (engrenagem)
2. Clique em **Add app** → **Android**
3. **Android package name**: `com.ygg.barbearia1`
4. **App nickname**: `Barbearia App`
5. Clique em **Register app**
6. **Baixe** o arquivo `google-services.json`
7. **IMPORTANTE**: Coloque o arquivo em `android/app/google-services.json`
8. Siga os próximos passos até **Continue to console**

#### 5. Para Web (Opcional - só se quiser testar no navegador)
Se você quiser adicionar suporte web:
1. Na mesma tela **Project Settings**, clique em **Add app** → **Web**
2. **App nickname**: `Barbearia Web`
3. Clique em **Register app**
4. **Copie** as configurações que aparecem:
   - **apiKey**
   - **appId** 
   - **messagingSenderId**
5. Substitua no arquivo `lib/firebase_options.dart` na seção `web`

#### 6. ✅ Pronto para Android!
Para Android, **não precisa configurar nada no código**! O arquivo `google-services.json` contém todas as configurações necessárias.

#### 7. Crie um Usuário de Teste
1. No Firebase Console, vá em **Authentication** → **Users**
2. Clique em **Add user**
3. **Email**: `admin@com.br`
4. **Password**: `123456`
5. Clique em **Add user**

## 🚀 Testando o App

1. Execute `flutter run`
2. Na tela de login, use:
   - **Email**: `admin@com.br` 
   - **Senha**: `123456`
3. Se aparecer a tela de código de convite, use: `75EB94F1`

## ❗ Problemas Comuns

### "API key not valid"
- ✅ Verifique se copiou a API Key correta
- ✅ Certifique-se de que o arquivo `google-services.json` está em `android/app/`

### "User not found" 
- ✅ Crie o usuário no Firebase Console → Authentication → Users
- ✅ Verifique se o email está correto

### App não compila
- ✅ Execute `flutter clean && flutter pub get`
- ✅ Verifique se o `google-services.json` está na pasta correta

## 📁 Estrutura de Arquivos Necessária

```
android/
├── app/
│   ├── google-services.json  ← ARQUIVO OBRIGATÓRIO
│   └── build.gradle
lib/
├── firebase_options.dart     ← SUBSTITUA AS CONFIGURAÇÕES
└── ...
```

## 🆘 Ainda com Problemas?

1. Certifique-se de que tem **Project Editor** no projeto Firebase
2. Verifique se o **Email/Password** está habilitado
3. Confirme que o `google-services.json` foi baixado e colocado na pasta correta
4. Teste com um usuário criado manualmente no Console

---

*Após configurar o Firebase, o app funcionará perfeitamente! 🎉*