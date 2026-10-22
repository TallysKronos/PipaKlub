# Eremor — batalha e overworld v1

21/10/2026. Gerado com image_gen integrada, usando o conceito de Eremor como referência de identidade. Prompts das três passagens em `prompts.json`. PNGs selecionados preservados sem alteração de pixels.

## Conteúdo

- `battle/eremor.png`: 1254×1254 RGBA, 16 quadros. Repouso 0–3, voo 4–7, habilidade 8–11, dano 12–13, vitória 14–15. Todas as poses voltadas à esquerda.
- `battle/eremor.json`: atlas, animações, durações e pontos de apoio medidos.
- `overworld/eremor.png`: 1536×1024 RGBA, grade 4×2. Colunas Sul/Oeste/Leste/Norte; linha 1 repouso, linha 2 passo complementar.
- `overworld/manifest.json`: contrato do renderizador `createWorldCompanions`, duas poses por direção a 240 ms. Escala de revisão proposta 1,65× a referência, sem definir tamanho oficial do boss no mapa.
- `validation.json`: medidas, hashes, alpha e margens dos 24 recortes.

## Recorte e animação

**Batalha não tem colunas uniformes.** Após duas correções de layout a geração ainda não respeitou a divisão exata em quatro. Preservamos os desenhos e medimos os espaços transparentes: limites X `[0,350,642,950,1254]`, Y `[0,313,627,940,1254]`. Usar os retângulos do JSON, sem dividir o PNG por quatro.

Manter escala fixa por folha e posicionar cada retângulo pelo `footAnchor`; não ajustar o tamanho de cada pose pelo bounding box. O renderizador atual de batalha não usa estes pontos de apoio; integrar exige seu adaptador de desenho. A prévia local já demonstra esse contrato, mas não registra Eremor no catálogo do jogo. O overworld usa o renderizador real de companheiros na prévia.

Habilidade e dano são sequências únicas com retorno sugerido a repouso; na prévia de inspeção param no último quadro para examiná-lo. A caminhada é um ciclo curto de duas poses, não uma animação longa de oito passos. Dorsais e cauda acompanham o corpo sem adicionar VFX soltos.

## Verificação e estado

Margem mínima de primeiro plano com alpha >32: 14 px em batalha, 50 px em overworld. PNGs com transparência real. Inspeção diagnóstica sobre fundos claro e escuro e revisão animada no navegador: repouso, habilidade quadro a quadro e direções de mapa. Há variação de volume/posição entre poses geradas; revisão artística final e ajuste fino dos pivôs ainda são necessários antes da integração.

Prévia: `node scripts/preview-eremor.mjs`, http://127.0.0.1:5232/. Medição reproduzível: `python scripts/build-eremor-pack.py` com Pillow. A edição offline exportada acompanha o ZIP.

Estado: **assets e prévia produzidos, sujeitos a revisão artística**. Sem alterações de conta, aquisição, atributos, campanha ou produção. Nenhum commit ou deploy incluído neste pedido.
