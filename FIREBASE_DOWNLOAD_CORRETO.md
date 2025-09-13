# 🎯 COMO BAIXAR O google-services.json CORRETO

## ⚠️ PROBLEMA IDENTIFICADO

Você tem **2 apps Android** no mesmo projeto Firebase:
1. **App Analice**: `com.example.analicegrubert` ❌ (app antigo)  
2. **App Barbearia**: `com.ygg.barbearia1` ✅ (app correto)

Quando você clica "Download google-services.json", ele baixa o arquivo do **app errado**.

## 🎯 SOLUÇÃO: Baixar do App Correto

### Passo 1: Acessar Firebase Console
1. Acesse: https://console.firebase.google.com
2. Abra: Projeto "teste-notificacao-barbearia"

### Passo 2: Identificar o App Correto
Na tela inicial, você verá **2 apps Android**:
- 📱 **analicegrubert** (`com.example.analicegrubert`) ❌ 
- 📱 **Barbearia 1** (`com.ygg.barbearia1`) ✅ **← ESTE É O CORRETO**

### Passo 3: Baixar do App Correto
1. **Clique** no app **"Barbearia 1"** (não no analicegrubert!)
2. **OU** vá em Project Settings → seção "Your apps"
3. **Encontre** o app com:
   - **Nome**: "Barbearia 1" 
   - **Package**: `com.ygg.barbearia1`
   - **App ID**: `1:862082955632:android:98db5b28e62a60c89cb7b5`
4. **Clique** no ícone de download ⬇️ ao lado deste app
5. **Baixe** o `google-services.json`

### Passo 4: Substituir o Arquivo
1. **Substitua** o arquivo em: `android/app/google-services.json`
2. **Execute**: `flutter clean && flutter run`

## ✅ COMO VERIFICAR SE ESTÁ CORRETO

Abra o arquivo baixado e verifique:
```json
{
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.ygg.barbearia1"  ← DEVE SER ESTE
        }
      }
    }
  ]
}
```

## 🚨 SE CONTINUAR BAIXANDO O ERRADO

### Opção A: Usar Link Direto
1. No Firebase Console, clique em Project Settings
2. Na aba "General", seção "Your apps"
3. Encontre especificamente o app "Barbearia 1"
4. Clique nos 3 pontinhos → "Download config file"

### Opção B: Deletar App Antigo (Cuidado!)
1. Se não precisar mais do app "analicegrubert"
2. Clique nos 3 pontinhos → "Delete app"
3. Assim só restará o app correto

## 🎯 INFORMAÇÕES DO APP CORRETO

**Use estas informações para encontrar o app certo:**
- **App ID**: `1:862082955632:android:98db5b28e62a60c89cb7b5`
- **Package**: `com.ygg.barbearia1`
- **Nome**: "Barbearia 1"

## 📝 PROJETO JÁ ATUALIZADO

Já atualizei o projeto Flutter para usar:
- ✅ **Package**: `com.ygg.barbearia1`
- ✅ **MainActivity**: Movido para pasta correta
- ✅ **build.gradle**: Configurado com package correto

**Agora só precisa baixar o `google-services.json` do app CORRETO!** 🎯