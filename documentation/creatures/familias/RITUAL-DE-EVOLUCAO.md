# Ritual de evolução no Godot

Na Equipe, abra o parceiro e escolha Evoluir. A seleção abre a confirmação do ramo com nível e estoque. A confirmação valida tudo novamente, prepara uma cópia do estado e grava a transformação e o consumo na mesma operação. O botão de pular avança para o resultado, inclusive após a gravação. Com movimento reduzido, o resultado é imediato.

## Cadastro de formas

Em `godot/assets/campaign/evolutions.json`, configure `from`, `level`, `bonus` e as ligações da família. Cada destino pode incluir `items` com `id`, `label`, `quantity` e `consume`. O consumo só ocorre quando `consume` é verdadeiro. Use `flags` para marcos booleanos da campanha e `flagLabels` para seus nomes na interface.

O campo opcional `signature` nomeia e habilita o ataque especial existente. A arte e as animações vêm de `content.combat`, sob o ID da forma. O empacotador preserva os requisitos e os nomes especiais configurados na tabela.

O Rabbito evolui para Rastro dos Ventos no nível 16 e usa um Papel de seda, material já disponível na campanha. O Rastro usa a arte aprovada disponível como retrato provisório e mantém o motor atual do ataque especial. A produção de um spritesheet direcional e de animações próprias de batalha continua separada.

## Arte do ritual

- `ritual-terraco.png` é o cenário 2D mangá em 16:9. O altar fica no eixo central e a iluminação do ritual é desenhada pelo Godot.
- `rastro-dos-ventos-idle.png` é a faixa de quatro poses transparentes, reproduzida a 6 fps após a revelação. A referência de forma e paleta foi o concept aprovado de Rastro dos Ventos.
- As duas imagens foram criadas com o gerador integrado de imagens do Codex. Os quadros do ritual são recortados no Godot por AtlasTexture.
