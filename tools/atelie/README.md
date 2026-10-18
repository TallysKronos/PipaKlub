# Ateliê de Tilesets do PipaKlub — local v1

Inicie na raiz do repositório:

```powershell
npm run atelier
```

Abra http://127.0.0.1:5210. Requer o Node já usado pelo jogo; não instala dependências. O servidor escuta somente em loopback, serve arquivos do Ateliê, três módulos de renderização/navegação e PNG/JSON/TMJ dos assets. Não lê `.env`, não grava arquivos do jogo, não conecta ao banco ou à produção. `ATELIE_PORT` permite mudar a porta. Ctrl+C encerra.

## Primeira bancada

O piloto do Morro do Sol e suas 26 peças abrem prontos para edição. À esquerda estão as folhas e recortes. No centro, o mapa com grade, zoom e pan pelo botão do meio. À direita, posição, base física, escala proporcional, nível e ordem de profundidade do objeto selecionado. As camadas podem ser ocultadas para inspeção.

- Peça: clique para colocar. Selecionar: clique/arraste para mover. Delete remove.
- Piso e colisão: arraste retângulos, com encaixe opcional de 32 px. Pisos recebem a textura selecionada; colisões são bases invisíveis que bloqueiam Kael.
- Entrada: reposiciona o ponto inicial do teste. Caminhos, escadas, pisos e zonas são validados pelo mesmo `parseWorldMap` usado pelo jogo.
- Recortar: importe PNG (até 12 MB e 8192 px), arraste o recorte, defina uso, escala e ponto de apoio. A imagem fica embutida no projeto salvo.
- Testar com Kael: mesma navegação, colisões e profundidade do jogo. Clique no caminho ou use WASD/setas. Esc volta ao editor. O teste exige um mapa válido.
- Desfazer/refazer: até 35 estados por sessão. Alterações em lote por arrasto formam um único estado. Ctrl+Z / Ctrl+Shift+Z.

## Salvar e exportar

IndexedDB guarda automaticamente o último projeto neste navegador/origem, inclusive imagens importadas. O status informa falhas de quota; mantenha também um arquivo baixado em **Salvar arquivo**. **Abrir** restaura esse JSON. Porta diferente ou perfil de navegador diferente não compartilham essa gravação.

**Exportar para o jogo** valida o mapa e cria um ZIP local contendo `project.json`, `blockout.tmj`, `art.json`, `kit.json`, imagens e instruções. O ZIP preserva o contrato do piloto. A integração no jogo é uma etapa explícita de revisão e build: não existe publicação automática. As camadas Tiled são grupos de retângulos; este editor não exporta tilelayers/GIDs.

## Limites da versão 1

Ferramenta para compor e recortar arte existente, sem geração de IA ou pintura de pixels. Áreas de piso e colisão são retangulares, não polígonos. A edição de encontros/saídas é de geometria, não de regras ou recompensas; projetos novos começam sem encontros. NPCs não são criados pelo editor. Rotação e escala não proporcional são evitadas para manter a arte e o contrato atuais. Dados inválidos podem ser salvos como rascunho; teste/exportação ficam bloqueados até a correção. Objetos fora do mapa ou caminhos desconectados aparecem na revisão.

## Verificação

```powershell
node --test tools/atelie/atelie.test.mjs
```

O editor reutiliza os módulos do jogo e respeita a propriedade opcional `ground_frame` para as texturas de chão. Alterações aos mapas originais só acontecem ao integrar manualmente um pacote exportado.
