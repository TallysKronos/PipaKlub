# Usar o Soulmonsters Studio

Abra `http://127.0.0.1:5256/`. Execute `node tools/plant-lab/server.mjs` na raiz do repositório se o servidor estiver fechado. O editor é uma aplicação web local.

## Documento e segurança de edição

**Arquivo → Projetos e versões** abre os mapas nomeados. Crie um mapa com outro nome para manter composições separadas. O salvamento automático usa IndexedDB do navegador; a indicação inferior informa o estado. O histórico retém 20 versões por projeto. Escolher uma versão recupera o documento e arquiva o estado anterior. Baixe também JSON para cópias fora do navegador.

Nessa janela, **Dimensões do mapa** permite mudar largura e altura entre 8 e 64 tiles. Primeiro peça a prévia: ela informa quantos objetos e eventos sairão ao reduzir. Aplicar é desfeito com Ctrl Z.

**Foco por andar** escolhe uma cota e atenua o restante. O cadeado protege outros andares. Sem foco, a pincelada de piso continua presa à cota do clique inicial; solte e clique em outro andar para trocá-la. O olho/cadeado de cada camada controla visibilidade e edição, sem excluir conteúdo do projeto.

## Construir terreno

1. Escolha **Piso** e um material. A prévia acompanha curvas, cotas e cantos reais.
2. Em **Relevo**, escolha cota e ação: nivelar, subir ou baixar. O seletor de traço oferece pincel, redondo, linha, retângulo, elipse e laço.
3. Escolha **Paredes** para revestir a face vertical. Isso não muda o piso de cima nem o de baixo.
4. Em **Rampa**, escolha direção de subida, largura de 1–4 tiles e Rampa/Escada. A origem fica na cota baixa; o destino deve estar exatamente uma cota acima. A prévia explica suportes inválidos. Shift remove.

Linha, retângulo e elipse partem do primeiro clique e terminam ao soltar. No laço, arraste os pontos do contorno. Um gesto confirmado é um único desfazer.

## Água e cachoeiras

Pinte água e use **Região** para selecionar onde ajustar profundidade/correnteza em Terreno. A cor diferencia profundidades; os reflexos seguem o fluxo escolhido.

Em **Cachoeiras**, coloque uma queda independente na face entre água superior e inferior. Escolha fina, dupla ou ampla na biblioteca. A prévia inclui boca, queda e espuma recortadas pelo relevo.

**Traçar rio e poço** marca a nascente no primeiro clique e o destino no segundo. O destino fica ao sul, pelo menos quatro tiles distante, com espaço para fechar o poço. A prévia mostra a escavação antes de aplicar; Esc cancela. Uma aplicação pode ser desfeita inteira.

## Seleções e carimbos

**Região** seleciona células de terreno. **Copiar região** ou Ctrl C reúne piso, cotas, paredes, rampas/escadas, água, variantes e objetos. Ctrl V prepara a colagem. Escolha **Adaptar altura ao destino** para deslocar as cotas relativamente; desmarque para manter valores absolutos. Um carimbo que ultrapassa o mapa ou alcança andar protegido é recusado.

Dê um nome e use **Salvar carimbo**. **Meus carimbos** permite reutilizá-lo em outros projetos. Assets próprios usados pelos objetos acompanham o carimbo; IDs com conteúdo conflitante são recusados.

Na mesma seleção, **Distribuir vegetação** oferece grupo, densidade, semente e pesos por ID. Pré-visualizar não altera o documento. A mesma semente e configuração repetem o resultado; aplicar registra um desfazer. Cancelar descarta a proposta.

**Terreno → Variações de piso** distribui variantes A/B/C. Os pesos são três números, por exemplo `[4,1,1]`. `[0,0,1]` usa apenas C. Atua na seleção ou, sem seleção, nas células editáveis pelo foco. Os encaixes de borda continuam iguais entre variantes.

## Biblioteca e objetos

Use busca, biomas, favoritos e recentes para filtrar materiais. Um material escolhido ativa sua ferramenta. A biblioteca aceita clique e arraste para o mapa, incluindo assets importados.

**Arquivo → Importar sprites/atlas** aceita PNG. Defina tamanho de cada frame, quantidade, FPS e pivô. O pivô é o ponto onde a peça se apoia no mapa. A imagem deve dividir a grade sem sobras. A biblioteca salva o asset e o JSON leva sua fonte junto.

Selecione uma peça para mudar posição, espelhamento, camada ou colisão. Em **Colisão da base**, escolha círculo, retângulo ou polígono; configure tamanho e deslocamento. O polígono usa pontos locais como `[[-12,-8],[12,-8],[12,8],[-12,8]]`. **Mostrar colisões** revela a área bloqueadora. A copa pode ser grande e o tronco bloqueador pequeno.

## Eventos e testar

**Eventos** coloca spawn, saída, NPC, encontro, gatilho ou item. O formulário inclui texto, condição exigida, condição ativada, uso único, destino e rota. Rotas usam coordenadas em pixels: `[[160,240],[224,240]]`. NPCs percorrem esses pontos em laço no teste. O validador avisa se a rota atravessa desnível ou água.

Uma saída pode apontar para o nome ou ID de outro projeto salvo, com o ID do evento de chegada. No teste, aproxime Kael e pressione E. Condições e itens do teste ficam em memória; não mexem no save da campanha.

**Jogar** ou Tab alterna o teste. WASD/setas caminha; Shift corre; E interage. **Mapa → Testar no ponto apontado** começa na última superfície caminhável indicada pelo mouse. Kael tem caminhada frontal e traseira com espelhamento para os lados.

O minimap mostra posição, eventos e enquadramento. Clique nele para navegar. **Mapa → Validar mapa** lista problemas e centraliza ao clicar em um aviso. Áreas isoladas são avisos: podem ser ilhas intencionais com acesso por evento.

## Atalhos

| Ação | Tecla |
|---|---|
| Selecionar / mover / pincel / apagar | V / M / B / E |
| Piso / relevo / rampa / paredes | P / H / U / J |
| Preencher / conta-gotas | Q / I |
| Copiar / colar / duplicar | Ctrl C / Ctrl V / Ctrl D |
| Desfazer / refazer | Ctrl Z / Ctrl Shift Z |
| Salvar JSON / abrir JSON | Ctrl S / Ctrl O |
| Centralizar / grade | F / G |
| Câmera | Space + arraste ou botão do meio |
| Cancelar proposta | Esc |

Exportação e montagem em Godot: [INTEGRACAO-GODOT.md](INTEGRACAO-GODOT.md).
