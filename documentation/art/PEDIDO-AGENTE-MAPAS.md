# Pedido pronto para o agente de mapas

Copie o texto abaixo e substitua região, escopo e branch. Informe qualquer aprovação já dada para a região. O roteiro detalhado está em [Como construir mapas jogáveis a partir dos concepts](GUIA-PRODUCAO-MAPAS-GODOT.md).

```text
Use o agente construtor-de-mapas para produzir <REGIÃO> no Godot do PipaKlub.
Minha referência de conteúdo é o concept dessa região em art/overworld/conceitos/.
Leia o BRIEF.md, abra a vista geral e todos os recortes pertinentes e siga
documentation/art/GUIA-PRODUCAO-MAPAS-GODOT.md. Use as imagens do designer como
referência direta. Mantenha o estilo de pixel art do Kael e os elementos modernos
e tecnológicos que estiverem no concept.

Trabalhe em <BRANCH>. Atualize e confirme a base indicada para a região e confira
que tem acesso ao guia, à extensão de cenário e aos exemplos aprovados.
Use os arquivos de produção em godot/ para confirmar o consumidor e o espaço de
coordenadas. Preserve IDs, conexões existentes e progressão. Leia a bíblia do ato
antes de incluir itens, personagens ou pistas.

Escopo autorizado: <ficha e blockout | peça-teste após aprovação | kit completo
após aprovação | integração atribuída>. Primeiro quero a ficha com elementos
numerados, cotas, dimensões, mapa de rotas e planta separada por andar. Mostre a
transição entre andares, morros e patamares. Use vegetação, árvores, cipós e
trepadeiras onde o concept e a função das zonas pedirem. Para cada cipó, diga se
é decorativo, bloqueio ou acesso. Se o acesso depender de mecânica nova,
documente a dependência antes da integração.

Renderize o blockout no Godot com Kael em escala nativa. Entregue a comparação
anotada com o concept e a prova das junções, e aguarde minha aprovação da
estrutura. Quando a estrutura estiver aprovada, faça um prédio e dois props da
região com quadro-chave, checklist e teste de convivência 1× e 2×. Aguarde a
aprovação da peça-teste antes de produzir o kit inteiro. Na etapa de integração,
comprove circulação, oclusão, colisões, retorno e conexões pelo jogo.

Um commit em português por etapa na sua branch. Em cada portão, dê os caminhos,
as capturas, o que foi testado e o que ainda depende de revisão.
```
