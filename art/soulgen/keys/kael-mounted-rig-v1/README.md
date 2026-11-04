# Kael montado — experimento arquivado

**Decisão do usuário: voltar aos sprites completos nos oito ângulos.**
A integração com mount_rig.gd foi retirada. Os arquivos abaixo são apenas
um registro do experimento; salvar este projeto não altera o Kael no jogo.
Para editar a versão em uso, abra http://127.0.0.1:5240/game-sprites.html.

## Registro do piloto SE

15 peças: quadril, tronco, cabeça, dois braços, dois antebraços, duas mãos,
duas coxas, duas canelas com botas e duas caudas do casaco.

Arte gerada por imagegen a partir da pose SE de
`godot/assets/mounts/doberman-c-v1/kael-rider-refined.png`.
O segundo passe trocou tampas ocas por abas de tecido para sobreposição.
Não houve referência externa de personagem nesta geração.

A saída real tem **1262 × 1246**, não uma grade uniforme. Os recortes são
medidos individualmente em `tools/soulgen-studio/build-kael-mounted.mjs`.
O script gera a montagem inicial, incorporando o atlas PNG. Não execute
o builder depois de ajustes no editor sem baixar uma cópia: ele restaura
a montagem inicial.

`kael-mounted.soulgen.json` é a semente de autoria. O arquivo experimental atualizado pelo editor é `godot/assets/mounts/kael-mounted-rig-v1/project.json`.

## Revisão

- Pivô do assento: [200, 325], espaço lógico 384 × 512.
- Pivôs de repouso no espaço global. O parentesco transmite a transformação
  da pose; a rotação de encaixe da imagem não gira novamente os filhos.
- Camada distante com z negativo passa atrás do corpo da montaria.
- Quadril preso ao assento durante a respiração; braços, mãos e caudas
  têm articulações independentes.
- Captura nativa: `documentation/qa/kael-mounted-rig-v1/mounted-se.png`.
- Piloto inicial, sem aprovação artística definitiva.
- As outras sete direções continuam usando a folha anterior. Ainda não há
  ciclo articulado de trote ou montar/desmontar.
- Botas e canelas são uma peça cada; pés independentes podem ser adicionados.

## Operação

Abra `http://127.0.0.1:5240/?preset=kael-mounted`. Selecione a peça para mover,
marcar pivô ou desenhar/apagar no editor de pintura existente. Grave poses
antes de exportar. **Salvar projeto** baixa uma cópia; **Salvar experimento · fora do jogo**
(Revisar e exportar) grava o projeto local com backup em `.local/soulgen-history/`.
O experimento não é carregado pelo jogo. Esta entrega não reexportou o executável.

Backend com destino fixo, validação dos PNGs e parentesco, recusa de revisões
desatualizadas e serialização de salvamentos. Recuperação do navegador
conserva a revisão de origem para proteger alterações de outra janela.

Transformações: [CanvasItem na documentação Godot](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-set-transform-matrix).
