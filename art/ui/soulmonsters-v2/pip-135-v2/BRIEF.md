# PIP-135 — Personalidade por função

O dono rejeitou a primeira montagem por estar chapada. Reaplicar a mesma superfície de papel a todas as funções não produziu a direção Mural. Esta revisão dá uma construção material própria a cada família, mantendo o traço 2D mangá e o parentesco com a prancha B de PIP-128 v2.

| Tela | Construção e gesto |
| --- | --- |
| Varal | Etiquetas de identificação presas em pregadores, seleção por marcador de tinta, parceiro maior num tecido tensionado por varetas; Linha e Armação são fios com nós |
| Pipa Dex | Caderno de campo com encadernação, abas e desenho de anotação; registros desconhecidos continuam fechados |
| Evolução | Folha de construção almática apoiada em varetas; diagrama nativo com os níveis reais do parceiro, sem inventar formas ou classes |
| Emblemas | Estojo de tecido índigo, costura e reforços; 12 posições numeradas, conquista real em destaque |
| Lobby | Ícones ilustrados saindo dos cartazes, texto em área segura, nome Tamer sem truncamento desnecessário |

O estudo `varal-estudo-material.png` explora composição. Sua materialidade mais realista não foi aplicada como fundo nem como redesign de Rabbito. Os PNGs de produção são peças vazias: nenhum nome, atributo, história ou comando está gravado neles. Retratos existentes e dados permanecem nativos.

## Produção e revisão

- Geração pela ferramenta de imagem, referência autoral `pip-128-v2/B-prancha.png`; prompts em prompts.md e correcoes.md.
- Fontes preservadas em fontes/. As versões `*-scalable.png` corrigem a posição dos objetos de borda: loops, fechos, nós e rabiolas não ficam no miolo que estica.
- build_mural_menu_art.py realiza somente corte pela caixa de alpha e redimensionamento uniforme. Não repinta os assets. manifest.json registra fontes, hashes, cortes e tamanho final.
- menu_art.gd define cortes de nove partes, densidade fixa por peça e margem interna independente da tipografia. O conteúdo usa o espaço posterior aos ornamentos, com 10 px adicionais.
- A interação dos botões continua sendo Button; etiquetas não viram hitboxes pintadas no fundo. Foco, clique, indisponibilidade e sinais permanecem nativos.
- A avaliação estética é interna e permanece aberta ao retorno do dono; nenhum estudo foi declarado aprovado por ele nesta revisão.
