# Projeto Operacional Shopify

Repositorio: https://github.com/costagabriel17/codex

## Objetivo

Esta pasta e a base operacional do projeto Shopify da loja ativa deste workspace.
O projeto deve operar com:

- escopo isolado por loja
- automacao reutilizavel
- validacao antes de resposta final
- relatorios em `reports\`
- operacao local segura no Windows

## Leitura obrigatoria antes de agir

1. Ler este arquivo.
2. Ler `scripts\README.md`.
3. So depois executar scripts ou mutacoes live.

## Fluxo padrao entre maquinas

1. Atualizar a pasta local com o GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-from-github.ps1
```

2. Executar o trabalho nesta pasta.
3. Validar com os scripts aplicaveis.
4. Publicar de volta no GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-to-github.ps1 -Message "Descreva aqui o que mudou"
```

## Estrutura operacional

- `scripts\`: scripts canonicos e utilitarios compartilhados
- `reports\`: provas de execucao e mutacoes live com `summary.json`
- `tmp\`: arquivos temporarios locais nao versionados
- `.codex\`: estado tecnico local do agente

## Politicas principais

- Nunca commitar `.env`, tokens ou segredos.
- Toda mutacao live deve deixar prova em `reports\`.
- Toda alteracao relevante deve atualizar esta documentacao e `scripts\README.md`.
- Sempre preferir script canonico em vez de acao manual repetitiva.
- Encerrar o trabalho sem processos ou terminais pendurados.

## Comandos base

Salvar token do GitHub nesta maquina:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-gh-token.ps1
```

Validar scripts PowerShell do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-scripts.ps1
```

## Observacoes

- O GitHub e a fonte central de sincronizacao entre maquinas.
- Os scripts usam `GH_TOKEN` local da maquina do dono da loja.
- O projeto e mantido com foco em robustez, rastreabilidade e operacao mobile-first quando houver UX/storefront.
