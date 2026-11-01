# Encosta dos Ventos — piloto independente

Implementação na branch `codex/encosta-mobilidade`, a partir de `68680247`.
Não concede recompensas, não grava saves e não substitui regiões existentes.

## Abrir e jogar

No Godot, abra `godot/project.godot`, abra a cena
`res://scenes/overworld_mobility_preview.tscn` e execute a cena atual (F6).
Também pode iniciar com:

```text
godot --path godot res://scenes/overworld_mobility_preview.tscn
```

- Setas/WASD, direcional/analógico ou clique: caminhar. Corrida usa a configuração existente.
- Nas setas azuis: E/Enter ou botão de interação do controle para saltar/descer.
  O nome do botão acompanha a família configurada do controle.
- Saltos são opcionais. Rampas permitem alcançar os dois lados e voltar andando.
- Durante a travessia, novos comandos não interrompem a animação nem geram outro salto.
- Esc: recuperação de diagnóstico para o último chão firme, com o parceiro.
- “Ver geometria”: troca a apresentação sem alterar relevo, colisões ou posição.

O piloto usa o Kael direcional atual, inclusive sua animação de salto existente. O parceiro
percorre as pegadas aceitas até a decolagem, aguarda sua vez e salta pela mesma rota.
Sombras usam o chão real sob a trajetória, não um piso fictício na altura do salto.
A recuperação em memória é um contrato para uma futura integração com saves; **não há
persistência entre execuções nem integração de checkpoint com a campanha neste piloto**.

## 1. Arquivos

- Brief: `art/overworld/briefs/encosta-dos-ventos-piloto.md`.
- Gerador: `tools/mapa-studio/desenhar-encosta-mobilidade.mjs`.
- Planta Tiled e compilado: `art/overworld/mapas/encosta-dos-ventos-piloto.tmj` e
  `godot/assets/overworld/maps/encosta-dos-ventos-piloto.json`.
- Cena: `godot/scenes/overworld_mobility_preview.tscn`.
- Comportamento isolado: `godot/scripts/overworld/mobility_{preview,traversal,marks}.gd`.
- Provas: `godot/tests/mobility_checks.gd`, `tools/mapa-studio/encosta-mobilidade.test.mjs`
  e `godot/tools/mobility_capture.gd`.

Reaproveita os kits de terrenos, mata e biruta existentes. Não altera assets de outras áreas,
renderer compartilhado, grafo de caminhada, regras de batalha, conta ou economia.
Permanece fora do seletor comum: aquele seletor instancia apenas o controlador de caminhada.

## 2. Resultado automático

Saída do gerador:

```text
Mapa conferido: entrada, acessos, rampas, pontes e trilhas. 429 células alcançáveis.
ZERO QUEBRA: platô 41,538%; 3 marcadores, 1 escondido; 24 células de rampa;
0 inalcançáveis; 0 degraus soltos; 0 árvores isoladas; 43 células de acesso; nenhum aviso.
OK: mapa independente, 3 cotas; 3 travessias opcionais; sem alterações de economia.
```

A conferência complementar existente é reutilizada. A exigência de uma região A/B/C é
explicitamente dispensada neste laboratório de uma área, conforme proposta aprovada.
As travessias especiais têm aterrissagens livres/largas, limite de distância, checagem de
obstáculos na trajetória, altura compatível e uma quebra real na caminhada normal.
Saltos de mesma cota são bidirecionais por duas ligações explícitas; descida aceita só -1 nível.

Validação:

| Teste | Resultado |
| --- | --- |
| `godot/tests/mobility_checks.gd` | 103 verificações, 0 falhas |
| `godot/tests/overworld_checks.gd` | 313.979 verificações, 0 falhas |
| `godot/tests/morro_map_checks.gd` | 9.386 verificações, 0 falhas |
| `node --test tools/mapa-studio/model.test.mjs` | 6 testes aprovados |
| `node --test tools/mapa-studio/encosta-mobilidade.test.mjs` | 2 testes aprovados |

O teste amplo `overworld_checks.gd` em modo headless também emitiu um diagnóstico do compilador
de shader em `_painted_floor` do renderer compartilhado, fora deste piloto e sem falha nas
asserções. A cena nova, seus testes e as capturas com OpenGL não emitiram erros de script/shader.
Esse diagnóstico do teste amplo não foi corrigido nesta entrega.

## 3. Capturas

55 PNGs nativos 1280×720 em `captures/`, gerados no Godot com OpenGL Compatibility.

- `geometria-geral.png` / `arte-geral.png`: área completa.
- `*-jogo-{chegada,salto,mirante,retorno}.png`: quatro câmeras naturais, zoom 1.
- `*-detalhe-rampa{1,2,3}-{pe,topo}.png`: seis bocas de rampa, zoom 2,2.
- `*-detalhe-canto-*.png`: dez enquadramentos dos encontros de barranco.
- `*-detalhe-salto-{oeste,leste}.png` e `*-detalhe-descida.png`: travessias e aterrissagens.
- `arte-diagnostico-*-sem-copas.png`: duas vistas adicionais do terreno texturizado sem
  copas de primeiro plano, para conferir canto externo e pé da rampa 3 sem obstrução.
- `movimento-{preparo,salto,pouso,parceiro}.png`: instantes da animação atual do Kael.
- `arte-jogavel.png`: câmera com personagens e comando contextual.

As 48 vistas de estrutura/arte não têm personagens sobre as juntas. As duas vistas sem
copas são diagnósticos, não representam remoção de árvores do mapa. Não há ponte, água,
mureta ou escada nesta área; as respectivas capturas não se aplicam. Sem antes/depois:
trata-se de um mapa novo.

## 4. Percurso

Controlador real acionado por teste determinístico a 60 passos/s: entrada → mirante de nível 2
→ platô leste → entrada → marcador escondido → entrada. Isso percorre as três rampas nos
dois sentidos. Exercitados salto/retorno/descida, parceiro atrasado, comando duplicado,
bloqueio de clique durante voo, cancelamento/retentativa e restauração de escala/animação.
Interação por evento de teclado E e de botão A simulados; direção usa o InputMap existente.
O teste também alterna geometria/arte preservando a posição.

## 5. Itens e história

Três marcadores de descoberta, um no desvio com mato, sem concessão de itens. Biruta marca
o mirante. Nenhum NPC, chefe, nome canônico novo ou revelação. O nome é de laboratório;
inserção na história e habilidades de tamer permanecem decisões futuras.

## 6. Pedidos ao integrador

Após avaliação do piloto: escolher quais regiões recebem travessias, relacionar acessos a
habilidades e adaptar o salvamento real para aceitar apenas checkpoints em chão firme.
O controlador é opt-in: mapas comuns continuam usando exclusivamente o grafo de caminhada.
Nenhuma dessas mudanças de campanha é feita implicitamente por abrir esta prévia.

## 7. Dúvidas

Nenhuma decisão pendente bloqueia a avaliação do piloto aprovado. Recomendação: avaliar
primeiro alcance, ritmo e legibilidade; depois expandir para outras mobilidades.

## 8. Não verificado

- Controle físico, Steam Deck, exportação Steam, máquinas diferentes ou acessibilidade completa.
- Teste manual contínuo por um jogador: percurso foi automatizado; imagens foram inspecionadas.
- Persistência ao fechar o processo, save da campanha, multiplayer, recompensas ou habilidades.
- Balanceamento final de distância/tempo: valores atuais são do piloto.
- Áudio/háptica exclusivos para salto: feedback atual é animação, arco, sombra e anel de pouso.

Relatório global gerado por teste e UID de ferramenta alheia foram retirados das alterações.
Sem merge, deploy ou push automático nesta tarefa.
