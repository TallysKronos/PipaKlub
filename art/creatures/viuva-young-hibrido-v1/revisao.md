# Revisão do piloto híbrido

## Resultado

Revisão independente: **8/10, sem bloqueante visual**. A leitura a frio identificou uma aranha-pipa com quatro velas rubras, abdômen marcado e patas finas articuladas.

Cabeça, abdômen, padrões e velas conservam os pixels aprovados. As patas foram reconstruídas com novas posições de juntas, passagem e contato, usando as fases do vídeo como referência. Nenhum pixel do MP4 foi incorporado. Os desenhos de patas são específicos desta criatura; não é um filtro aplicado ao catálogo inteiro.

Os grupos de apoio alternam nas duas vistas. A pata distante parcialmente oculta continua atrás do corpo. A transição da sexta para a primeira pose não mostrou salto estrutural evidente na revisão.

## Arquivos

- `idle.png`:4 poses por vista;448×224.
- `walk.png`:6 poses por vista;672×224.
- `viuva-young-hibrido.aseprite`:20 quadros, sete camadas, quatro tags e apoio(56,100).
- `poses.json`:juntas, pontas e grupos de contato por pose.
- `validacao.json`:limites, conectividade e volume por quadro.
- `auditoria-aseprite.json`:verificação do editável contra os atlas e dos pixels do corpo contra a base.
- `index.html`:original, recortes antigos, vídeo convertido e reconstrução, em1×/2×, com frente/costas e idle.

## Verificações e limites

Os vinte quadros usam somente cores da base, transparência binária e a mesma grade112×112. Todos têm uma silhueta opaca conectada, sem ilhas de um/dois pixels. As poses de caminhada têm três apoios por fase; o idle mantém os seis.

Na perspectiva isométrica, contatos diferentes têm coordenadasY diferentes. O referencial corporal fica estável; não se reposiciona cada quadro pelo bounding box. A silhueta inteira ocupa de67 a70px na caminhada conforme a elevação das patas; o corpo preservado não muda de escala.

Observação não bloqueante do revisor: algumas patas próximas se sobrepõem no miolo dos quadros2/5, reduzindo sua separação quando ampliadas. Continuam legíveis no tamanho nativo.

**Ainda não integrado.** Falta conferir a cadência acompanhando o deslocamento real no renderer do jogo, inclusive em corrida, antes de afirmar ausência de deslizamento. A comparação sobre uma captura real do mapa é um diagnóstico visual, não substitui esse playtest. A fila de geração de vídeos não foi alterada por este piloto.
