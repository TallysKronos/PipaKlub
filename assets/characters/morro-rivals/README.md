# Rivais do Morro do Sol — v1

Cinco artes de corpo inteiro com transparência: Zeca, Bia, Juninho, Lia e Tião. São recortes estáticos para apresentação e fala; não são spritesheets de animação.

O estilo de referência é a Mikka existente: desenho 2D, contorno quente e sombreamento em células. Cada rival tem silhueta e paleta próprias. A Mikka conserva seu atlas original.

O registro assets/rival-art.json liga nomes de personagens a arquivos. art-build adiciona a versão por hash, copia para a distribuição e para docs; static-assets publica somente arquivos cadastrados. O texto identifica o falante, então as imagens são decorativas para leitores de tela. Falhas no carregamento escondem somente a imagem.

As artes aparecem na apresentação do encontro e na reação após resultado confirmado. O terceiro encontro apresenta Juninho e Lia separadamente. As artes não mudam inventário, recompensas, desbloqueios ou a simulação da batalha.

Geração: ferramenta image_gen integrada, com fundo transparente solicitado. Prompts completos em prompts-v1.json. Originais preservados.
