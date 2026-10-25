# Lobo em pele de cordeiro — Soulgen

Projeto articulado: `color-rig-v2/lobo-cordeiro.soulgen.json`.
Importação independente, com PNGs embutidos: `color-rig-v2/lobo-cordeiro.portable.soulgen.json`.
Editor: `/?preset=lobo-cordeiro` no servidor Soulgen Studio.

Oito peças: tronco, cabeça/capuz, pipa dorsal, rabiola e quatro patas. Patas distantes reaproveitam os recortes dianteiro e traseiro com posicionamento próprio. Tronco é o pai das peças; cada peça possui pivô editável. Expressões neutra, feliz, feroz e dor substituem a cabeça inteira. Seis ações: idle, walk, flight, skill, hurt e victory, com expressões agendadas.

## Ajuste salvo e registro facial — revisão 2

Montagem atual importada de `lobo-em-pele-de-cordeiro-papel-vivo.soulgen (4).json`, salva pelo usuário em 24/10/2026 às 16:36. Original arquivado em `user-adjustment/user-saved.soulgen.json`. Retângulos, pivôs, ordem, parentesco e animações preservados.

As variantes agora compartilham o tamanho e o alpha da cabeça neutra (355 × 331); somente a janela dos olhos/sobrancelhas muda. A boca e o contorno permanecem canônicos para evitar saltos de silhueta. `scripts/register-lobo-faces.py` registra a arte gerada sem desenhar olhos por código. O editor atualiza somente essas referências nos projetos antigos reconhecidos, preservando a montagem em cache. Referências anatômicas ainda não foram medidas; o aviso informativo e a necessidade de revisão visual continuam válidos. O atlas de autoria anterior não representa os ajustes salvos e não deve ser usado como exportação final.

Origem: referência fornecida pelo usuário e conceito adaptado ao Carcará. Peças e expressões geradas com image_gen integrado; recortes e limpeza de fragmentos vizinhos feitos no script de exportação. PNG fonte preservado em `source/parts-generated.png`. O sino do conceito não está incluído neste primeiro rig.

`scripts/build-lobo-cordeiro.mjs` produz o projeto, versão portátil, retrato, prancha de revisão e atlas de autoria a 12 FPS. Não escreve no atlas do jogo nem substitui criaturas existentes. Verificação de contrato durante exportação e inspeção da prancha; sem execução de suítes de testes ou validação de combate. Ajustes salvos pelo usuário no editor devem ser preservados antes de executar novamente o gerador.
