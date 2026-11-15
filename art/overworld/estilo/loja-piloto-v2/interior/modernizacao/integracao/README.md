# Loja moderna integrada

O interior da Linha & Papel usa o atlas aprovado em godot/assets/campaign/loja-interior-v2/. A cena continua sendo kite-shop, acessada pela porta da loja no bairro. A prévia dos saves também usa o interior novo.

Os vinte recortes são montados em escala 1×, com filtro nearest. A projeção do jogador usa células 64 × 32 e a origem medida no quadro. O Kael também usa escala 1×. A câmera acompanha sua posição, limitada ao canvas de 1120 × 820, dentro do enquadramento de exploração. Em resoluções menores que a área de referência, o layout existente adapta o stage à janela.

As colisões e os pontos de interação foram calibrados para a pintura. O corredor central permite passagem de três células entre a gôndola e as mesas. As mesas, prateleiras, balcão e porta participam da ordenação dos personagens pelo apoio no chão. O dono continua usando sua arte existente, com filtro nearest, atrás do balcão.

Saves antigos que apontam para uma área agora ocupada por móveis são reposicionados no piso livre mais próximo. O ID da cena e as coordenadas lógicas persistidas foram preservados.

## Evidências

- 02-interior-hud.png mostra a entrada pelo fluxo real da campanha.
- 03-dono-conversa.png mostra a interação com o caixa.
- 04-retomada.png mostra a posição restaurada do save e o contorno de interação.
- 06-estantes.png, 07-mesa-fundo.png, 08-mesa-frente.png e 09-gondola.png mostram os demais pontos acessados por caminhada.
- 05-retorno-bairro.png mostra a volta pela porta.
- moderno-v2-geral.png e moderno-v2-sem-atores.png mostram o cômodo completo em captura nativa.
- verificacao.json registra a comparação do quadro aprovado com a captura runtime sem atores. Os 469.525 pixels visíveis coincidem.

## Verificação

- Loja — 45 verificações, 4.848 amostras de piso alcançáveis, zero bolsões caminháveis isolados.
- Fluxo — 24 verificações de entrada pelo bairro, movimentação até todos os pontos, conversa, bloqueio e retorno dos controles, salvamento, retomada e saída.
- Laboratório da pasta principal — 62 verificações de regressão, 4.510 amostras alcançáveis.
- Movimentação da cidade e cômodos — 11 verificações.

Os testes criam saves isolados em godot/.godot/. Estas evidências foram produzidas no projeto principal C:/Users/user/produto/pipa-club/godot, na branch codex/unificacao-final.

A integração transfere a loja da branch codex/laboratorio-v2-blockout, commit 253a7116. As alterações locais anteriores da pasta principal foram preservadas. O frontend recebeu somente a prévia da loja, o suporte ao stage nativo e sua seleção na cena kite-shop. As mudanças locais já existentes no frontend foram conferidas por comparação com a cópia anterior, e ficaram fora do commit desta integração.

## Reprodução

Na raiz do checkout, com Godot no PATH e as imagens importadas.

```powershell
godot --headless --path godot --script tests/shop_modern_checks.gd
godot --path godot --script tools/shop_flow_capture.gd --rendering-method gl_compatibility
godot --path godot --script tools/shop_modern_capture.gd --rendering-method gl_compatibility -- --overview-only
godot --headless --path godot --script tests/professor_modern_checks.gd
godot --headless --path godot --script tests/locomotion_city_room_checks.gd
```
