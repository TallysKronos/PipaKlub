# Eremor · Soulgen Studio v3

22/10/2026. Rig editável derivado do conceito de `art/concepts/eremor-v1/eremor.png`, usando a engine Canvas existente. Preserva a paleta marfim, petróleo, terracota e turquesa, garras, nó, velas e rabiola bifurcada. As folhas de batalha e overworld anteriores permanecem intactas.

## Abrir

Execute `npm run studio:sprites`, abra http://127.0.0.1:5240/ e use **Projeto e biblioteca → Abrir Eremor · Elo das Ruínas**. Abrir um preset usa o diálogo e histórico existentes; não substitui um ajuste de pose pendente.

Também é possível abrir ou arrastar `eremor-v3.soulgen.json` para o Soulgen. Esse JSON incorpora os sete PNGs e não depende dos caminhos do repositório para reabrir. O preset e o arquivo portátil contêm as mesmas peças, articulações e ações. Salvar, reabrir, editar e exportar continuam usando o fluxo comum da ferramenta. `eremor.soulgen.json` é um alias atualizado da revisão 3. Projetos antigos salvos no navegador não são migrados automaticamente: abra o preset atualizado ou o arquivo v2; salve suas alterações anteriores antes de substituí-las.

## Construção

Espaço lógico 340×280, pivô global (157,177). PNGs proporcionais, sem redução de paleta ou redesenho procedural. As dimensões reais e os hashes estão em `parts-report.json`; montagem em `rig-data.mjs` e parâmetros autorais em `scripts/build-eremor-soulgen.mjs`. A revisão 2 aumenta o tronco, reduz a cabeça e registra os encaixes independentemente dos pivôs; relatório em [AUDIT-V2.md](AUDIT-V2.md).

| Peça | Pivô lógico | Hierarquia |
|---|---|---|
| Tronco e patas traseiras | 169,173 | Corpo inteiro |
| Cabeça e pescoço | 131,32; 128,53 | Tronco |
| Braço próximo e garras | 162,855; 132,974 | Tronco |
| Braço distante e garras | 100; 132,843 | Tronco |
| Leque dorsal de velas | 143,44; 147,125 | Tronco; acompanhamento de 0,035 s |
| Rabiola bifurcada | 253,6; 176,173 | Tronco; acompanhamento de 0,12 s |
| Nó do Elo e tirantes | 103; 138,177 | Tronco; atrás do braço próximo |

O leque é uma peça conectada, não cinco velas soltas. Patas traseiras fazem parte do tronco. Braços são articulações únicas no ombro; não há cotovelo independente neste lote. O nó permanece preso ao tronco. Esses limites são editáveis e não representam um rig esquelético completo.

| Ação | Duração | Reprodução |
|---|---|---|
| Repouso ancestral | 3,6 s | Ciclo contínuo, respiração e balanço discreto |
| Planagem pesada | 2,8 s | Ciclo contínuo, sustentação e acompanhamento |
| Golpe de fundação | 2,4 s | Única; preparação, impacto em 1,05 s e recuperação |
| Dano e recomposição | 1,35 s | Única; recuo e recomposição |
| Elo reerguido | 3 s | Única; cabeça erguida e assentamento |

As ações únicas assentam antes do fim para que o atraso das peças termine em repouso. As curvas não mudam a escala do corpo. A revisão 3 possui cabeças registradas de golpe, dano e vitória. Somente a região dos olhos e sobrancelhas muda: focinho, mandíbula, orelhas, pescoço e alpha permanecem canônicos. A expressão substitui a cabeça inteira no mesmo retângulo, sem acrescentar outro rosto. Tempos, validação e origem em [AUDIT-V3.md](AUDIT-V3.md).

## Fontes e reprodução

Arte gerada com `image_gen` a partir do conceito existente. Fontes completas, inclusive pixels invisíveis, preservadas em `source/parts-generated.png` e `source/parts-clean.png`; prompts integrais em `source/prompts.json`.

`prepare.py` separa as sete ilhas de anatomia pelo alpha, preservando RGB e alpha original dos dois pixels de antialias ao redor de cada ilha. O isolamento impede que os retângulos sobrepostos do leque/rabiola e braço/nó carreguem fragmentos de outra peça. Não pinta anatomia nem inventa expressões.

Para reproduzir, use Python com Pillow em `art/soulgen/keys/eremor/prepare.py`, seguido por `node scripts/build-eremor-soulgen.mjs`. `measure.py` fornece medição independente das ilhas. A geração do projeto valida os dados antes de gravá-los.

`export-plan.json` registra o plano de atlas (12 FPS, células de 256 px, oito colunas); não é uma imagem exportada. `exports/eremor-v2.png` e `exports/eremor-v2.atlas.json` foram exportados pela interface real. São 163 quadros, 2048×5376 px, sem quadros vazios ou conteúdo tocando as bordas. Reproduza a verificação e a prancha diagnóstica com `audit-export.py`. O Soulgen também permite exportar runtime Canvas e prévia HTML. O JSON `.soulgen.json` é o projeto portátil, não um atlas.

## Validação e escopo

- Testes de fábrica/JSON portátil, dimensões reais dos PNGs e cópias independentes do preset.
- Amostragem de todas as ações a 60 Hz: pivôs dos membros coincidem com os pivôs herdados; retângulos permanecem no palco; escalas invariantes; ciclos sem salto e ações únicas assentadas.
- Regressão dos controles, cancelamento e abertura do preset, exportação e rotas permitidas do servidor local.
- Navegador: revisão 2 aberta pelo preset; revisão de repouso, planagem, antecipação/impacto, dano e vitória. Teste negativo com cabeça ampliada gerou dois avisos no audit; desfazer restaurou zero avisos. Evidências atuais em `review-audit-v2.png`, `review-audit-negative.png`, `review-windup-v2.png` e `review-poses-v2.png`. `review-studio.png` é histórico da revisão 1, contestada pelo usuário.

Estado: **compatível e integrado localmente ao Soulgen; nova arte articulada para revisão artística**. Não registra Eremor no catálogo, não troca o overworld ou a tela inicial, não altera economia/banco e não faz deploy. Inclui as três novas expressões faciais da revisão 3, sem afirmar aprovação visual do responsável pelo jogo.
