# Linha & Papel — loja ampliada no Godot

## 1. Arquivos criados e alterados

Branch `codex/loja-tcg-moderna`, baseada na reforma do professor. Brief, seis fontes, prompts e alfa em `art/loja-tcg-v1/`. Kit em `godot/assets/campaign/loja-tcg-v1/`. Planta `shop_data.gd`; renderer `shop_modern.gd`; integração em RoomView, frontend, adaptador do bairro e validação de checkpoints. Preset Windows inclui os PNGs/JSON brutos. Teste `shop_modern_checks.gd`; capturas `shop_modern_capture.gd` e fluxo verificável `shop_flow_capture.gd`.

O legado web tinha uma planta 14×11 em `src/service-interiors.js`; o Godot não tinha interior de loja acessível. A nova sala é 18×14, +63,6% de área. Dois conjuntos de mesas/bancos, duas estantes, balcão-vitrine, expositor de pipas e duas ilhas de mostruários. O dono é um novo NPC, conforme escolha do usuário, com sprite chibi próprio e colisão no pé; Lia e sua conversa continuam na rua.

Não houve reestruturação de saves: apenas o novo valor de cena `kite-shop`, com validação de posição contra o piso real. Saves anteriores continuam aceitos. O conteúdo canônico `content.json`, o exterior, a economia web e as recompensas não foram modificados. O checkpoint do bairro é preservado para a volta. Na zona de 0,65 célula junto à porta, entrar tem prioridade; fora dela, ainda é possível conversar com Lia.

## 2. Resultado automático

```text
SHOP MODERNO 45 checks; 6449 reachable samples; 0 isolated walkable samples; 0 failures; isolated save directory
SHOP FLOW 17 checks; doorway, movement, owner dialogue, save/resume, return; isolated directory
PROFESSOR MODERNO 37 checks; 4510 reachable samples; 0 unreachable walkable samples; 0 failures; no save access
CASA MODERNA 79 checks; bedroom 1807, home 4680 reachable samples; 0 failures; no save access
CAMPAIGN CHECKS: 206 checks, 0 failures
CAMPAIGN VIEW CHECKS: 30 checks, 0 failures
PLAYER FLOW: 7 checks, 0 failures
OVERWORLD 313979 checks; 0 failures
Morro maps/views: 9386 checks, 0 failures
node --test tools/mapa-studio/model.test.mjs: 6 pass, 0 fail
6 alpha assets validated
```

Todos os processos terminaram com código 0. As verificações específicas e o fluxo completo não emitiram erros de script/shader. O teste geral de views informa 2 instâncias em uso ao sair; o teste geral de fluxo informa 2 recursos em uso, diagnósticos de encerramento distintos das asserções funcionais. O teste geral do overworld ainda emite a condição do compilador de shaders em `_painted_floor`, já observada antes desta tarefa, no renderer externo não alterado. O relatório geométrico compartilhado escrito pelo teste foi revertido. Os diretórios de teste são isolados dos saves do usuário.

## 3. Capturas

Individuais nativas a 1280×720; detalhes a 2×.

- `geometria-*`: planta e volumes chapados, incluindo a posição do dono.
- `arte-*`: geral com/sem atores; detalhes de balcão, entrada, estantes, expositores, mesas e canto de paredes; dono no balcão; oclusão atrás/à frente de balcão e mesa.
- `fluxo/01-porta-bairro.png` a `05-retorno-bairro.png`: entrada real, interior com HUD, conversa com dono, retomada e volta ao bairro.
- `kit-contato.png`, `detalhes-contato.png`, `evidence.json`: pranchas, dimensões e hashes. As seis fontes são idênticas às cópias de runtime.

Não há captura anterior do interior no Godot porque ele ainda não existia. A comparação de área usa a planta do legado, sem apresentá-la como uma captura antiga da versão Godot. A regra de partes A/B/C e itens de exploração não se aplica a esta loja.

```powershell
godot --headless --path godot --script res://tests/shop_modern_checks.gd
godot --path godot --script res://tools/shop_modern_capture.gd -- --name=arte
# Para cores chapadas: KAEL_ROOM_GEOMETRY=1 e --name=geometria
godot --path godot --script res://tools/shop_flow_capture.gd
```

## 4. Percurso

Busca de alcance pelo `_safe` real: 6.449 amostras alcançáveis e nenhum bolsão caminhável isolado. Conferidos os seis hotspots, colisão do dono, escala uniforme e oclusão atrás/à frente de móveis. O fluxo visual usa o frontend real e o movimento de encenação com pathfinding: entra pela porta do bairro, caminha ao balcão sem atravessar móveis, abre e fecha a conversa, salva no local, recarrega o slot, preserva a posição, caminha à saída e retorna ao mesmo ponto livre do bairro. Conferida também a conversa com Lia fora da zona da porta. Não foi uma sessão manual com controle físico.

## 5. História e itens

Nome de lugar Linha & Papel reaproveitado da identificação da Lia no bairro. Novo personagem identificado somente pelo cargo, sem nome pessoal nem revelações de história. Nenhum item, carta de inventário, moeda, preço ou recompensa nova. Os produtos e cartas das mesas são cenográficos. Não se inicia compra ao conversar com o dono.

## 6. Integração

Loja acessível pela porta existente do bairro; conversa e prévia do save integradas. O sistema de compras do legado permanece intacto. O catálogo/economia de compras ainda não está portado para Godot; não foi fabricado um checkout que pareça conceder itens. Mesas não têm minigame de cartas.

## 7. Dúvidas para o dono

Sem bloqueio para esta reforma. Nome pessoal do novo lojista pode ser definido depois. A revisão estética final dos móveis e do NPC continua com o dono do projeto.

## 8. O que não foi verificado

Não houve exportação Steam/Windows, teste com controle físico, migração online, teste de compra ou implementação de TCG jogável. O NPC é estático e não foi certificado como animação. Os fluxos foram automatizados em uma máquina, não em duas contas online. Sem push, merge ou deploy nesta entrega.
