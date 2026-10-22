---
name: pipaklub-production
description: Produza ou revise assets e HUD do PipaKlub e diagnostique desempenho na engine JavaScript/Canvas existente. Use para sprites, tiles, objetos, interface e FPS/latência deste projeto, conectando seus contratos às skills externas selecionadas.
---

# Produção do PipaKlub

Trabalhe a partir da raiz do repositório. Preserve a identidade aprovada e consulte o consumidor real antes de propor novos formatos. O objetivo é melhorar a entrega solicitada, não migrar o motor ou revisar todo o jogo.

Escolha somente a área pertinente:

- **Assets:** leia [references/assets.md](references/assets.md), depois `../create-game-assets/SKILL.md`. Para criaturas, combine com a skill `pipamonsters` se disponível; para geração/edição de imagem, siga a skill de imagem disponível.
- **HUD, menus e overlays:** leia [references/interface.md](references/interface.md), depois `../game-ui-ux/SKILL.md`.
- **FPS, travamentos ou latência:** leia [references/performance.md](references/performance.md), depois `../performance-optimization/SKILL.md`.

As skills externas contêm exemplos de outras engines. Traduza os conceitos para os módulos existentes; referências a skills não instaladas são sugestões bibliográficas, não dependências que devem ser instaladas automaticamente. Atribua números de orçamento sugeridos a uma meta proposta, não a um limite já medido no PipaKlub.

Ao entregar, informe o que mudou, o que foi realmente verificado e suas limitações. Separe aprovação visual, verificação técnica, integração local e publicação. Não afirme que um PNG valida um spritesheet em movimento, que testes DOM provam o layout no navegador, ou que duas conexões no mesmo computador equivalem a duas redes físicas.
