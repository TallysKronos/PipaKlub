# Abertura e Rua dos Ventos em isometria

**Revisão de 23/10/2026:** a disposição v1 do quarto foi reprovada em auditoria. O quarto foi reconstruído com planta compartilhada, colisões, pontos de aproximação e encaixes de parede na v2. Consulte `quarto-kael-v2.md` para o contrato atual e `auditoria-quarto-kael-2026-10-23.md` para os defeitos históricos. As descrições da vila abaixo registram a entrega original.

## Entrega

O quarto e a sala de Kael, a Rua dos Ventos, a casa do Sr. Assis e a loja de pipas usam o mesmo renderizador isométrico e a mesma família de objetos. Fachadas de reboco, esquadrias azul-petróleo, telhas cerâmicas e móveis de madeira se conectam à vegetação e às animações Soulgen já aprovadas para o parque.

São dezoito sprites novos, dois atlas de autoria e desenhos de projeto no quarto. O chão da rua usa a união dos polígonos reais de caminhada, com uma única borda e paginação contínua, evitando emendas entre retângulos. Vegetação enquadra as bordas e mantém os caminhos livres.

A câmera começa na transmissão animada da TV e revela o quarto. A bancada, o presente, o nascimento, o nome do parceiro, a escada e a saída mantêm a história existente. Personagens e parceiros usam profundidade; objetos que encobrem Kael ficam transparentes. Cliques, teclado e controle convertem a direção da tela para a navegação canônica.

## Contratos preservados

- Geometria Tiled, nós, portais e coordenadas de campanha.
- RPCs, progressão e concessão única de Rabbito; reprise sem recompensas.
- Loading recuperável e bloqueio de movimento durante menus.
- Pausa de movimento ambiente e preferência de movimento reduzido.
- Nenhuma migração SQL ou alteração de conta de produção.

## Validação

`npm test`: 385 testes passaram. Inclui três testes novos de integração das cinco cenas, registro e cópia dos PNGs, inversão de câmera, cliques em móveis/NPCs e posições salvas. O teste de entrada automática foi adaptado às direções da tela isométrica.

`node build.mjs` e `node build-pages.mjs`: builds completos.

`npm run audit:world`: passou para o projeto modular legado que esse comando verifica; não substitui a revisão visual das cenas novas.

Navegador real, servidor em `127.0.0.1:5243`, banco local isolado:

- Campanha nova de Kael: transmissão, revelação do quarto, clique na mesa, montagem, entrada da mãe, presente, colocação da rabiola, nascimento, nome, Rabbito seguindo, escada, sala e saída para a rua.
- Conta Ana com fixture local de campanha concluída: caminhada da rua à casa do professor, clique no Sr. Assis e diálogo de prática, sem iniciar repetição de aula.
- Retorno do professor à rua, entrada na loja e clique no balcão abrindo o catálogo de linhas, sem compras.
- Reprise pelo menu Clube → Rever a abertura, com a arte final, sem alterar a coleção.

Capturas em `documentation/evidence/village-isometric-v1/`.

## Limites

A apresentação continua sendo Canvas 2D com sprites e projeção isométrica; os mapas de física mantêm seus eixos originais. As imagens estáticas de fachadas e móveis não possuem rigs individuais. Árvores, bandeirinhas e pipa reaproveitam animações Soulgen do parque. A revisão em navegador foi feita no desktop; as câmeras estreitas têm cobertura automatizada, mas ainda merecem revisão em um telefone físico.

Esta entrega não inclui publicação no Render nem mudanças no Supabase de produção.
