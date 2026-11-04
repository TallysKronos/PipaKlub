# Casa do Kael — reforma contemporânea dos dois pisos

**Atualização posterior:** o dono pediu um térreo maior e uma porta para o quarto da mãe. A implementação vigente e as novas verificações estão em [ampliacao-terreo.md](ampliacao-terreo.md). As dimensões e a câmera do térreo descritas como preservadas abaixo se referem à primeira reforma, antes desse pedido.

## 1. Arquivos criados e alterados

Branch local `codex/quarto-kael-manga`, baseada em `codex/mapa-submerso`. Integração em `godot/scripts/campaign/room_view.gd`; renderer novo `house_modern.gd`; kit em `godot/assets/campaign/casa-moderna-v1/`; fontes, brief, prompts e QA em `art/casa-kael-moderna-v1/`. Ferramentas reproduzíveis `house_modern_capture.gd` e `house_modern_opening_capture.gd`; teste `house_modern_checks.gd`.

O preset Windows inclui explicitamente os PNGs originais e o JSON deste kit, pois o renderer lê esses arquivos diretamente. Não foi gerado um executável nesta tarefa.

Os dois interiores usam branco/creme, azul, madeira clara e plantas, seguindo a fachada fornecida pelo dono. A TV de tubo permanece canônica. Planta, câmera, colisões, pegadas, hotspots e encenação vêm do mesmo `content.json`, que não foi modificado. Sem mudanças em roteiro, recompensas ou saves. A especificação de regiões A/B/C e percentuais de platôs não se aplica a esta reforma dos dois interiores existentes.

## 2. Resultado automático

```text
CASA MODERNA 72 checks; bedroom 1807, home 2683 reachable samples; 0 failures; no save access
CAMPAIGN CHECKS: 206 checks, 0 failures
CAMPAIGN VIEW CHECKS: 30 checks, 0 failures
OVERWORLD 313979 checks; 0 failures
Morro maps/views: 9386 checks, 0 failures
node --test tools/mapa-studio/model.test.mjs: 6 pass, 0 fail
11 alpha assets validated
```

Os processos terminaram com código 0. Há diagnósticos que não devem ser confundidos com uma execução totalmente limpa: `campaign_view_checks` informa 1 recurso ainda em uso ao sair; `morro_map_checks`, 13 instâncias e 4 recursos; `overworld_checks`, uma condição do compilador de shaders em `_painted_floor` do renderer externo. Esses caminhos e shaders não foram alterados por esta reforma. As capturas nativas de ambos os interiores, o teste específico da casa e a abertura não emitiram erros de script ou shader. O relatório geométrico compartilhado escrito pelo teste foi revertido.

## 3. Capturas

Todas as capturas individuais são nativas, 1280×720. Pranchas de contato são composições para comparação.

- `quarto-antes*.png` e `sala-antes*.png`: referência anterior.
- `bedroom-geometria-*` / `home-geometria-*`: casca, volumes e escadas antes da aplicação da arte.
- `bedroom-arte-*` / `home-arte-*`: visão geral com e sem atores, detalhes ampliados a 2× e poses de oclusão.
- Detalhes: cama, mesa de criação, canto de paredes, descida, sofá, jantar, cozinha, porta e pé/topo da escada ascendente. Juntas sem personagens.
- `abertura/01...09`: cenas reais do frontend, da volta da TV até a conversa no térreo, em progresso isolado.
- `antes-depois.png`, `kit-contato.png`, `detalhes-contato.png`: comparação e revisão.
- `evidence.json`: dimensões e SHA-256 dos PNGs, incluindo conferência de igualdade entre fontes e cópias do kit.

Reproduzir no Godot 4.7.2, a partir da raiz:

```powershell
godot --path godot --script res://tools/house_modern_capture.gd -- --room=bedroom --name=bedroom-arte
godot --path godot --script res://tools/house_modern_capture.gd -- --room=home --name=home-arte
# Para a versão geométrica, definir KAEL_ROOM_GEOMETRY=1 e usar outro --name.
godot --path godot --script res://tools/house_modern_opening_capture.gd
godot --headless --path godot --script res://tests/house_modern_checks.gd
```

## 4. Percurso

Busca automatizada no mesmo `_safe` do personagem, com malha de 16 unidades: 1.807 amostras alcançáveis no quarto e 2.683 no térreo. Conferidos os hotspots, pontos da história, bloqueio dos móveis, presença de todas as peças, escala uniforme e ordenação do personagem à frente/atrás de cama, mesa e sofá. A encenação real moveu a mãe na escada, pelo quarto e pela sala; foram capturados presente, nascimento, nomeação e saída. As poses de oclusão foram posicionadas automaticamente. Não foi uma sessão manual completa com controle físico.

## 5. Itens, pistas e revelações

Nenhuma adição de item ou alteração de história. Preservados a TV CRT, a bancada de criação do Rabbito, a entrega da Rabiola Antiga e os pontos de surgimento/diálogo. O desenho de pipa na parede é decorativo.

## 6. Pedidos ao integrador

Nenhum para ativar os interiores vivos: o RoomView já usa o kit. O filme pré-renderizado exibido na TV continua com o cenário anterior e precisará de uma produção própria para harmonizar todos os planos da abertura.

## 7. Dúvidas para o dono

Sem bloqueios. Falta a avaliação estética final dos dois pisos e da descida revisada. Recomendação: manter o CRT como objeto nostálgico da família dentro da casa contemporânea.

## 8. O que não foi verificado

Não houve exportação Steam, teste de controle físico, teste do renderer legado web nem percurso manual integral. O filme pré-renderizado não foi refeito. As cores chapadas validam a apresentação sobre a planta existente; não há navegação 3D contínua entre pavimentos: a troca de ambiente continua pelo fluxo existente. Esta entrega não faz deploy nem push.
