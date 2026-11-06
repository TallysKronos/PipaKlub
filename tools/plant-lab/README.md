# Jardim de Kronasta — bancada de tiles

Área pequena de edição top-down com os seis novos sprites de vegetação e Kael. Ferramenta local de composição, separada da campanha.

## Abrir

Execute `Iniciar.ps1` nesta pasta, ou `node tools/plant-lab/server.mjs` na raiz do repositório. Endereço padrão: **http://127.0.0.1:5256**. Sem instalação de dependências novas. `PLANT_LAB_PORT` permite outra porta.

## Edição em tempo real

- Biblioteca: escolha uma das seis plantas. B planta com clique/arraste.
- V seleciona pela silhueta opaca e arrasta; a seleção marca a raiz.
- E ou botão direito apaga. Del exclui a seleção; Kael não é excluído.
- Inspector: posições X/Y, espelho, duplicação. Ctrl+D duplica.
- Piso: três materiais provisórios de apoio; clique e arraste pinta células32×32.
- H / Morro: pinta a cota escolhida (0–12, 16px por nível), em 1×1 ou 2×2 células. Face de terra ou rocha.
- U / Rampa: liga cota baixa ao sul a outra 1 nível acima ao norte. Shift+clique remove. Uma edição de altura elimina rampas que perderem a conexão.
- Mostrar cotas: sobreposição numérica de diagnóstico. Morros de exemplo: aplica dois platôs com acessos, preservando plantas; pode ser desfeito.
- Ctrl+Z e Ctrl+Shift+Z (ou botões) desfazem/refazem o gesto inteiro, incluindo uma pincelada de piso.
- Roda/botões: zoom inteiro1–4×. Meio do mouse ou Space+arrastar: câmera. Centralizar volta a1×.
- Encaixe8px é opcional. Grade32px pode ser ligada/desligada.
- Testar (ou Tab com canvas focado): WASD/setas move Kael e Shift corre. Tab retoma edição. A pose é estática; rampas permitem subir e paredes dos barrancos bloqueiam. Plantas não têm colisão.

As edições ficam em localStorage (`soulmonsters.plant-lab.v1`) neste navegador/origem. JSON serve para guardar ou transferir a composição. A importação valida dimensões, materiais, IDs, posições e contagem de peças. Restaurar o jardim inicial pode ser desfeito.

## Godot de verdade

**Projeto Godot** baixa um ZIP com o layout atual, oito texturas (seis plantas, frente/costas de Kael), `project.godot`, cena e script. Extraia tudo, abra `project.godot` no Godot4 e execute. É um projeto independente, sem autoloads ou saves da campanha. A bancada nativa também permite plantar, mover, apagar, pintar piso e testar Kael; consulte o README incluído no ZIP para atalhos.

Há uma cópia inicial em `godot-preview/project.godot`, preparada por `node tools/plant-lab/prepare-godot.mjs`. Esse comando regenera a cópia inicial; não o use para preservar mudanças feitas diretamente nos arquivos dela. F5 **na janela do jogo** salva o layout nativo em uma pasta de usuário exclusiva `SoulmonstersPlantLab`, reaberta na próxima execução. A exportação do navegador é baixada, sem escrever sobre a campanha.

## Direção e limites

Grade top-down quadrada32×32, por instrução atual do usuário. O contrato isométrico64×32 dos mapas da campanha não foi alterado. Plantas64×64 com raiz(32,52), Kael80×80 com raiz(40,65), sem redimensionar os pixels. Sprites são os PNGs recém-aprovados; pisos são bases procedurais provisórias. O relevo é uma simulação procedural editável, com sustentação, rampas e bloqueio por desnível. Não contém água, encontros, colisão de vegetação ou animação de caminhada.

Navegador e Godot usam as mesmas cotas, rampas, projeção e bloqueio por desnível, com texturas procedurais de apoio diferentes. A disposição, escala, raízes e profundidade são compartilhadas; não são renders idênticos do piso.

## Verificação

- `node --test tools/plant-lab/lab.test.mjs tools/plant-lab/terrain.test.mjs`: modelo, importação, ordenação, ZIP com CRC e layout editado, rotas e rejeição de arquivos fora da lista.
- `node tools/plant-lab/ui-check.mjs`: Playwright; usa `PLAYWRIGHT_MODULE` para indicar o módulo se necessário. Edição, persistência, importação, exportação real e quatro resoluções.
- Projeto importado e executado headless no Godot4.7.2 sem erros de script. Isso verifica inicialização/importação; não equivale a playtest manual da janela nativa.
- Capturas e relatório em `documentation/plant-lab-v1/captures/`.

Servidor escuta somente loopback, serve apenas arquivos autorizados e gera ZIP em memória. Não há banco, conta, upload remoto ou gravação da composição no repositório via HTTP.

- `node tools/plant-lab/terrain-ui-check.mjs`: altura/material, desfazer, rampas e captura das juntas sem vegetação.
- `check_terrain.gd` na prévia: teste nativo de subida/descida, barreira e inversão da projeção.

Layouts antigos sem campos de relevo são importados planos para preservar a composição. Use **Morros de exemplo** para experimentar; Ctrl+Z desfaz.

## Edição atrás dos barrancos

O botão **Editar atrás dos barrancos** revela a composição sem alterar os dados. Escolha **Apoio** (0–12) para plantar em uma superfície real dessa cota, mesmo encoberta por terreno mais alto à frente. Mover, apagar e selecionar também enxergam os objetos ocultos. No modo Testar a oclusão volta automaticamente. O modo de revelação não é exportado como aparência do jogo; posições e alturas são preservadas.

Teste específico: `node tools/plant-lab/behind-ui-check.mjs`; capturas `editar-atras-revelado.png` e `editar-atras-teste-normal.png`.
