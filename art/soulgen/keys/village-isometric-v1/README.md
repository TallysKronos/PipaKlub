# Vila inicial — isometria v1

**O quarto v1 foi reprovado na auditoria de 23/10/2026 e substituído pela planta v2.** A arte raster desta família foi reaproveitada; `src/bedroom-layout.js` agora governa disposição, apoios, colisões, parede e narrativa. Ver `documentation/quarto-kael-v2.md` e o registro histórico em `documentation/auditoria-quarto-kael-2026-10-23.md`.

Família de arte criada para continuar o parque aprovado na abertura do jogo.
Inclui quarto, sala da casa de Kael, rua, casa do professor e loja de pipas.

**Rua atualizada:** a disposição da rua v1 foi substituída pela planta espaçosa v2 em `src/street-layout.js`. As fachadas deste kit continuam intactas; chão, acessos e objetos foram reorganizados. Ver `documentation/rua-dos-ventos-v2.md`. A afirmação abaixo sobre preservar polígonos legados se refere à integração v1, não à nova planta.

## Direção e origem

- Dois atlas originais gerados com a ferramenta de imagem do Codex, com fundo transparente: `source-exterior.png` e `source-interior.png`.
- Fachadas de reboco creme, telhas cerâmicas, esquadrias azul-petróleo, madeira quente e detalhes de pipas. Móveis com contorno escuro e poucas massas de sombra; sem textura fotográfica.
- Os assets de vegetação, bancos, luminárias, bandeirinhas e pipa continuam usando a família aprovada `park-isometric-v1` e seus rigs Soulgen.
- Os atlas são fontes de autoria; não são carregados pelo jogo. Apenas os dezoito recortes são publicados.

## Preparação

`slices.json` guarda as células revisadas. Execute `python scripts/prepare-village-isometric.py` com Pillow instalado para reproduzir os recortes.
O script recorta pelo alfa acima de 32, mantém o alfa original, adiciona 6 px transparentes de margem e atualiza dimensões, pivôs e origem no manifesto. Não redimensiona a arte.

`assets/world/village-isometric-v1/manifest.json` é o contrato de runtime. Os pivôs das fachadas são a entrada, não o centro da imagem. A projeção de chão é `(x-y)*0.82, (x+y)*0.41`, igual à do parque.

## Integração

`src/village-isometric.js` desenha piso, paredes, objetos e personagens ordenados pela profundidade. Objetos que encobrem o jogador ficam parcialmente transparentes. Câmera, cliques e direções usam a mesma projeção.

A abertura mantém os passos, textos, ações de montagem, nome e concessão do parceiro existentes. TV, bancada, escada e saída continuam interativos; a transmissão ocupa a tela da nova TV e a câmera afasta para revelar o quarto. O overworld usa as mesmas peças após a abertura.

Esta é uma substituição de apresentação: os polígonos de navegação, nós, portais, salvamentos e RPCs de progresso permanecem nos mapas canônicos. Não requer migração de banco.

## Verificação

- `village-runtime.test.mjs`: cinco cenas, destinos alcançáveis, profundidade, cliques, NPCs, inversão de câmera e registro dos PNGs.
- `first-flight.test.mjs`: caminhada pelas portas com controles orientados à tela, retorno e pausa em menus.
- `opening.test.mjs`: progressão narrativa, montagem, nascimento e isolamento de conta/reprise.
- Auditoria visual em campanha nova, usando banco local isolado. Capturas e resultados consolidados em `documentation/village-isometric-v1.md`.
