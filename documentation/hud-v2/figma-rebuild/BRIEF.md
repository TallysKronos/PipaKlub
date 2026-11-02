# Reconstrução das telas no Figma

## Origem e destino

O dono informou: **“Foi testado mas encontrou muitos problemas, vamos construir essas telas todas no figma”**. A avaliação humana foi realizada e relatou problemas; ainda não foram fornecidos os achados individuais. Os testes geométricos anteriores continuam sendo evidência técnica limitada, não aprovação de composição, navegação ou identidade visual.

Arquivo indicado pelo dono: [PipaKlub](https://www.figma.com/design/KCvJbbcDt9E35umMjjXHVz/PipaKlub?node-id=0-1). Chave `KCvJbbcDt9E35umMjjXHVz`; nó indicado `0:1`. Usar uma área/página isolada para a reconstrução, preservando o material existente. Antes de criar, inspecionar páginas, variáveis, fontes, componentes e bibliotecas acessíveis nesse arquivo.

Estado desta preparação: **nenhum frame criado**. O plugin consta como instalado, mas não expõe comandos Figma nesta conversa; no navegador o arquivo abriu como visitante. A conexão de edição precisa ser confirmada antes de registrar objetos como criados.

## Direção artística

Ponto de partida: **B — Mural de Kronasta, revisão ilustrada**, escolhida pelo dono. [Prancha aprovada como direção](../../../art/ui/soulmonsters-v2/pip-128-v2/B-prancha.png). Ela é referência de composição e matéria, não um screenshot para importar como tela acabada.

- Mangá 2D autoral; papel aplicado, contorno de tinta expressivo, vareta, presilha e linha com função na composição.
- O jogo e a ação são o foco. Ornamentos ficam nas bordas, sem atravessar texto, barras, atalhos ou retratos.
- Ícones ilustrados com presença e recuo reservado. O ícone pode sair do card; texto e hitbox continuam claros.
- Hierarquia distinta por função: seleção, boss, enroscada, resultado, informação e erro não recebem a mesma placa amarela.
- Não repetir a estrutura atual só para conservar o código. O inventário do jogo informa conteúdo e estados; o layout deve ser revisto visualmente.
- Não trocar a identidade por uma biblioteca genérica de aplicativo. Tokens e componentes Figma serão próprios do Soulmonsters.

## Organização proposta do arquivo

| Área | Conteúdo |
| --- | --- |
| Referências e achados | Direção B, capturas atuais e problemas relatados, separados de propostas |
| Fundações | Cores semânticas, tipos, escala, grid, safe areas, exemplos de leitura |
| Componentes | Papel/caps, opção, destino ilustrado, retrato, barra, glyph, alerta e navegação |
| Exploração e conversa | HUD, interação, objetivo, Kronasta, mapas, diálogo e escolhas |
| Combate | Lição, batalha comum, boss, VS, enroscada, especial, pausa e resultado |
| Lobby e consulta | Equipe/Varal, Dex, evolução, mochila, identidade, missões, emblemas e oficina |
| Sistema e momentos | Título, jornadas, configurações, controles, loading, item, emblema e nível |
| Protótipo e revisão | Caminhos clicáveis, variantes de conteúdo e provas responsivas |

Adaptar a quantidade de páginas ao plano e à organização já existentes; usar Sections quando apropriado. Estes nomes são proposta de organização, não páginas já criadas.

## Escopo de telas e estados

Os 37 estados da auditoria precisam estar representados por telas, instâncias ou variantes — não por 37 desenhos independentes do mesmo componente.

| Família | Estados atuais para cobrir |
| --- | --- |
| Entrada | `menu`, `slots` |
| Preferências | `settings`, `controls` |
| Exploração compartilhada | `bedroom`, `street`, `professor`, `park`, `trail`, `clearing`, `morro`, `morro-2`, `morro-3`, `morro-4`, `morro-5` |
| Orientação | `map`, `kronasta`, `missions` |
| Diálogo | `morro-dialog`, mais escolhas, fala longa e confirmação/cancelamento |
| Aprendizado e criação | `practice`, `workshop`, com estados de instrução, ação, erro e conclusão |
| Combate | `boss`, `live`, `impact`, `paused`, `morro-battle` |
| Resultado | `victory`, `victory-unfocused`, `defeat`, mais recuo e erro ao gravar |
| Consulta | `team`, `bag`, `pause`, `dex`, `evolution`, `emblems`, `identity` |
| Cuidado | `care`, incluindo contexto de entrada e retorno |
| Momentos complementares | Warning, VS, especial, enroscada, item, insígnia, nível e carregamento |

As cinco áreas do Morro compartilham a HUD; variantes usam seus dados e fundos para conferir legibilidade. Não duplicar toda a biblioteca para cada mapa. Não alterar regras, XP ou recompensas durante a criação das telas.

## Ordem de construção

1. Inspecionar o arquivo e reunir os problemas específicos do teste.
2. Estabelecer fundações e componentes mínimos editáveis.
3. Construir batalha e lobby como primeiras composições completas: densidade alta e consulta.
4. Construir identidade e mochila com dados longos e estados cheios/vazios.
5. Completar exploração, diálogo, mapas, aprendizado, oficina, cuidado e sistema sobre os componentes revisados.
6. Conectar os caminhos de uso e conferir cada família em contexto, inclusive retorno, erro e indisponível.

Não multiplicar a primeira composição para todas as telas antes de verificar seu resultado visual. A ordem não reduz o pedido de reconstruir todas as telas.

## Critérios de construção e revisão

- Textos, números, ícones e peças decorativas em camadas separadas; conteúdo variável editável.
- Componentes e instâncias; estados normal, foco, pressionado, indisponível, loading e erro onde aplicáveis.
- Auto Layout em grupos relacionados; Fill/Hug/Fixed decididos nos dois eixos. Posições absolutas apenas para sobreposições intencionais e arte.
- Safe area explícita depois dos caps; fonte não acompanha a escala da textura. Retrato ou ícone saliente tem espaço próprio.
- Tela-base 1280×720 e revisão em 1920×1080, 1024×768 e 1280×800. Escala de texto 100/150%; strings longas, números altos, coleção vazia e cheia.
- Mostrar navegação por teclado, controle e mouse no protótipo. Um print bonito não prova interação.
- Boss, enroscada e especiais com tratamentos próprios. Fundo claro/escuro e cenário real participam da revisão.
- Validar estrutura e screenshot do Figma antes de declarar uma composição pronta. Não converter uma tela inteira em imagem para simular editabilidade.
- A aprovação visual e de fluxo vem antes de adaptar novamente o Godot. Não manter a etiqueta de “aprovado” apenas porque o layout anterior passou em verificações automáticas.

## Insumos locais

- Referência B: `art/ui/soulmonsters-v2/pip-128-v2/B-prancha.png`.
- Capturas atuais: `documentation/hud-v2/pip-139/capturas/100/` e `150/`.
- Peças, ícones e eventos: `godot/assets/ui/mural-v1/`.
- Fontes e licenças: `godot/assets/campaign/ui-modern/fonts/`.
- Contratos técnicos existentes: `HUD-KIT-v2.md`, usados como referência de implementação, não como aprovação visual do redesenho.

## O que falta para iniciar a edição externa

Confirmar acesso de edição ao arquivo pelo conector Figma e executar a inspeção inicial. Os problemas individuais do teste foram solicitados ao dono para orientar a revisão. Não há criação de objetos ou publicação externa comprovada nesta preparação.
