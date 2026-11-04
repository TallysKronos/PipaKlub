# Conferência zero quebra

Uma área só está pronta quando passa as quatro partes desta lista. Imprima o resultado automático no
gerador; registre o resto no relatório.

## 1. Automático (no gerador e no Mapa Studio)

| Checagem | Nível |
| --- | --- |
| `audit()` do Mapa Studio | zero ERRO; AVISO corrigido ou justificado |
| Entrada, saídas, NPCs, itens e gatilhos alcançáveis a partir da entrada | ERRO se não |
| Região com menos de 3 partes; parte sem ligação para a anterior/seguinte | ERRO |
| Parte com menos de 3 itens ou sem item escondido | AVISO |
| Área natural com menos de 40% em platô | AVISO |
| Rampa `u+` ou `v+` | ERRO (some na projeção) |
| Rampa sem pé de terra livre na cota baixa ou sem 2 células de chegada livre | ERRO |
| Célula elevada com menos de 2 vizinhas na mesma cota | ERRO |
| Bolsão caminhável inalcançável | ERRO |
| Corredor obrigatório com menos de 2 células de largura | ERRO |
| Árvore solta (sem vizinha a até 1 célula) acima de 2 por tela | AVISO |
| Copa grande até 2 fileiras atrás de chão caminhável | AVISO |
| Peça ou evento sobre boca de rampa, escada ou cabeceira de ponte | ERRO |
| Mureta ou muro cruzando acesso, ponte, porta ou saída | ERRO |
| Moldura com menos de 4 células, ou vazio visível na captura de jogo | AVISO |

As checagens de região, anti-chapado, rampa e mureta ainda não estão no Mapa Studio. Implemente-as no
gerador da área (ou proponha a inclusão no Mapa Studio) e imprima o resultado.

## 2. Capturas obrigatórias

Todas a 1280×720, cada uma em duas versões: **geométrica** (cores chapadas) e **com arte**.

- Área inteira (zoom ~0,36).
- Entrada, centro, cada platô e a saída, no zoom de jogo (1,0 na natureza).
- Detalhe ampliado (zoom ≥ 2), **sem personagem na junta**, de:
  - cada boca de rampa e de escada (pé e chegada);
  - cada canto interno e externo de barranco;
  - cada encontro de muretas e cada ponta de mureta;
  - cada cabeceira de ponte e trecho de margem;
  - cada poço ou cachoeira.
- Prancha antes/depois quando a área substitui outra.

Na geométrica você procura: rampa sem área visível, face faltando ou sobrando, parede atravessando
passagem, fenda em canto, degrau solto, borda de platô em ameia. Na com arte: textura esticada ou com
fase diferente entre faces, borda de grama interrompida, sombra de base faltando, copa tapando
caminho, peça flutuando ou enterrada, item escondido demais (invisível até para quem procura).

## 3. Percurso com o Kael

- Andar da entrada a cada saída, a cada item e NPC, subindo e descendo cada rampa e escada, nos dois
  sentidos.
- Parar sobre cada junta: pés e sombra no chão certo, seguidor acompanhando, oclusão correta atrás e
  na frente de platôs e copas.
- Clique em destino distante: o caminho não atravessa paredão nem mureta.
- Se só capturas estáticas foram feitas, diga isso no relatório.

## 4. Testes e repositório

- `godot/tests/overworld_checks.gd` e `godot/tests/morro_map_checks.gd` passando.
- `node --test tools/mapa-studio/model.test.mjs` passando.
- `git diff` limpo de artefatos de teste e de `kit.json` de áreas que você não tocou.

## Defeitos conhecidos do exemplo `kronasta-bosque-a`

Não repita; corrija se trabalhar nessa área:
- o topo dos platôs tem quase o mesmo tom do chão de baixo (falta separar as cotas pela luz);
- pedras em dupla empilhada parecem repetidas;
- um brilho quadrado aparece numa mancha de mato (máscara de mato com borda dura);
- a mata da moldura sul ainda cobre parte da trilha de entrada (só a transparência salva).

## Relatório de entrega

1. Arquivos criados e alterados.
2. Resultado automático (copie a saída do gerador).
3. Capturas: caminhos dos arquivos, geral, jogo, detalhes, geométrica.
4. Percurso: o que foi andado e o que não foi.
5. Itens, pistas e revelações colocados, conferidos com a bíblia.
6. Pedidos ao integrador (código fora do seu escopo).
7. Dúvidas para o dono, cada uma com a opção que você recomenda.
8. **O que não foi verificado.**
