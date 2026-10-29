# Pixelgen Studio 2

Bancada local de pixel art do Soulmonsters: referência → grade nativa → camadas → animação → revisão → exportação. Os projetos permanecem no navegador e nos arquivos que você baixar; o servidor não recebe imagens nem salva arquivos por você.

## Abrir

```sh
npm run studio:pixel
```

Acesse http://127.0.0.1:5264/. O terminal informa outra porta se necessário. Recarregue a página para receber a nova interface. Não precisa de build nem de novas dependências para usar a bancada.

## Projetos e recuperação

Em **Projetos**, crie um sprite vazio de 48×64, 32×32, 64×32 ou 64×64, guarde o projeto atual e abra projetos da biblioteca. A biblioteca usa IndexedDB neste navegador, incluindo camadas e imagem de origem. Guardar novamente atualiza o mesmo projeto; importar outro exemplo cria um projeto independente.

A gravação automática guarda o estado atual e o anterior em uma transação. **Recuperar gravação anterior** abre a cópia anterior; Desfazer permite voltar. Reabrir o autosave não sobrescreve imediatamente a cópia de recuperação. Projetos antigos v1 são migrados para v2 com seus pixels preservados; o autosave antigo não é apagado.

**Salvar projeto ↓ / Ctrl+S** baixa um arquivo portátil .pixelgen.json, com a fonte quando disponível. Limpar dados do navegador remove a biblioteca; guarde arquivos fora dele como backup. Falhas de quota ou indisponibilidade de armazenamento são exibidas; não são tratadas como gravação bem-sucedida.

## Camadas e edição

- Até 8 camadas indexadas: nome, visibilidade, bloqueio e ordem. O desenho e os deslocamentos afetam somente a camada ativa.
- B lápis, E borracha, I conta-gotas, G preenchimento, M seleção retangular. Botão direito apaga. A seleção restringe o lápis e o preenchimento.
- **Separar em camada** recorta a seleção mantendo o encaixe e a aparência. Pode agir só no quadro atual ou em todos. Não identifica anatomia automaticamente.
- As setas deslocam a seleção ou camada em pixels inteiros. Espelhar funciona na seleção ou na camada completa. Delete apaga a área selecionada; sem seleção, limpa a camada do quadro atual.
- **Copiar pose à sequência** replica o conteúdo da camada ativa para os quadros da sequência. Útil para reutilizar uma cabeça; as cels são cópias independentes, não cels vinculadas.
- Ctrl+A seleciona o quadro; Esc limpa a seleção. Ctrl+Z / Ctrl+Shift+Z desfazem/refazem. O histórico inclui documento e referência de origem, com limite de estados e memória.

Kael e professor têm exemplos de caminhada para a esquerda com cabeça e corpo em camadas separadas. Ambos usam quatro poses 48×64 e tempos 140/110/140/110 ms. Os exemplos ainda estão sujeitos à revisão artística; não substituem os personagens no jogo.

Também estão disponíveis **Kael · 8 direções e movimentos**, com seleção de direção/ação e filtro da timeline, e **Kael · subir escada · 4 quadros**, um estudo menor de costas em 64×80. A biblioteca de oito direções foi rejeitada na revisão artística do usuário por baixa legibilidade; permanece como estudo técnico editável. O estudo da escada permite revisar um único ciclo antes de ampliar o conjunto.

## Animação

A timeline permite duplicar, inserir quadros vazios, excluir e reordenar dentro da sequência selecionada. Nomes, intervalos, durações e modos normal, reverso e ping-pong são editáveis. **Aplicar ms à sequência** ajusta todos os seus quadros. A velocidade de prévia não modifica o arquivo exportado. Espaço no canvas inicia/para.

Onion skin mostra poses vizinhas em verde e violeta somente no editor; nunca é exportado. A leitura 1× ajuda a conferir o resultado no tamanho nativo. Uma folha de quatro direções estáticas não se transforma automaticamente em uma caminhada.

## Conversão e revisão

Importe PNG/JPEG/WebP, defina grade, recorte, resolução, paleta e limpeza. O processamento roda em worker. Cores dominantes ou nearest-neighbor; alinhamento de pés ou centro; alpha binário; remoção opcional de fundo conectado às bordas e de pequenas ilhas. A separação pressupõe células regulares: rascunhos gerados podem precisar de ajuste do recorte. Fundos complexos exigem uma fonte recortada adequadamente.

A revisão geométrica lista quadros vazios, pixels isolados, contato com bordas e variação do apoio vertical. O relatório JSON inclui contornos, contagem de pixels e duração real das sequências. Esses avisos não certificam anatomia ou movimento.

## Exportação

- PNG de quadro ou folha: resolução nativa, composição das camadas visíveis, paleta limitada e alpha 0/255.
- Aseprite indexado: camadas reais, visibilidade/bloqueio, cels, tempos e tags com modos de reprodução. Sem suavização ou rig inventado.
- Atlas JSON: recortes, pivôs em pixels, duração e sequências. A imagem é a composição visível.
- Godot .tres: recurso SpriteFrames para AnimatedSprite2D. Exporte também o PNG e coloque-o no caminho res:// indicado. Reverso/ping-pong são materializados na ordem dos quadros para manter compatibilidade. Use filtro Nearest; o pivô do atlas é uma orientação para configurar o nó, não uma propriedade inserida no SpriteFrames.
- Paleta GPL e relatório de qualidade JSON.

Limites: 16 MP / 32 MB por fonte; 1.048.576 pixels na grade; 4.194.304 pixels de cels; 8 camadas; 256 quadros; 256 entradas de paleta incluindo transparência. Projeto JSON até 64 MB. A conversão garante estrutura nativa editável; contornos, identidade e poses ainda precisam de trabalho artístico.

## Verificação

```sh
npm run studio:pixel:check
```

O comando verifica migração, camadas, recorte, composição, transformação, histórico, animação, exportação e fluxo DOM. O canvas do teste DOM é simulado: ele não comprova aparência no navegador.

Também foram executadas verificações independentes de IndexedDB com fake-indexeddb, importação/exportação real no Aseprite 1.3.18.6 e carregamento real do SpriteFrames no Godot 4.7.2. Evidências e limites em documentation/pixelgen/studio-v2/README.md. A inspeção interativa do navegador está indisponível pela configuração do Work.

## Skills e Aseprite

Foram instaladas as skills pixel-art, pixel-art-animator, pixel-art-professional e aseprite-ai-artist no Codex. O pacote @pebbly/aseprite-ai-artist 0.8.2 está em uma pasta local de ferramentas, com extensão instalada no Aseprite e MCP configurado para a instalação Steam. O diagnóstico MCP respondeu READY em modo headless. As ferramentas das skills de willibrandon e do pacote AI Artist têm APIs diferentes; consulte as ferramentas realmente expostas, sem pressupor nomes intercambiáveis.

A conexão é uma ferramenta do Codex; o Pixelgen não depende dela para abrir ou editar. A configuração e os pacotes locais não são enviados no Git. Consulte documentation/pixelgen/skill-installation.json para origens e versões. As skills ficam disponíveis no próximo turno; pode ser necessário reiniciar o Codex para carregar o novo servidor MCP.

Referências: especificação Aseprite em https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md e documentação SpriteFrames em https://docs.godotengine.org/en/stable/classes/class_spriteframes.html.
