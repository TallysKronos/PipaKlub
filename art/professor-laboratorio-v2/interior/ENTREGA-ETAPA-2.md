# Laboratório v2 · Quadro-chave do interior

A maquete aprovada orientou a composição 2:1, a área livre na frente da bancada e as zonas do interior. O concept recortado e o detalhe da maleta entraram como imagens de referência no ImageGen. A base foi normalizada para a paleta da fachada e recebeu acabamento no Aseprite.

- [Quadro-chave transparente](quadro-chave.png) e [Aseprite editável](quadro-chave.aseprite).
- [Comparativo do concept, quadro-chave e interior atual do jogo](comparativo.png).
- [Convivência em 1× e 2×, em cor e em cinza](teste-convivencia.png).
- [Checklist de I1 a I10](checklist.md) e [verificação do PNG](verificacao.json).
- [Fonte selecionada e prompts usados](fontes/PROMPTS.md).

Para reproduzir a base e as pranchas a partir da raiz:

```powershell
godot --headless --path godot --script tools/laboratorio_v2_interior_base.gd
godot --path godot --script tools/laboratorio_v2_revisao.gd --rendering-method gl_compatibility -- --interior
```

O primeiro comando regenera a base anterior ao acabamento. O segundo lê a exportação final do Aseprite e gera as pranchas. A próxima etapa, após a aprovação, é cortar o kit modular.
