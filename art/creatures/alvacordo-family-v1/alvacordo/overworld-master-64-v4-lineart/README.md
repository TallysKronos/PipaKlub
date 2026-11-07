# Alvacordo 64×64 — lineart definida

Edição do piloto v3 no Aseprite. Contorno externo em #080b10 aplicado pelo lado interno da silhueta com espessura de um pixel e vizinhança ortogonal; sem expansão do alpha ou alteração do canvas. A paleta remapeou o antigo escuro #14191d para esse preto mais profundo. Linhas internas seletivas sobre o desenho ficam na camada `lineart-interna`, que pode ser ocultada separadamente.

Focinho/gola, ombreiras, braçadeiras e sobreposições das placas receberam separações. Não houve contorno de cada mudança de sombra, nova geração, blur ou redimensionamento da arte nativa. Linhas foram desenhadas na grade e recortadas ao alpha já existente para preservar a silhueta.

- `alvacordo-master-64.aseprite`: fonte em duas camadas.
- `alvacordo-64.png`: pose transparente nativa.
- `preview-8x.png`: ampliação inteira transparente.
- `preview-fundo-claro-8x.png`: diagnóstico sobre cinza claro; não é asset de runtime.
- `a.png` / `b.png`: antes e depois para comparação; revisão preferiu b.
- `antes.aseprite`: snapshot preservado.
- `validacao.json`: dimensões, cores e igualdade de alpha.

Uma pose estática. Sem integração ou animação; aprovação do autor pendente.
