# Laboratório de Batalha

Abra o project.godot com o Godot 4.7 e execute o projeto com F6 na cena
arena.tscn ou F5. Selecione o formato nos botões da arena.

Para validar no terminal, execute os comandos a partir desta pasta após a
importação dos assets.

    godot --headless --path . --import
    godot --headless --path . -- --test
    godot --path . --fixed-fps 60 --script playtest-no-impulso.gd
M ou View/Share alternam o formato. Enter ou Menu/Options reiniciam a luta.

| Ação | Teclado | Controle padrão Xbox |
| --- | --- | --- |
| Pilotar | WASD ou setas | Analógico esquerdo |
| Recolher / soltar | Z / C | RT / LT |
| Rebicar | R | RB |
| Cortar | Espaço | X |
| Guarda / esquiva | G / Shift | LB / B |
| Técnica | Q | Y |
| Curar o Soulmon que você controla | H | A |
| Tempestade Celestial | E | Direcional digital para cima |
| Alternar aliado / alvo | Tab / F | Clique no analógico esquerdo / direito |

A arena começa em 1×1 com Aeron contra Pyron. Os formatos de equipe usam aliados autônomos e troca
de piloto. Cada domador tem dois itens de cura na sessão de teste. Um corte
durante o preparo preserva o item e faz a tentativa esperar três segundos.
A cura concluída restaura até 25 pontos de Linha e usa recarga de 30 segundos.

O laboratório usa arte e física de corda reaproveitadas do PipaKlub. Os
dados e o balanceamento são experimentais. Não lê nem grava o progresso
da campanha. Ainda faltam ordens de equipe, os elementos Gelo e Rocha,
a tabela elemental completa e uma rodada de teste com controle físico.

## Laço de Vento

Contorne uma vez o ponto luminoso na linha do rival selecionado, mantendo uma
distância próxima à do anel guia. Os dois sentidos funcionam. Com o anel
dourado, use E (ou direcional digital para cima) dentro de 3 segundos.
O Laço usa 32 de energia, causa até 28 de dano à linha e reduz a mobilidade
do rival por 2 segundos se acertar. Compartilha o botão e a recarga com a
Tempestade Celestial. A guarda e o escudo de Flora envolvem a criatura e
seguem a posição dela enquanto ativos.

O corte aceita o comando até 0,18 s antes de um cruzamento válido e não
gasta energia se a janela não abrir. A Tempestade avisa quando o alvo está
fora do alcance e conserva a energia e a recarga. Guarda e impulso usam
uma recarga compartilhada. O aviso Corte rival indica uma tentativa inimiga
em preparação e dá tempo para defender ou sair do cruzamento.

Após acertar a Tempestade Celestial, procure o trecho roxo na linha rival.
Ele fica exposto por 3,5 segundos, aceita cruzamentos em uma faixa mais
ampla e aumenta o dano do corte. Para causar mais dano à linha, procure
cruzar com o indicador de tensão próximo de 65%.

Em Treinar Laço, use as mesmas teclas do duelo. Complete uma volta e
aperte E na primeira etapa com a linha parada e na segunda com a linha
em movimento. A barra no cartão de E mostra o tempo para confirmar.

## Nó de impulso

Com Shift e uma direção, atravesse a linha rival com o Soulmon. Quando
aparecer a marca azul, espere a recarga curta e use Shift para cruzar
de volta pelo mesmo trecho. A marca dourada indica o nó armado.
O próximo golpe do mesmo Soulmon contra esse alvo causa 65% a mais
de dano. O nó expira após 4 segundos e pode ser desfeito antes disso
se o rival impulsionar na direção oposta à sua passada de volta.

A faixa azul mostra a parte da linha que aceita a volta de Shift e
pulsa quando há recarga e energia disponíveis. A seta laranja junto ao
rival avisa o lado da fuga. A soltura exige deslocamento real do alvo
nessa direção. Aeron, Pyron, Raio e Azulão têm poses próprias de subida e mergulho.
