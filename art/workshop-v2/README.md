# Oficina das Almas — bancada neutra jogável

23/10/2026. Evolução local do commit b536e50, integrado como 4df3ca4. A construção deixa de revelar a anatomia da espécie: o gabarito é uma pipa neutra e a alma permanece selada até o nascimento. Isso substitui a escavação da silhueta do Rabbito da revisão anterior.

## O que está implementado

- Bancada superior completa, ferramentas que acompanham o cursor, bandeja de materiais e área central livre.
- Pinça para pegar/soltar varetas e papel; linha puxada em cada união; tesoura seguindo contorno; cola aplicada nas uniões; cabresto ajustado no teste de vento; rabiola selada presa por último.
- Botões DOM com ícones SVG, foco, estado pressionado, teclas 1–6. Setas movem a ferramenta; Espaço alterna pegar/soltar sem precisar manter pressionado. Esc cancela o gesto e não deve alcançar os atalhos do mundo.
- Arrastar ou usar dois cliques para posicionar materiais. Cancelamento em perda de captura, saída de foco ou aba oculta. Pausa e movimento reduzido.
- Sinais de risco: faixa de tensão no nó; corte marcado sobre o contorno; flash e rasgos na folha; cola nas uniões; inclinação ao testar voo; sombra de encaixe e mensagem curta contextual.
- Transformação visual da pipa neutra em criatura apenas após confirmação do nascimento pelo servidor. Nenhuma silhueta, rosto, nome ou paleta de espécie na montagem.
- Catálogo agrupado por classe; preparação com almas seladas compatíveis. Não há sorteio novo de espécie: a alma selecionada continua ligada ao mesmo alvo no servidor.

## Dificuldade do piloto

| Classe | Gabarito | Apoios | Tolerância de corte (coordenadas da bancada) | Faixa de puxada |
|---|---|---:|---:|---:|
| Comum | Diamante | 4 | 22 | 24–64 |
| Incomum | Hexagonal | 6 | 18 | 29–60 |
| Raro | Estrela de vento | 8 | 14 | 33–57 |

Valores iniciais para playtest, não balanceamento final. O gabarito começa visível, sem cronômetro obrigatório nem limite de consultas. A dificuldade aumenta por geometria e tolerância. A prévia permite testar as três classes livremente.

No jogo, `craftClasses` do manifesto permite atribuição explícita por modelo. Na ausência dela, usa `rarity` da Dex, reconhecendo `rara`/`rare`. `especial` não é convertido automaticamente em raro: o fallback é comum. Rabbito está explicitamente no comum para o piloto. A distribuição completa por espécie permanece uma decisão de conteúdo.

## Fontes, assets e reprodução

- `assets/workshop/v2/bench.png`: fundo original 1536×1024 gerado com a ferramenta image_gen integrada, sem ferramentas nem textos pintados. Cópia do resultado original mantida no workspace; a versão anterior não foi sobrescrita.
- `assets/workshop/v2/{pinca,linha,tesoura,cola,vento,gabarito}.svg`: vetores nativos de ferramentas, publicados também por `craftIcon()` no DOM. `voltar.svg`, `confirmar.svg`, `refazer.svg` são ícones reutilizáveis de ação.
- Botões do jogo preservam o skin Papel e Bambu existente. Texto e hitboxes ficam separados da arte.
- `src/workshop-craft.js`: geometria, manipulação, qualidade e payloads.
- `src/workshop-craft-renderer.js`: desenho e animação; não consulta espécie antes da etapa de nascimento.
- `src/workshop-craft-controls.js`: entrada compartilhada entre prévia e jogo.
- `src/workshop-craft-client.js`: integração com sessão, reserva, confirmação e coleção já existentes.
- `src/workshop-craft-preview.html`: fonte da prévia. `node scripts/build-workshop-craft-preview.mjs` a recompõe e publica os SVGs.
- `node scripts/preview-workshop.mjs`: abre a prévia na porta 5237. `WORKSHOP_PREVIEW_PORT` permite outra porta; nesta auditoria usamos 5252. `/mobile` contém um iframe de 390×844 e `/landscape` um de 844×390; não representa aparelho físico. `/v1` preserva a revisão anterior.

Prompt final da bancada (image_gen, geração nova):

> Use case: stylized-concept. Asset type: actual playable 2D videogame workbench background, landscape 3:2. Create a polished clean hand-drawn cel-shaded Brazilian kite artisan workbench seen directly from above, orthographic top-down, for Soulmonsters Oficina das Almas. Entire wooden tabletop fills image edge to edge. Warm honey wood, dark teal painted border, small coral and golden accents. Central 75 percent is EMPTY clear smooth wooden working surface with very restrained subtle grain and no objects, no paper, no kite, no symbols. Around narrow outermost edges only: a few neatly stacked colored tissue paper sheets at upper left corner, small bamboo offcuts at upper right, two spools by far lower left edge, subtle dried tropical leaf corner detail. These decorative objects never intrude center. Consistent dark blue brown outlines, flat colors with two levels of shading, crisp edges, minimal detailed stylized 2D RPG art, warm cheerful cozy artisan identity, NO watercolor texture, NO photorealism, NO isometric room, NO text, NO baked-in tools or interface, NO characters, NO creature silhouettes. This is a functional unobstructed game board background, camera exactly perpendicular to tabletop. Generous clean central working space.

## Persistência e limites

As cinco confirmações continuam no endpoint idempotente de Oficina com migrações 024/025. Os gestos viram os payloads já existentes; não foi inventada uma economia paralela. Etapas confirmadas ficam na conta. O rascunho parcial de cada etapa é salvo no navegador, separado por ID da montagem e etapa, com validação de versão, classe e índices. Esse rascunho não sincroniza entre aparelhos. Limpar o armazenamento local pode apagar a parte ainda não confirmada.

O kit ainda é fornecido pelo ateliê. Falha pede refazer; materiais reais, perdas de estoque, bônus competitivos e variante física rara continuam pendentes da PIP-58. A nota ainda é declarada pelo cliente e não deve virar bônus competitivo sem validação autoritativa. Nenhuma migração de produção, push ou deploy foi executado nesta entrega.

## Auditoria desta revisão

- Modelo: fabricação completa nas três classes, payloads compatíveis, cortes equivalentes em eventos densos/esparsos, recusa de encaixe errado e nó frouxo/forte demais, dano bloqueando conclusão, pausa, dois cliques e validação de rascunho.
- Integração: identidade oculta na preparação, bloqueio de confirmação antes de construir, retry idempotente após resposta perdida, teclas da oficina sem vazamento ao mundo.
- Navegador: fluxo comum completo na prévia e na conta Ana do banco local isolado, incluindo reserva, montagem, etapas salvas, saída/retomada com um nó parcial e nascimento de Rabbito confirmado na coleção.
- Layout: 1280×720 e iframes 390×844 e 844×390. Corrigidos overflow horizontal da grade móvel e contraste de textos herdados do jogo. Sem teste em aparelho físico ou controle físico.
- Suíte completa: 459 testes, 457 passaram. Falhas anteriores preservadas: auditoria da mochila no avatar sentado e conferência histórica dos móveis do piso inferior. Os 20 testes focados da oficina passaram após os ajustes de entrada.

Referências de estudo: [Fossil Fighters Frontier, Nintendo](https://www.nintendo.com/en-gb/Games/Nintendo-3DS-games/Fossil-Fighters-Frontier-893831.html) confirma o uso de ferramentas na extração. A tradução para construção de pipas é uma decisão deste projeto, não uma regra da referência. [Xbox Accessibility Guideline 107](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107) fundamenta a alternativa de entradas digitais. O blueprint do usuário determina a manipulação direta e a ordem de construção; sua orientação mais recente determina o mistério até o nascimento.
