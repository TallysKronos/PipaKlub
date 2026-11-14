# Laboratório v2 · Fachada final para aprovação

A fachada do blockout foi aprovada pelo dono. Esta etapa apresenta seu acabamento em pixel art antes do kit modular. O interior fica pendente de ampliação.

- [Quadro-chave PNG transparente](quadro-chave.png)
- [Fonte editável Aseprite](quadro-chave.aseprite)
- [Prévia nativa com Kael, Rabbito e Sr. Assis](convivencia-nativa.png)
- [Convivência 1×/2× e escala de cinza](teste-convivencia.png)
- [Comparativo concept / quadro-chave / captura legada](comparativo.png)
- [Checklist F1–F9 e limitações](checklist.md)
- [Verificação mecânica](verificacao.json)
- [Fontes e prompts integrais do ImageGen](fontes/PROMPTS.md)

## Reprodução

A partir da raiz do checkout, `godot --path godot --script tools/laboratorio_v2_revisao.gd --rendering-method gl_compatibility` recompõe as pranchas a partir do PNG final exportado pelo Aseprite. O script de normalização `laboratorio_v2_quadro.gd` gera somente a base anterior ao acabamento e nunca substitui o PNG final.

A verificação terminou com código 0. Avisos do ambiente restrito sobre cache/log do Godot não afetaram o render. A ferramenta Aseprite disponível não expõe a operação `validate`; foram executadas verificação de alpha/cores/pixels isolados, inspeção ampliada, prova de convivência e crítica independente. Não se declara uma validação de gameplay.

Parada: **aguardando aprovação do quadro-chave da fachada**.
