# Linha & Papel — loja e ponto de encontro

Pedido: ampliar a loja, dar linguagem de loja de TCG e acrescentar um novo NPC dono. Dono novo confirmado pelo usuário; Lia continua na rua, não é substituída. Sem nome pessoal/história novos: identificado pelo papel de Dono da loja.

O legado web tem interior 14×11; o Godot ainda não tem esse interior nem catálogo de compras. Construir 18×14 (+63,6% de área), com entrada real pelo prédio existente, retorno ao mesmo bairro e save/retomada. Não portar economia online ou inventar preços. O balcão recebe conversa do dono; mesas e mercadorias são ambientais, sem minigame de cartas nesta reforma.

```
FUNDO  estante       dono atrás do balcão       estante
                     vitrine + caixa
LATERAL janela           corredor               painel
        expositor        mesa com bancos        oficina/vitrine
        ilha de kits     corredor
                         mesa com bancos
                         entrada/saída
```

Planta: corredor central desde entrada em u7,v13.5; cliente do balcão em u8.5,v4.5. Mesas de convivência à direita, prateleiras no fundo, expositores à esquerda. Corredores livres de pelo menos 2 células onde a planta permitir. Mesas e bancos compartilham bloco de colisão; o dono tem apoio e profundidade próprios atrás do balcão. Todos os pontos decorativos/saída/atendimento acessíveis. Sem história de ruínas, itens novos ou recompensas.

Estilo: mesma família de interiores modernos 2D mangá, azul-marinho, creme, madeira clara; acentos coral/ciano. Estantes de kits/linhas/papéis, balcão de vidro, pastas e mostruários com motivos de pipas, mesas com playmats e bancos. A inspiração TCG é composição, exposição e espaço comunitário, não a cópia de produtos de outra franquia.

Fluxo: planta e geometria nativa → alcance e captura → bancada hero como referência → cinco objetos e dono chibi → alfa, manifesto e escala uniforme → capturas gerais, sem atores e detalhes ampliados → teste de entrada/saída/save/retomada em diretório isolado. Exterior e compras web preservados.
