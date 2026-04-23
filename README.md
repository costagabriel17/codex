# Projeto Codex

Esta pasta e a base local do projeto ligado ao repositorio:

https://github.com/costagabriel17/codex

## Regra principal

Antes de rodar qualquer script ou continuar um trabalho:

1. Atualize a pasta com `scripts\sync-from-github.ps1`
2. Faca o trabalho
3. Publique de volta com `scripts\publish-to-github.ps1`

## Estrutura inicial

- `scripts\sync-from-github.ps1`: baixa a versao mais recente do GitHub
- `scripts\publish-to-github.ps1`: envia os arquivos atuais para o GitHub

## Como usar

Atualizar antes de trabalhar:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-from-github.ps1
```

Publicar alteracoes:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-to-github.ps1 -Message "Atualiza scripts do projeto"
```

Salvar o token do GitHub nesta maquina:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-gh-token.ps1
```

## Observacoes

- A pasta `.git` fica localmente nesta maquina para controle de versao local.
- A pasta `.codex` guarda somente estado temporario da sincronizacao.
- O script de publicacao precisa de acesso autenticado ao GitHub para funcionar.
- Para publicar, use um token do GitHub com permissao para ler e escrever o conteudo do repositorio.
