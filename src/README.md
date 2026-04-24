# Src

Codigo-fonte operacional do projeto Shopify.

## Estrutura

- `src\node\`: scripts operacionais em Node.js
- `src\python\`: pipelines de dados e imagens em Python 3
- `src\playwright\`: auditorias live E2E da storefront
- `src\theme\`: assets e customizacoes de tema Shopify

## Regras

- scripts operacionais canônicos ficam aqui, nao em comandos manuais soltos
- cada mutacao live deve produzir report em `reports\`
- storefront sempre deve ser auditada em mobile-first antes do encerramento
