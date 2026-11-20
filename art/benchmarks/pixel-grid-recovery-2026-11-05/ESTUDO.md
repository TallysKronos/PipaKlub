# Recuperação da grelha real em pixel art gerada

Leitura em05/11/2026 da sequência pública de nove posts de MagicPixel. Fonte principal: https://x.com/MagcPixel/status/2118362886359630086

O texto completo ficou acessível no navegador. Os links para ampliar as imagens abriram pedido de login; esta nota se baseia no texto, não numa inspeção integral das figuras. Não foi medido nenhum asset do projeto nesta etapa.

## O problema descrito

A saída de um gerador pode ser uma imagem grande que representa pixels menores por blocos ampliados. O tamanho pedido no prompt não garante o espaçamento efetivamente produzido. A thread relata um exemplo de imagem com512px: foram pedidos64blocos de8px, mas a saída tinha55blocos com passo aproximado9,31px. Ao amostrar com passo8, certos blocos são lidos duas vezes. O resultado pode ter contornos de espessura alternada, degraus irregulares e linhas/colunas repetidas.

Esse exemplo não é uma regra universal para todas as gerações. A possibilidade de recuperar uma grelha regular precisa ser verificada na imagem original.

## Método apresentado pelo autor

1. Medir as mudanças de cor entre colunas vizinhas, somando ao longo da altura. Interiores dos blocos tendem a variar menos; fronteiras produzem picos. Repetir a ideia para linhas.
2. Buscar o espaçamento periódico que se alinha aos picos. A analogia é um pente com dentes: espaçamento correto encaixa sucessivamente nas bordas. O autor relaciona essa busca à transformada de Fourier.
3. Recuperar uma cor por bloco, usando a região central e sua cor mais frequente. Evitar fronteiras suavizadas pela geração. Esse procedimento seleciona cores presentes, sem produzir misturas de interpolação.
4. Manter a resolução recuperada, com blocos consistentes, em vez de esticar a imagem para a contagem que o prompt havia solicitado.

Fontes específicas: bordas https://x.com/MagcPixel/status/2118362941107962228 ; periodicidade https://x.com/MagcPixel/status/2118362950264140051 ; amostragem central https://x.com/MagcPixel/status/2118362960641056959 ; resultado https://x.com/MagcPixel/status/2118362971659550945

## Interpretação técnica para o nosso pipeline

Estas são implicações propostas para Soulmonsters, além da explicação textual da thread:

- Separar resolução do arquivo, passo da grelha representada e tamanho final da célula. Uma imagem1024×1536 não contém necessariamente1024×1536 decisões de pixel art.
- Medir os passos horizontal e vertical e também o deslocamento/origem da grelha. Conhecer apenas o período não determina onde ficam os centros dos blocos.
- Um sinal de bordas horizontal pode ser escrito E_x(x)=soma_y distância(C(x,y),C(x−1,y)). O período dominante é candidato à largura dos blocos. Cor, alpha e ruído do fundo precisam de tratamento explícito; o método não deve detectar o fundo como se fosse o sprite.
- Harmônicos podem sugerir metade ou dobro do passo. Conferir o ajuste sobre bordas reais, nos dois eixos, e registrar uma confiança, em vez de escolher cegamente o maior pico.
- Nearest-neighbor evita mistura de cores, mas não resolve uma grelha de origem desconhecida. Quantizar a paleta também não restaura por si só os espaçamentos e clusters.
- Recuperar primeiro a grelha nativa. Só depois decidir se a arte cabe na célula por padding/ancoragem, ampliação inteira ou uma adaptação artística explícita de escala. Recuperação da grelha e escala física entre evoluções são decisões diferentes.
- Para animação, verificar a consistência da grelha entre frames e preservar uma escala/pivô comum. Não fazer auto-fit individual por pose. Se o vídeo inventar grelhas locais incompatíveis ou borrar os blocos, não existe garantia de uma reconstrução única correta; podem ser necessários redraws.

## Consequência para os trabalhos atuais

Nas versões já produzidas, a conversão usou tamanhos-alvo fixos64/192 antes de medir o período da grelha original. Isso pode contribuir para espessuras e ruído inconsistentes; não foi confirmado por medição nos assets. A próxima experiência pertinente é comparar o mesmo master gerado por dois processos: redução atual e recuperação de grelha medida, em tamanho nativo e ampliado.

Recuperar a grelha não corrige anatomia, arcos que mudam de forma, cordas interrompidas ou falhas de preenchimento sob peças deslocadas. Esses problemas têm causas diferentes e continuam exigindo revisão artística. As correções de junções aprovadas pelo usuário não são invalidadas por esta leitura.
