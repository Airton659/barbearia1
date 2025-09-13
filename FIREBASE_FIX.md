# 🔥 CORREÇÃO URGENTE - Firebase Package Name

## ⚠️ PROBLEMA IDENTIFICADO

O arquivo `google-services.json` está configurado para:
- **Package atual**: `com.example.analicegrubert` ❌
- **Package necessário**: `com.ygg.barbearia1` ✅

## 🛠️ COMO CORRIGIR

### Opção 1: Corrigir no Firebase Console (Recomendado)

1. **Acesse**: https://console.firebase.google.com
2. **Abra**: Projeto "teste-notificacao-barbearia"
3. **Clique**: Project Settings (engrenagem) → aba "General"
4. **Na seção "Your apps"**: Encontre o app Android atual
5. **Clique**: nos 3 pontinhos → "Delete app" (opcional)
6. **Clique**: "Add app" → Android
7. **Android package name**: `com.ygg.barbearia1` ✅
8. **App nickname**: `Barbearia App`
9. **Register app**
10. **Baixe**: o novo `google-services.json`
11. **Substitua**: o arquivo em `android/app/google-services.json`
12. **Teste**: `flutter run`

### Opção 2: Usar Modo Demo (Temporário)

O app agora detecta automaticamente quando o Firebase não funciona e:
- ✅ **Mostra**: "MODO DEMONSTRAÇÃO"
- ✅ **Permite**: Testar todas as telas
- ✅ **Funciona**: Sem precisar de Firebase

## 🎯 CONTAS DE TESTE (Modo Demo)

```
admin@com.br → Dashboard Admin
profissional@com.br → Dashboard Profissional  
cliente@com.br → Tela do Cliente
```

## 📱 COMO USAR AGORA

### Se Firebase estiver configurado:
- Login normal com `admin@com.br` / `123456`

### Se Firebase não estiver configurado:
- Automaticamente abre o **Modo Demo**
- Use qualquer conta de teste acima
- **Código de convite**: `75EB94F1`

## ✅ VERIFICAR SE FUNCIONOU

Execute o app e veja:
- **Firebase OK**: Tela de login normal
- **Firebase com problema**: "MODO DEMONSTRAÇÃO"

## 📋 ARQUIVO ATUAL

O arquivo `android/app/google-services.json` atual tem:
```json
"package_name": "com.example.analicegrubert"  ← ERRADO
```

Precisa ter:
```json
"package_name": "com.ygg.barbearia1"  ← CORRETO
```

---

**📞 Se ainda tiver problemas, o Modo Demo permite testar todas as funcionalidades!**