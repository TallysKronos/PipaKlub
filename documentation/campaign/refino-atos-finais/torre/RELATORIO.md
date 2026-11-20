# Torre do Vento — relatório de refino

## 1. Arquivos e escopo

- `godot/scripts/overworld/wind_tower.gd`: peça com base ilustrada reutilizada, mastreação, quatro velas, geometria simples e estado ativo.
- `mountain_structures.gd`: montagem somente em kronasta-montanha-c.
- `park_overworld_view.gd`: estado salvo, convergência no receptor e enquadramento/restauração da câmera.
- `endgame_staging_checks.gd`: apoio da base, rota, fontes/destino, câmera, movimento reduzido e atualização de estado.
- `wind_tower_capture.gd`: capturas reproduzíveis sem personagens sobre a base.
- Brief em `art/overworld/briefs/torre-do-vento-refino.md`.

A planta, os geradores, os arquivos de mapas e os kits alheios não foram alterados. O novo marco reutiliza o pilar da Câmara do Elo; as velas são polígonos 2D com contorno e dobra. Não é uma nova ilustração de torre pintada.

## 2. Resultado automático

- Endgame staging: 0 failures, incluindo movimento normal/reduzido e restauração de câmera.
- OVERWORLD 565281 checks; 0 failures.
- Morro maps/views: 9386 checks, 0 failures.
- Mapa Studio model: 6 testes passaram.
- Montanha: 3 testes passaram e 1 falhou na comparação entre gerador e mapa integrado. O gerador ainda produz “Mirante do cume”; o JSON integrado contém o NPC Tufanocorte e suas propriedades. Os três arquivos envolvidos estão inalterados nesta entrega. Não sobrescrever o evento de campanha para satisfazer o gerador antigo.

A base usa duas células já bloqueadas de rocha, ambas na cota 7. A rota caminhável do cume continua alcançável. Esta alteração não gera novos itens, revelações ou conexões.

## 3. Capturas

- `art-area.png`, `geometry-area.png`: área inteira.
- `art-game.png`, `geometry-game.png`: enquadramento de jogo sem personagens.
- `art-base.png`, `geometry-base.png`: base ampliada a 2x, sem personagem ocultando a junta.
- `../torre-convergencia.png`: montagem preparada dos quatro participantes com os feixes no receptor, HUD oculto.

A geometria simples confere topo e duas faces da base. Não houve alteração de rampa, escada, margem ou mureta; suas juntas não receberam nova auditoria manual completa.

## 4. Percurso e história

O teste geral executa navegação de controle, saídas e NPCs do overworld. Foi conferida também a rota da posição do evento até o cume. Não houve uma sessão humana contínua do ato 5 nesta entrega. A torre cumpre o papel já definido em §7.6 da Bíblia, sem nova revelação.

## 5. Pendências e limites

- Mostrar os Desalmados recuperando suas almas na cidade, com antes/depois reconhecível.
- Arte própria de Trovareta permanece pendente; usa Raio de Sol provisoriamente.
- O teste antigo de sincronização do gerador da Montanha precisa incorporar a integração de Tufanocorte de forma explícita.
- As capturas do efeito são preparadas por fixture. Não equivalem a um playtest completo com dispositivo físico ou a uma gravação de toda a campanha.
- Sem publicação ou push nesta etapa.
