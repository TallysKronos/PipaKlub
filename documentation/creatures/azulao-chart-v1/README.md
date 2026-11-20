# Prova do chart do Azulão

[Abrir o chart interativo](index.html) · [Ler o chart documentado](CHART.md) · [Dados](chart.json).

Oito formas principais em quatro estágios, duas propostas de configuração especial e um estado narrativo separado. A progressão inclui as três arquiteturas já aprovadas do Azulão. Novos nomes, novas formas, distribuição de estágios e critérios estão identificados como propostas.

O HTML funciona por arquivo local, sem servidor. `build.py` insere os dados de `chart.json` no template. `app.js` e os dois CSS são locais; referências usam as artes existentes do repositório. A página não acessa save, conta ou rede.

## Verificação

Da raiz do projeto:

```powershell
python documentation/creatures/azulao-chart-v1/build.py
node --check documentation/creatures/azulao-chart-v1/app.js
node documentation/creatures/azulao-chart-v1/verify.mjs
```

`verify.mjs` usa o linkedom já instalado em um dos checkouts locais. Confere as três rotas e retorno, critérios desmarcados, bloqueio de salto de estágio, estágio preservado nas configurações e impossibilidade de acionar possessão. Não valida renderização, margens, imagens em tela ou movimento.

**Limite da revisão:** a abertura automática do arquivo local no navegador foi bloqueada pela política do navegador. Não foi tentado outro protocolo ou superfície para contornar o bloqueio. A prévia visual no navegador continua pendente; fontes, estrutura e controles podem ser verificados localmente sem acesso externo.

Não há alterações no jogo, integração ao Soulgen, merge ou push desta proposta.
