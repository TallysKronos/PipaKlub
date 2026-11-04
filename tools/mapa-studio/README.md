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

### Revisão PIP-81

O auditor também detecta duas peças sólidas ocupando a mesma célula. A camada opcional `zonas` contém retângulos de orientação visual (`uso`), sem alterar navegação; aparece apenas na versão com legendas.

Para salvar referências diretamente na pasta fixa `documentation/overworld/pip81/references`, inicie com `MAPA_STUDIO_EXPORT=1` e abra `?mapa=<id>&salvar=1`. Esse modo opcional aceita somente PNGs de referências de plantas existentes, originados na própria bancada local. Fora dele o servidor continua somente leitura e a exportação baixa o PNG normalmente.

No jogo, abra `/?overworld=veredas-piloto` e use **Jogar → Exploração e campanha → Mapa piloto** para iniciar a conferência na entrada. A passagem das Veredas na Clareira também leva ao piloto com esse parâmetro. Sem o parâmetro, o atalho não aparece. A prévia não concede recompensas nem salva posição de campanha.
