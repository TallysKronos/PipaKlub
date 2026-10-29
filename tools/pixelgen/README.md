# Pixelgen

Bancada local para transformar uma imagem ou folha de referências em quadros de pixels nativos, limpar a transparência, construir uma paleta compartilhada e retocar os pixels antes da exportação. Não altera o jogo nem chama serviços de IA.

## Abrir

Na raiz do projeto:

```sh
npm run studio:pixel
```

Acesse `http://127.0.0.1:5264/`. Se a porta estiver ocupada, o terminal informa a próxima disponível. O servidor atende somente ao próprio computador. Não precisa de build ou dependências adicionais.

## Fluxo

1. Importe PNG, JPEG ou WebP; ou use a folha de Kael e professor incluída como exemplo.
2. Defina colunas, linhas e, quando necessário, o recorte da fonte. A separação pressupõe uma grade regular: uma imagem gerada pode exigir ajuste do recorte para não atravessar os personagens.
3. Escolha resolução nativa, quantidade de cores e limpeza. O padrão é 48×64, até 32 cores opacas mais transparência. Os quadros da mesma linha compartilham a escala e podem alinhar os pés.
4. Converta. O processamento roda em um worker para não bloquear a bancada. Fundos uniformes podem ser removidos por preenchimento conectado às bordas; fundos ilustrados complexos exigem uma fonte com transparência ou preparação manual.
5. Use Comparar para conferir a identidade e Pixel para editar: B lápis, E borracha, I conta-gotas, G preenchimento; botão direito apaga. Ctrl+Z desfaz e Ctrl+Shift+Z refaz. As setas da bancada deslocam o quadro em um pixel. Editar uma cor da paleta atualiza todos os quadros. Onion skin mostra a pose anterior em verde e a próxima em violeta; essas camadas não são exportadas.
6. Salve o projeto e exporte. Reconverter substitui os pixels por uma nova conversão e pode ser desfeito. O histórico guarda até 20 estados dos pixels, paleta e parâmetros; não é um histórico das imagens importadas.

Na timeline, selecione uma sequência, ajuste seu nome, início, fim e loop em Editar e aplique. O campo ms controla a duração do quadro selecionado (20–2000 ms). Reproduzir usa essas durações; o controle de velocidade só altera a prévia. O botão ⧉ duplica o quadro e ajusta os intervalos das sequências. Projetos anteriores continuam abrindo; sem sequências cadastradas, cada linha vira uma sequência inicial. Uma folha com quatro direções estáticas não é um ciclo de caminhada.

Use **Professor · teste de caminhada** para abrir o primeiro ciclo `walk-left`: quatro poses, 48×64, 140/110/140/110 ms, loop de 500 ms. É uma proposta para revisão de movimento, ainda sem substituir os sprites no jogo.

## Formatos

- `.aseprite`: documento indexado de 8 bits, índice transparente 0, uma camada editável chamada Pixels, uma cel por quadro, durações individuais e tags com os intervalos das sequências. Não inventa camadas anatômicas.
- PNG: folha ou quadro na resolução nativa, RGBA com cores limitadas e alpha binário. O zoom da bancada não modifica a exportação.
- Atlas JSON v2: retângulos em pixels, pivôs locais em pixels, nomes, durações, paleta e sequências com intervalos e loop. É um formato simples do Pixelgen; não é um recurso Godot pronto nem um importador automático.
- GPL: paleta opaca compatível com editores de pixel art.
- `.pixelgen.json`: pixels indexados, paleta, nomes, parâmetros e fonte original incorporada quando disponível. A gravação automática no navegador guarda somente os pixels e parâmetros; use Salvar projeto para guardar também a fonte. Ao restaurar apenas o autosave, importe novamente a fonte para reconverter.

Limites: fonte até 16 megapixels / 32 MB; projeto até 1.048.576 pixels nativos e 256 entradas de paleta. Projetos JSON até 64 MB. A remoção de ilhas é opcional porque pode apagar detalhes legítimos.

## O que a conversão garante

Coordenadas inteiras, quadro nativo, índices de paleta e alpha 0/255. Não há suavização na visualização dos pixels nem na exportação. Isso garante uma estrutura editável de pixel art; não garante anatomia correta, contornos desenhados à mão, identidade perfeita ou continuidade entre poses. A referência e o editor estão disponíveis para essa revisão.

Não há upload: a imagem é processada no navegador. Projetos ficam no armazenamento local desse navegador ou nos arquivos que você escolher baixar. O servidor só entrega os arquivos da ferramenta e a imagem de exemplo.

## Verificação inicial — 28/10/2026

- Exemplo convertido em 8 quadros 48×64; folha 192×128; 32 cores opacas, alpha binário, sem quadros vazios ou pixels encostando na borda.
- Projeto serializado e reaberto sem alteração dos índices; limite de memória verificado.
- Arquivo Aseprite lido por um parser independente em Python: cabeçalho, oito frames/cels, camada, paleta e tags; todos os pixels e cores conferem com o projeto exportado.
- Inicialização DOM e operações de lápis, deslocamento, paleta e desfazer/refazer verificadas com canvas simulado. Isso não comprova renderização no navegador.
- Rotas estáticas conferidas diretamente no handler: arquivos entregues com MIME correto; arquivo fora da lista retorna 404 e POST retorna 405.
- Servidor iniciado e acesso HTTP real à página inicial confirmado com status 200.
- Inspeção visual no navegador indisponível porque o controle local de navegador está desabilitado no Work. Aseprite não foi encontrado nos caminhos de instalação consultados; a abertura no aplicativo ainda precisa de confirmação.

Artefatos do exemplo: `art/characters/rpg-overworld-study-v1/pixelgen-native-v1/`.

Atualização de animação: lógica DOM verificada com canvas simulado para onion skin, duração variável, término sem loop, duplicação, desfazer e ajuste dos intervalos. Parser independente conferiu tag `walk-left` de 0 a 3 e tempos 140/110/140/110 ms no Aseprite. Os quatro frames do GIF foram decodificados e comparados pixel a pixel com o projeto. Cabeça estável nos quatro quadros; 31 cores opacas usadas e alpha binário. Inspeção interativa do navegador continua bloqueada pela configuração do Work.

Escritor Aseprite implementado a partir da [especificação oficial do formato](https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md).
