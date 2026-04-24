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

## Tecnologias obrigatorias

- `Node.js`: scripts operacionais canônicos
- `Python 3`: pipelines de dados e imagens
- `Playwright`: auditoria live E2E da storefront
- `Shopify Admin GraphQL/REST`: mutacoes e leitura de dados da loja
- `Liquid/CSS/JS`: implementacao e ajuste de tema

## Requisitos de runtime

- `Node.js 20+`
- `Python 3.11+`
- Navegador do Playwright instalado quando houver auditoria live
- Variaveis locais em `.env` apenas na maquina do usuario

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

- `deliverables\`: entregaveis para cliente
- `src\`: codigo-fonte operacional do projeto
- `scripts\`: scripts canonicos e utilitarios compartilhados
- `reports\`: provas de execucao e mutacoes live com `summary.json`
- `tmp\`: arquivos temporarios locais nao versionados
- `.codex\`: estado tecnico local do agente

## Politicas principais

- Nunca commitar `.env`, tokens ou segredos.
- Toda mutacao live deve deixar prova em `reports\`.
- Toda auditoria live de storefront deve acontecer com Playwright antes do encerramento.
- Toda alteracao relevante deve atualizar esta documentacao e `scripts\README.md`.
- Sempre preferir script canonico em vez de acao manual repetitiva.
- Encerrar o trabalho sem processos ou terminais pendurados.
- Quando a API variar ou falhar, corrigir o script com fallback resiliente.

## Comandos base

Salvar token do GitHub nesta maquina:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-gh-token.ps1
```

Validar scripts PowerShell do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-scripts.ps1
```

Validar o padrao estrutural do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-project-standards.ps1
```

Jeito facil para o dia a dia:

Antes de comecar a trabalhar:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\iniciar-trabalho.ps1
```

Quando terminar e quiser salvar tudo no GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\salvar-no-github.ps1 -Message "Descreva aqui o que mudou"
```

Ativar salvamento automatico no GitHub:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\ativar-autosave.ps1
```

Desativar salvamento automatico:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\desativar-autosave.ps1
```

## Observacoes

- O GitHub e a fonte central de sincronizacao entre maquinas.
- Os scripts usam `GH_TOKEN` local da maquina do dono da loja.
- O projeto e mantido com foco em robustez, rastreabilidade e operacao mobile-first quando houver UX/storefront.
- O codigo operacional Shopify fica em `src\` e os utilitarios PowerShell atuam como camada Windows/orquestracao.
- O autosave cria commits pequenos periodicos e so publica quando ha mudanca real validada.
- Os reports do autosave ficam em `reports\autosave\` e nao entram no Git para evitar loop infinito de commits.
- Os reports internos de infraestrutura local ficam em `reports\runtime\` e tambem nao entram no Git.
