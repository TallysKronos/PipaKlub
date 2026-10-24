# Ateliê — fundo de ambiente v1

- Arquivo de runtime: `tools/oficina-v3/atelier-v1.png`
- Dimensões: 1672 × 941; PNG opaco, imagem única de cenário.
- Origem: gerado com a ferramenta de imagens nesta conversa, em 24/10/2026, para Soulmonsters. Não deriva das criaturas da referência enviada.
- Direção: ateliê brasileiro em 2D com contornos nítidos, madeira terracota, teal, bambu, papéis e rabiolas. A janela ilumina a esquerda; a lanterna aquece a direita; o centro fica reservado à bancada e ao resultado.
- Uso: fundo `cover` da Oficina v3; sem colisão ou pivô de gameplay, sem texto, botões ou personagens embutidos. HUD e bancada continuam em DOM/Canvas.
- Distribuição: lista explícita de arquivos em `scripts/workshop-v3-build.mjs` e no servidor de prática. Os dois builds copiam o asset para `docs/oficina-v3/`.
- Movimento: luz ambiente por CSS, flutuação suave do retrato no resultado; respeita movimento reduzido.
- Verificado: inspeção da ilustração gerada, sintaxe e compilação. Não foram feitos testes nem validação visual jogando.
