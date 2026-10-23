# Quarto de Kael — arte ilustrada na grade do Iso Studio

A versão vetorial v3 serviu para validar geometria e foi rejeitada pelo usuário como acabamento de baixa fidelidade. A v4 usa novas ilustrações, produzidas com a ferramenta integrada `image_gen`, guiadas pelos volumes da v3 e pelo banco aprovado do parque (`assets/world/park-isometric-v1/bench.png`). Não usa a aparência vetorial como arte final.

## Entrega

- `sources/`: dez imagens originais geradas, preservadas sem sobrescrita.
- `quarto-kael.isostudio.json`: projeto com as nove peças e a casca incorporadas. Abrir pelo botão **Abrir** do Iso Studio; a ferramenta apresenta **9/9 peças aprovadas**.
- `conferencia.json`: auditoria geométrica dos PNGs finais e das pegadas.
- `assets/world/kael-bedroom-iso-v4/`: PNGs em escala nativa e manifesto do jogo.
- `scripts/prepare-bedroom-polished.mjs`: exportação reproduzível. Requer Sharp, localizado no pacote local ou no runtime fornecido pelo Codex.

## Direção

Madeira mel com veios e quinas gastas, pintura azul-petróleo, detalhes de latão, tecido creme e teal, contorno escuro e luz superior esquerda. Detalhes suficientes para parecer um objeto construído, sem perder a leitura no tamanho do jogo. O banco do parque é referência de acabamento, não um objeto a copiar para dentro do quarto.

## Geometria e normalização

As imagens geradas não foram aceitas diretamente: a primeira exportação apontou desvios de aresta. O processo recorta o alpha, reduz à resolução de entrega e registra verticalmente a envoltória de cada coluna à respectiva guia aprovada. Isso mantém as verticais retas e ajusta as bases ao volume de referência, sem alterar o posicionamento do móvel no jogo. Os vazios internos da arte são preservados. A transparência da exportação é binária, evitando halos. As fontes originais ficam disponíveis para revisão da transformação. Este registro é uma correção técnica de geometria, não uma declaração de que o gerador produziu ângulos exatos sozinho.

As guias editáveis e suas exportações ampliadas estão em `art/kael-bedroom-iso-v3/`. `scripts/build-bedroom-iso.mjs` recompõe as guias de cada peça. O projeto usa células de 64×32, unidade de altura de 32 px e cômodo de 10×8 células com paredes de cinco unidades.

## Conjunto de prompts

Cada pedido recebe duas referências: primeiro a guia ampliada da peça e depois o banco do parque. Pedido comum: editar a primeira imagem para um asset final de jogo 2D ilustrado; preservar silhueta, orientação, pegada, verticais e projeção dimétrica 2:1; usar a segunda apenas como referência de acabamento/material; madeira mel, teal e creme; volume, veios, bordas chanfradas, desgaste discreto, luz superior esquerda; evitar aparência vetorial, piso externo, sombras externas, textos, rótulos e cenário adicional; fundo transparente real.

Diretivas específicas usadas nos pedidos:

- **Cama:** quilt teal com faixas creme, tecido e costuras, travesseiro fofo, cabeceira e peseira teal com painéis, moldura mel e detalhes entalhados discretos. Silhueta e câmera da guia, sem novos objetos.
- **Guarda-roupa:** duas portas teal em moldura de madeira mel, painéis internos chanfrados, puxadores de latão, cornija discreta e veios nas laterais.
- **Mesa:** bancada jovem de construção de pipas, tampo mel com quinas usadas, painéis laterais e travessa inferior; papel creme com o desenho simples de uma pipa teal, sem ferramentas externas ao volume.
- **Estante:** móvel baixo com livros coloridos nas prateleiras e armário teal com puxador de latão. Sem televisão, que é uma peça independente.
- **TV:** CRT teal com céu e pipa na tela, botões e grade discreta de alto-falante, sem antena ou suporte fora do volume.
- **Janela:** paralelogramo da parede esquerda, verticais retas, moldura mel e teal, travessas creme, vidro azul com reflexo e relevo interno.
- **Casca:** quarto vazio com cantos e alturas exatos da guia; tábuas mel com variação discreta, paredes creme texturizadas, rodapé de madeira e faixa teal; oclusão ambiente no encontro parede/piso. Sem móveis, personagens, janela, tapete, escada ou adereços.
- **Tapete:** tecido teal com trama visível, borda creme/dourada, dois motivos bordados em losango de pipa substituindo os retângulos da guia; manter o contorno externo, sem franjas fora da pegada.
- **Escada:** apenas o vão e seus degraus descendentes em madeira mel, recessos escuros e quinas gastas; orientação da guia, sem plataforma elevada, corrimão ou piso externo.
- **Desenhos:** três folhas nas posições e no plano da parede direita, papel creme texturizado, fita e lápis teal; desenho de armação de pipa, estudo com orelhas e criatura de papel com orelhas longas. Sem texto legível.

As concessões de itens e os dados de conta não são alterados por este kit.
