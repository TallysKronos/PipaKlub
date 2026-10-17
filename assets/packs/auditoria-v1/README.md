# Assets necessários — lote v1

Gerados com a ferramenta integrada imagegen a partir dos Pipamons existentes. Os PNGs originais foram preservados.

## Conteúdo

- Quatro folhas dos básicos, cada uma com 16 quadros: idle 0–3, flight 4–7, skill 8–11, hurt 12–13, victory 14–15.
- Três cenários das Trilhas: Morro do Sol, Beira-Mar e Campanários.
- Fundo próprio do Ascendente.
- Portal do Ascendente: formação 0–7, pulsação 8–11, dispersão 12–15.
- Partículas: quatro quadros por sequência (turquesa, dourada, rastro e explosão).
- Atlas com 12 ícones: moeda, cadeado, estrela, chefe, troca, invocação, rabiola disponível, rabiola danificada, ventania, linha encerada, garoa e neblina.
- As três folhas de líderes já criadas também foram incluídas; não foram geradas novamente.

## Uso

manifest.json contém tamanhos reais e recortes inteiros, incluindo células alternadas quando as dimensões não são divisíveis pela grade. Não assumir células de384px. PROMPTS.json guarda os prompts finais deste lote; os prompts dos líderes estão em seus diretórios no projeto. Sugestão inicial: repouso5fps, voo8fps, habilidade8fps, dano8fps, vitória5fps e portal10fps. Homologar ritmo, pivôs, margens e contraste na composição final antes de ativar em produção. Efeitos semitransparentes e partículas podem precisar de refinamento de borda após essa revisão.

Abrir index.html para revisar as imagens e sequências sem instalar ferramentas. Fundos possuem proporções reais diferentes; definir o enquadramento de cada cenário na integração, mantendo o céu central livre para o combate.

Este lote é de arte e preparação: ainda não foi registrado no atlas principal, copiado pelo build do jogo ou integrado às telas. Os assets atuais continuam preservados. Sem merge ou deploy.
