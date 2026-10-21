# Soulmonsters — companheiros de overworld v1

Produzido em 21/10/2026 com image_gen integrado. Referência de identidade por espécie e acabamento/câmera de Kael registrados em `prompts.json`. A linha é o método de manifestação; a anatomia de pipa é preservada em velas, dobras, asas, cordas, nós e rabiolas.

## Cobertura deste lote

- Rabbito: parceiro da abertura.
- Carcará, Mata verde, Azulão e Raio de sol: quatro espécies básicas usadas pelos encontros do Morro do Sol e pelo jogo casual; Raio de sol também corresponde à recompensa do primeiro bairro.
- Nozinho: residente do professor e parceiro do treino da abertura; sua presença não concede posse ao jogador.
- Nevagume: compatibilidade adicional com coleções existentes. Não é anunciado aqui como recompensa disponível na campanha nova.

Essa cobertura descreve a abertura e o primeiro bairro. O catálogo histórico contém outras espécies de eventos e bairros posteriores; elas continuam com o renderizador anterior caso já estejam em uma conta. Este lote não cria eventos, recompensas ou permissões de aquisição.

## Contrato

Cada PNG tem 1536×1024, grade de quatro colunas por duas linhas e oito desenhos. O manifesto mede recortes, bounds e âncoras; a ordem lógica é Sul/Oeste/Leste/Norte. Rabbito foi gerado com Leste e Oeste trocados entre as colunas: o manifesto corrige a seleção sem espelhar ou editar a imagem.

Repouso usa um quadro por direção. Locomoção alterna a pose neutra e a pose de passo/vela a cada 200 ms. São ciclos curtos de duas poses, não animações de corrida completas. Escala é fixa por espécie; âncoras alinham cada recorte ao ponto no chão. O parceiro acompanha o histórico existente de movimento; sua direção vem do deslocamento dele, não da virada antecipada de Kael. A profundidade continua sendo ordenada pelo mapa.

PNG preservado sem alteração de pixels; `sources.json` contém a origem local, e `validation.json` registra hash e margens. O build copia os arquivos e calcula URLs com hash. O servidor permite somente os PNGs cadastrados. Os sprites de combate não foram substituídos.

## Reprodução da revisão

1. `python scripts/build-overworld-companions.py`: mede as folhas e refaz manifesto/relatório. Na ausência do arquivo de geração original, usa o PNG já preservado neste diretório.
2. `node scripts/preview-overworld-companions.mjs`: prévia local em `http://127.0.0.1:5228/art/overworld-companions-v1/index.html`, com escala normal/ampliada, quatro direções e caminhada em curva. Usa o renderizador de runtime, mas o percurso é ilustrativo e não testa colisões.
3. Após build: `node --test world-companions.test.mjs world-actors.test.mjs world-navigation.test.mjs art.test.mjs`.

## Estado

Integrado localmente, sujeito a revisão artística. A validação geométrica não comprova continuidade anatômica. Comparar especialmente variação de volume entre poses, pernas de apoio, caudas e leitura em tamanho pequeno. Não publicado no Render, não concedido a contas e não commitado por este trabalho.
