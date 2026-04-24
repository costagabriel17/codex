# Scripts do Projeto

## Leitura obrigatoria

Antes de rodar qualquer script:

1. Ler `C:\Users\HUGO\Documents\Codex\2026-04-23\preciso-que-voc-seja-um-auxiliador\README.md`
2. Ler este arquivo
3. Confirmar que a acao pertence somente a esta loja/projeto

## Politica operacional

- Preferir script canonico a comando manual ad-hoc.
- Toda mutacao live deve gerar report em `reports\...\summary.json`.
- Falhas de API devem ser tratadas no script com saida previsivel.
- Nenhum script deve imprimir ou gravar secrets.
- Toda validacao deve ser reproduzivel no Windows com PowerShell.
- A camada operacional Shopify principal fica em `src\node\`, `src\python\`, `src\playwright\` e `src\theme\`.

## Scripts canonicos

### `sync-from-github.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\sync-from-github.ps1
```

Funcao:

- consulta a ultima versao do repositorio no GitHub
- atualiza a pasta local
- gera report de sincronizacao em `reports\`

### `publish-to-github.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-to-github.ps1 -Message "Descreva aqui o que mudou"
```

Funcao:

- envia os arquivos versionaveis para o GitHub
- ignora `.env`, `.codex` e `tmp`
- gera report de publicacao em `reports\`

### `set-gh-token.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-gh-token.ps1
```

Funcao:

- grava `GH_TOKEN` somente na maquina local atual
- nao cria report para evitar qualquer risco com segredo

### `validate-scripts.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-scripts.ps1
```

Funcao:

- valida a sintaxe dos scripts PowerShell do projeto
- gera report em `reports\`

### `validate-project-standards.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-project-standards.ps1
```

Funcao:

- valida a estrutura obrigatoria do projeto
- confere manifests e pastas canônicas
- gera report em `reports\`

## Estrutura de report

Cada execucao relevante cria uma pasta em `reports\YYYYMMDD-HHMMSS-acao\` com:

- `summary.json`: resumo estruturado da execucao

Campos esperados em `summary.json`:

- `action`
- `status`
- `startedAt`
- `finishedAt`
- `inputs`
- `results`
- `validation`
- `errors`

## Provas e validacoes

- Sempre que houver mutacao live, responder com o caminho do `summary.json`.
- Sempre que possivel, validar o efeito real antes da resposta final.
- Se nao houver validacao live possivel, registrar isso no report e na resposta final.
