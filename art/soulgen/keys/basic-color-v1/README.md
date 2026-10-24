# Básicos e Rabbito — rigs coloridos

**Revisão solicitada em 24/10/2026:** este lote não está aprovado em direção de arte. Os olhos grandes/brilhantes e o acabamento polido se afastaram do Carcará. A próxima versão deve seguir [Direção de arte — padrão Carcará](../../DIRECAO-ARTE-CARCARA.md). Os testes abaixo verificam somente a montagem técnica; não devem ser apresentados como aprovação do desenho. Fontes e projetos permanecem como histórico da tentativa.

Lote solicitado: Mata verde, Azulão, Raio de sol e Rabbito. O Carcará aprovado continua preservado como referência de método. Não foram criadas variantes de raridade, alterados poderes, substituídos atlas do jogo ou publicados estes assets em produção.

## Abrir e editar

`npm run studio:sprites` abre o Soulgen Studio (porta padrão 5240). A biblioteca contém os quatro personagens. `/basics-review.html` compara as cinco ações em tempo normalizado, com pausa, busca temporal e fundos claro/escuro. Links `/?preset=rabbito`, `/?preset=mata-verde`, `/?preset=azulao` e `/?preset=raio-de-sol` abrem cada projeto; uma recuperação automática da mesma espécie é preservada.

Cada pasta `../<espécie>/color-rig/` contém:

- `source.png`: fonte original image_gen preservada, RGBA 1254×1254.
- Peças PNG e variantes da peça facial; dimensões e recortes reais em `registration.json`.
- `<espécie>.soulgen.json`: projeto editável com referências às fontes locais.
- `<espécie>.portable.soulgen.json`: projeto independente com os PNGs incorporados; pode ser aberto pelo comando Abrir projeto do Studio.
- `expressions-review.png`: comparação neutro/golpe/dano/vitória.

## Anatomia e movimentos

Mata verde: quatro peças, asas-folhas, vela central e cipó. Movimento lateral leve e asas ondulantes. Azulão: quatro peças, vela-nuvem e rabiola; voo mais lento e compensações menores. Raio de sol: quatro peças, asas sanfonadas e rabiola dupla; voo mais rápido e angular. Rabbito: sete peças, corpo com pés, cabeça, duas orelhas de vela, dois braços e rabiola. Orelhas herdam a cabeça; braços e rabiola acompanham o torso. Esta vista não é um rig de quatro direções de overworld.

Cada projeto possui repouso/voo contínuos e golpe/dano/vitória únicos. Golpe dura 1,8 s e atinge em 0,68 s; dano dura 1,2 s; vitória dura 2,6 s. As ações únicas retornam ao neutro, inclusive após o atraso das peças. Expressões são temporais, sem trocar enquadramento.

## Registro e reprodução

`prepare.py` mede recortes explícitos, registra as faces geradas sobre a textura neutra e verifica igualdade de alpha e de todos os pixels fora da janela facial. Não desenha olhos por código. A única limpeza de componente remove um fragmento isolado da cabeça vizinha no slot da orelha do Rabbito. Os PNGs originais permanecem intactos.

`build.mjs` monta os projetos, registra os pivôs próprios de cada anatomia, cria curvas e incorpora as imagens nos projetos portáteis. As 96 unidades do Carcará não são copiadas: estes rigs usam uma bancada de 160×160 unidades.

```powershell
python art/soulgen/keys/basic-color-v1/prepare.py
node art/soulgen/keys/basic-color-v1/build.mjs
node --test tools/soulgen-studio/basics.test.mjs tools/soulgen-studio/model.test.mjs tools/soulgen-studio/server.test.mjs
```

## Revisão

35 testes do Soulgen aprovados, incluindo quatro novos contratos de criatura: continuidade dos ciclos, fim estável das ações únicas, estados faciais, transformações finitas, margens de todas as peças em 121 instantes por ação e compatibilidade de exportação do Studio. O preparo verifica alpha idêntico e pixels externos à face invariantes. Referências de proporção, ordem de camadas e pontos de contato também são verificadas pelo auditor anatômico do Studio. Esses testes não substituem julgamento artístico.

Inspeção no navegador detectou e corrigiu a rabiola afastada do Mata verde, um fragmento vizinho na orelha do Rabbito e o encaixe da rabiola do Rabbito no golpe. A revisão foi feita em fundos claro e escuro. Evidências estão nesta pasta. A aprovação artística final pertence ao responsável do projeto.
