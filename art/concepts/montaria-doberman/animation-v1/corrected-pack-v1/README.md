# Kael e montaria — pacote de animações corrigidas v1

## Entrega

16 animações: caminhada e corrida em S, SW, W, NW, N, NE, E e SE.
Oito frames por animação, **128 PNGs RGBA** de 512 × 512, 16 folhas de
2048 × 1024, atlas com duração e ponto de apoio, GIF e MP4 de revisão.
`index.html` funciona offline e permite pausar, mudar velocidade e inspecionar
um frame nos ciclos. `package.json` indexa os arquivos finais.

Os 16 vídeos ComfyUI foram recolhidos com histórico. A caminhada sudeste
original foi rejeitada por mudar o zoom. A corrida de costas original foi
rejeitada por girar de trás para perfil. Esses arquivos foram preservados
como histórico, não aprovados para uso.

## Produção artística

As folhas `before.png` foram montadas de quadros dos vídeos locais, com um
recorte fixo por vista. A edição conjunta foi feita por **imagegen**, usando
somente o alvo e a composição editada do usuário da direção correspondente.
`generated.png` e `prompt.txt` conservam a saída e a instrução de cada passe.
Não houve referência externa ou repintura programática dos personagens.

O passe corrigiu leitura de orelhas, olhos, roupa, contornos, cores e membros.
As poses da corrida de costas foram **reconstruídas**, mantendo a vista
traseira fixa, porque o take não servia como sequência de poses nessa direção.
A caminhada frontal reaproveita a folha corrigida anteriormente em
`../correction-front-walk-v1/`.

Nem todo detalhe solicitado ao gerador ficou idêntico: caudas se sobrepõem em
algumas poses traseiras, há pequenas variações nas proporções e dobras entre
frames e a vista diagonal traseira precisa de revisão artística no mapa real.
A correção de imagem é uma nova ilustração por pose, não restauração exata
dos pixels do vídeo. Não declarar o resultado perfeito ou aprovado pelo usuário.

## Grade, escala e espelhamento

O gerador não respeitou perfeitamente a grade 4 × 2. Foram identificados oito
componentes conectados grandes por folha (`components.json`) e recortados sem
cortar a figura, em ordem de leitura. Cada frame foi colocado numa célula
512 × 512, usando uma escala fixa por sequência e o cabelo do Kael como
referência de tamanho/posição. O maior alcance inferior da sequência define
a linha de apoio. Não foi usado auto-fit diferente em cada frame, para não
inflar/encolher o personagem durante o ciclo.

Os valores reais estão nos atlas. Ponto de apoio da célula: [256, 480]. A
translação remove deriva da grade e fixa a referência superior; por isso o bob
do vídeo não foi preservado exatamente. Esta escolha deve ser revista junto
do movimento no jogo, não tratada como validação de biomecânica.

Pares derivados, sem nova geração:

- W ← E, caminhada e corrida.
- SE ← SW, caminhada e corrida. O SW estável foi a fonte excepcional deste lote.
- NW ← NE, caminhada e corrida.

Espelhamento horizontal **por célula**, mantendo a ordem e os tempos. O
pivô central [256, 480] não muda. As sequências são figuras completas com
Kael e montaria, sem peças articuladas ou máscaras de perna separadas.

Tempos de reprodução propostos: caminhada 150 ms/frame; corrida 100 ms/frame.
São cadências de prévia, não medição automática de um ciclo perfeito do vídeo.
Os oito idles anteriores foram apenas preparados como workflow e não foram
executados nem incluídos neste pacote de caminhada/corrida.

## Validação e estado

`validation.json`: **480 verificações**, sem falhas. Dimensões, oito frames,
alpha real, atlas exato e igualdade pixel a pixel dos pares espelhados.
As validações de margem constam no `validation.json` de cada animação.
O relatório registra diferenças entre frames e no fechamento do loop para
ajudar a revisão; esses números não provam naturalidade do movimento.

Inspeção visual das folhas e dos recortes normalizados concluída. GIFs e MP4s
estão prontos para revisão. A automação de navegador está desativada na sessão;
não foi alegada inspeção visual da galeria nem playtest desta arte no Godot.

**Estado: rascunho artístico para revisão, validado tecnicamente e não integrado.**
Os PNGs retocados no Soulgen, os encaixes e os sprites ativos do jogo não
foram substituídos. Este pacote não foi publicado nem enviado ao Git remoto.

## Reprodução

Da raiz do repositório, com `SOULGEN_CANVAS_MODULE` apontando para o pacote
Canvas local já instalado:

1. `node tools/soulgen-studio/package-mount-correction-pack.mjs`
2. `node tools/soulgen-studio/validate-mount-correction-pack.mjs`
3. `node tools/soulgen-studio/build-mount-correction-gallery.mjs`

O empacotador usa as saídas já geradas e a seleção em `manifest.json`;
não gera novas imagens nem executa ComfyUI.
