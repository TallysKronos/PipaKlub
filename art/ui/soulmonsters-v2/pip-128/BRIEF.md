# PIP-128 — três direções de HUD

Propostas locais de composição, 01/11/2026. Não são telas implementadas nem arte aprovada pelo dono. [Comparar](index.html) · [Nove mocks](comparativo.png) · [Dados](fixtures.json) · [Medições](auditoria-geometrica.json).

## Brief comum

Mostrar como o mundo do Soulmonsters pode estruturar informação, foco e consulta, com três matérias dominantes. O benchmark está em `art/benchmarks/hud-soulmonsters-v2/ANALISE.md`; suas imagens não foram usadas para gerar os mocks. Nenhum design de outra franquia foi inserido nas propostas.

Base: 1280×720. Mesmas cenas, atores, textos e valores nas três direções. Exploração no Bosque dos Ventos, batalha de estudo Rabbito/Lacertubo na arena das Veredas e pausa sobre a mesma exploração. A combinação da missão de exemplo com estes estados é uma fixture de comparação, não alteração da campanha ou afirmação sobre o estágio atual do jogador.

Dados: Rabbito Nv. 8, Linha 84%, Armação 96%, Energia 70%; Lacertubo Nv. 8, Linha 62%, Armação 78%; Kael Tamer Nv. 3; 42 segundos; 1.240 moedas; 0/12 emblemas. Oito destinos da pausa. A versão longa tem 93 caracteres. Os textos novos usam Soulmonsters conforme a bíblia; não introduzem lore secreto.

## Entregas por direção

- `exploracao.png`, `batalha.png`, `pausa.png`: os nove mocks principais.
- `texto_longo.png`: objetivo longo quebrado por largura medida na pausa.
- `componentes.png`, `componentes-cinza.png`: revisão da linguagem sem cenário, elenco ou logo; normal, selecionado, indisponível e pressionado propostos.
- Variantes dos três contextos em 1920×1080, 1024×768 e 1280×800. Escala uniforme com letterbox, não layout adaptativo Godot.
- `brief.md`: matéria, assinatura, paleta, tipografia, iconografia, foco, movimento e riscos específicos.

Os PNGs não serão usados como HUD gigante em produção. `render.mjs` mantém desenho, textos, dimensões e dados separados e editáveis. Nenhuma imagem nova foi gerada por modelo nesta tarefa; as composições e ícones são desenhados em Canvas, sobre assets existentes do projeto.

## Tipografia e ícones

Barlow Condensed Bold: títulos, destinos e chamadas. Nunito: descrição, valores e comandos. São os arquivos locais de `godot/assets/campaign/ui-modern/fonts/`, com OFL no mesmo diretório. Nenhuma fonte proprietária do benchmark foi usada. A rasterização dos mocks não substitui texto nativo no Godot.

Ícones próprios em paths: pipa, carretel, mochila, livro, emblema, localização, perfil, salvar, ajustes e ações. Rótulo acompanha ícone. Linha usa fio contínuo com ponta; Armação, segmentos diagonais; Energia, células. Nenhum estado depende apenas da cor.

## Layout e contrato de interação proposto

Exploração: área/objetivo no canto superior esquerdo; mapa no superior direito; parceiro embaixo à esquerda; interação perto do ator sem cobri-lo; acesso ao menu embaixo à direita. Energia fica fora da exploração por não ser decisão imediata da caminhada.

Batalha: atores e fios livres no centro; adversário no canto superior direito; tempo ao centro; estado próprio e ações junto à base. Destaque inicial em Cortar. Os quatro cartões demonstram categorias, não substituem a lista completa de ações existente. A HUD de boss, apresentação VS e enroscada serão aprofundadas na PIP-133, lendo o contrato real de combate. Estes mocks não acrescentam uma regra nova.

Pausa: destinos em duas colunas; parceiro, retrato, objetivo e local numa consulta lateral. Seleção inicial Soulmonsters. A ordem proposta usa setas/D-pad para vizinhos, confirmar/voltar pelas ações configuradas do jogo; Tab pode percorrer ordem linear. Mouse recebe hover sem apagar a seleção do controle; clique muda seleção e confirma. Escape/voltar fecha e restaura o foco de origem. Ao abrir, o overlay bloqueia comandos do cenário. Nada disso foi integrado ou testado nesta tarefa: é contrato para implementação. Z/X nos mocks são legendas demonstrativas; prompts devem vir de `controls.gd` e mudar com a família do dispositivo.

## Proveniência e reprodução

O contexto de exploração foi capturado do renderer Godot por `capture_context.gd`, com interface de revisão escondida e estado isolado, sem sessão de campanha ou escrita em save. Saída: `contexto/exploracao.png`. Arena, retrato e células de combate vêm dos caminhos em `fixtures.json`. As células de atlas foram enquadradas como sprites; não são novos desenhos de personagem.

Recriar o contexto, com o Godot local disponível:

```powershell
godot --path godot --script ../art/ui/soulmonsters-v2/pip-128/capture_context.gd --rendering-method gl_compatibility
```

Renderizar as composições a partir da raiz do repositório:

```powershell
node art/ui/soulmonsters-v2/pip-128/render.mjs
```

O renderizador requer `@napi-rs/canvas` (nesta sessão, 0.1.80 no cache de QA existente). Procura primeiro o pacote normal ou o caminho explícito em `HUD_CANVAS_MODULE`, depois o cache `tmp/soulgen-qa/node_modules/`. Não adiciona dependências ao runtime do jogo. A galeria abre offline sem dependências de Node ou servidor.

## Revisão interna e limites

Foram vistos os nove mocks na prancha comparativa e, em tamanho nativo, exemplos de exploração, batalha, pausa, texto longo e componentes em cinza. Ajustes: seleção B ganhou preenchimento inteiro e contraste próprio; C ganhou percurso de fio na pausa e bobina no tempo; glifo de vento ausente foi substituído por seta vetorial.

36 verificações calculadas: regiões principais dentro do viewport, margens e largura dos textos. Nenhum texto excedeu a largura declarada. A menor margem medida foi 25,6 px. Isso não detecta automaticamente toda colisão entre enfeites ou prova legibilidade por humanos.

**Limitação aberta:** em 1024×768, o letterbox reduz rótulos secundários a 9,6 px. O mínimo deverá crescer e o layout se reorganizar na implementação, em vez de aceitar esta escala como produção. Não houve teste de fontes ampliadas, dispositivo físico, mouse/controle/teclado no jogo, áudio ou movimento. A galeria não foi auditada visualmente em navegador nesta entrega.

Teste sem logo: todas as telas já omitem logo/nome do jogo. As pranchas isoladas retiram também atores/cenário. A oferece construção leve; B precisa preservar os registros de tinta para não virar cartaz comum; C precisa preservar o percurso para não virar painel tecnológico. Isto é crítica interna, não reconhecimento validado com jogadores. Não há vencedora declarada; a PIP-129 compara os ganhos e custos antes do sistema base.

Sem alterações em código do jogo, Theme, regras, quests ou saves; sem merge, push ou atualização no Linear.
