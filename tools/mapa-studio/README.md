# Mapa Studio

Bancada local para as plantas do overworld feitas no Tiled. As regras completas estão em `art/overworld/ESPECIFICACAO-MAPAS.md`.

```
npm run studio:mapa      # http://127.0.0.1:5244  (MAPA_STUDIO_PORT muda a porta)
npm run mapa:piloto      # gera de novo art/overworld/mapas/veredas-piloto.tmj (sobrescreve)
node --test tools/mapa-studio/model.test.mjs tools/mapa-studio/server.test.mjs
```

- O seletor lista os `.tmj` de `art/overworld/mapas/`. Depois de salvar no Tiled, use **Recarregar mapa**. A posição do Kael é mantida.
- **Abrir .tmj** carrega um mapa do computador. Selecione o `.tsj` junto se o tileset não for o `rascunho`.
- Clique no chão para o Kael andar (caminho A* em 4 direções). As setas ou WASD andam uma célula, e a rampa sobe o Kael aos poucos.
- **Conferência**: clique num item para ver a célula piscando no mapa.
- **Baixar referência para o Codex**: PNG 2× sem textos, sem grade e sem eventos, para pintar por cima. **Com legendas**: grade, nomes e coordenadas, para conversar sobre a planta.
- O servidor só lê arquivos: nada é gravado no repositório.
