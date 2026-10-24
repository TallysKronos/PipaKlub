# Starters v2 — papel artesanal no padrão Carcará

Mata verde, Azulão, Raio de sol e Rabbito regenerados conforme o pedido de 24/10/2026 e `../../DIRECAO-ARTE-CARCARA.md`. O Carcará aprovado governa o desenho e o material, além do método de animação. A versão anterior permanece em `basic-color-v1` e `../<espécie>/color-rig/`.

## Entrega e revisão

- Olhos pequenos, escuros e sem íris brilhantes; intenção por sobrancelhas e postura.
- Vela de papel facetado, varetas, amarrações e remendos costurados.
- Azulão tratado como ave-pipa: bico curto amarelo de papel e penas com motivos de nuvens. Não acrescentado bico às espécies vegetal, solar ou coelho.
- Rabbito com focinho, cabeça angular, orelhas de vela e corpo de papel, preservando creme/turquesa e rabiola de laços.
- Carcará preservado integralmente e incluído na galeria como referência. O enquadramento da galeria usa limites neutros fixos por criatura, sem alterar escala entre expressões; não representa escala de combate.

Primeiro foram geradas e inspecionadas quatro poses completas (`concept.png`), depois quatro folhas de peças baseadas nessas poses (`source.png`). As oito chamadas usaram `image_gen.imagegen` com transparência. Os prompts completos e a fonte de estilo estão em `prompts.json`. As referências de identidade foram os atlas anteriores de cada espécie; a sua aparência de olhos grandes não foi conservada.

## Abrir no Studio

Execute `npm run studio:sprites`. A porta padrão é 5240; nesta revisão foi usado também o servidor local na porta 5258.

- `/basics-review.html`: comparação animada com o Carcará, cinco ações, busca temporal, pausa e fundos claro/escuro.
- `/?preset=mata-verde`, `/?preset=azulao`, `/?preset=raio-de-sol`, `/?preset=rabbito`: editar peças, pivôs, parentesco, poses e expressões.
- Biblioteca: os quatro botões abrem agora a revisão v2. Uma recuperação anterior da mesma espécie é arquivada em uma chave local de histórico quando um link de preset solicita a nova arte; o conteúdo do PNG anterior não é sobrescrito.

Em `../<espécie>/color-rig-v2/` há fontes, peças PNG, `registration.json`, máscara facial, comparação de expressões, manifesto, projeto local e `<espécie>.portable.soulgen.json` com imagens incorporadas. O ZIP deste diretório reúne os quatro projetos portáteis.

## Construção e invariantes

`prepare.py` mede recortes reais sem confiar na grade aparente. Recorta as peças e elimina fragmentos desconectados de slots vizinhos; não desenha anatomia por código. As variantes faciais são registradas sobre uma peça neutra, preservando alpha e todos os pixels externos à máscara. Regiões medidas do bico do Azulão e nariz do Rabbito ficam protegidas e têm igualdade de pixels verificada.

`build.mjs` retargeta as cinco ações da base anterior para a nova geometria: recalibra tamanhos, pivôs e referências de contato. No Rabbito, a folha gerada inverteu o tamanho esperado dos dois braços; a peça mais larga foi atribuída ao braço próximo. Não foram copiadas cegamente coordenadas de recorte nem rótulos da geração.

Cada rig possui repouso e voo contínuos; golpe, dano e vitória terminam no neutro. Golpe: 1,8 s, impacto em 0,68 s; dano: 1,2 s; vitória: 2,6 s. Os atrasos de peças assentam antes do fim das ações únicas. Expressões acompanham as janelas temporais do projeto.

```powershell
python art/soulgen/keys/basic-color-v2/prepare.py
node art/soulgen/keys/basic-color-v2/build.mjs
node --test tools/soulgen-studio/*.test.mjs
```

39 testes do Soulgen aprovados na revisão completa, incluindo os oito contratos de criatura v1/v2. A conferência posterior da proteção de bico/nariz passou nos oito contratos. Verificados projetos portáteis, amostragem de 121 instantes por ação, limites de enquadramento, continuidade dos ciclos, assentamento, estados faciais e referências anatômicas. Revisão no navegador: comparação com Carcará, leitura em fundo claro/escuro e extremos das ações; capturas neste diretório.

## Limites

Esta é uma entrega de arte e projetos animáveis para revisão final do responsável. Não altera espécie/modelo no banco, raridade, bônus, coleção ou atributos. Os atlas usados pelo combate e overworld permanecem como antes; os rigs v2 ainda não foram publicados no Render nem enviados ao Git remoto. Esta vista não é uma folha de quatro direções do overworld.

## Hierarquia do Rabbito editada pelo responsável

Adotado o arquivo `Downloads/rabbito-papel-artesanal-v2.soulgen.json`, preservado sem modificação em `../rabbito/color-rig-v2/user-hierarchy-original.soulgen.json`. O hash e os ajustes geométricos estão em `user-hierarchy.json`. A cabeça passou para trás do torso; cabeça e ambas as orelhas foram reposicionadas. Parentesco, profundidade, dimensões, distâncias relativas e as cinco ações do autor foram preservados. As texturas faciais continuam sendo as versões canônicas com nariz protegido, atualizadas após a exportação original do autor.

O projeto usa agora uma área de 160×176, com translação global de +12 no eixo Y para preservar a margem superior da orelha em todos os extremos. Essa translação aplica-se igualmente às peças, pivôs e pivô global, sem alterar a montagem relativa ou as curvas. Os testes comparam cada peça contra a exportação original descontando esse deslocamento. As referências antigas de contato das orelhas foram recalibradas a partir das raízes das peças, mantendo a tolerância de 3,5 unidades.

O build reaplica o ajuste manual depois da geometria gerada; reconstruir o lote não volta à hierarquia anterior. O preset tem `rigRevision: 1`. A galeria usa a nova montagem e o projeto portátil/ZIP foram atualizados.
