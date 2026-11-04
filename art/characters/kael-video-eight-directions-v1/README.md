# Kael — caminhada em oito direções por vídeo

Produção solicitada a partir do teste MiniMax de perfil direito.

## Contrato de entrega

- Direções: S, SO, O, NO, N, NE, E e SE.
- Oito poses extraídas por direção, 64 quadros, células64×96.
- Uma única escala, recorte e paleta de até32 cores para a biblioteca inteira; alpha0/255 e pivô32,94.
- PNG completo, folhas e projetos separados por direção e projeto único para Pixelgen.
- Vídeos de512×512 a24fps, MiniMax H3 local, sem créditos de API. O clipe E é reutilizado do primeiro teste.

## Origem e revisão

`referencias/prancha-original.png` é a geração de vistas orientada pela referência anterior de Kael. A ordem real dos perfis foi verificada visualmente: O veio na célula6 e E na célula2, contando desde0; a associação foi corrigida antes de produzir os vídeos. As referências foram isoladas e normalizadas para400px de altura numa área512×512 com fundo magenta.

`jobs.json` registra cada prompt_id, workflow, vídeo e tentativas rejeitadas. `workflows/` preserva os prompts exatos e seeds. As primeiras versões NO, N e NE foram rejeitadas por efeitos, figuras duplicadas ou cenário inventado. Foram refeitas com descrições diretas; uma tentativa intermediária N e a nova NE incluíram a pose de referência também em31,62 e93 frames. A N intermediária foi rejeitada por saltos; a final usa uma instrução curta de apoio alternado e apenas as âncoras inicial/final.

A seleção de ciclo compara poses próximas no início/fim e seus vizinhos. É uma candidata automática, não certificação de loop perfeito. Trechos com fundo contaminado nas bordas são recusados. Isso também impede que um fundo preto ou cenário entre no recorte e encolha o personagem na folha.

## Abrir

No Pixelgen local, use **Kael · vídeo ·8 direções**. O seletor Direção troca o ciclo; cada um mantém os tempos da seleção de frames. O arquivo `pacote/kael-eight.pixelgen.json` abre diretamente na bancada. As folhas separadas também usam a paleta e o pivô comuns.

`comparacao.gif` compara as oito direções em tempo comum de150ms por quadro; não sincroniza a fase de contato nem substitui a reprodução com os tempos individuais. Os vídeos originais e os quadros-fonte preservam a referência para retoques.

## Limites

É uma biblioteca de rascunhos extraídos de vídeo. Ainda pede revisão de volume da cabeça/tronco, detalhes do figurino, pixels soltos e contato dos pés na emenda. A redução/quantização não reconstrói automaticamente clusters desenhados. As imagens estão numa camada, sem falsa segmentação anatômica ou rig inferido. Não foram instaladas no jogo nem marcadas como arte aprovada.

## Reproduzir o processo

- `build-kael-video-directions.py`: prepara as referências e os workflows iniciais; não executar sobre a produção atual, pois recomeça o plano.
- `collect-kael-video-directions.py`: coleta somente os jobs deste lote no ComfyUI local.
- `pack-kael-video-directions.py`: seleciona os vídeos concluídos; com `--assemble`, exige todas as direções e monta a biblioteca.

Scripts ficam em `tools/pixelgen/examples/`. As seleções, timestamps e métricas estão em `selecoes/<direção>/selecao.json` e no manifesto da entrega.


Verificação final:64quadros distintos,8sequências,32cores opacas,alpha0/255 e recortes64×96. Folhas separadas recompõem exatamente a folha única. Aseprite nativo abriu os64frames e8tags e exportou pixels visíveis e alpha idênticos ao PNG/Pixelgen. Isso verifica formato e integridade; ainda não certifica anatomia, movimento ou integração no jogo. Arquivos .aseprite,.atlas.json e.tres estão em pacote/.

Os clipes integrais podem conter trechos não aproveitados com alteração do fundo. A folha usa somente os frames selecionados e recortados; os vídeos completos ficam como fonte, não como animação pronta do jogo.
