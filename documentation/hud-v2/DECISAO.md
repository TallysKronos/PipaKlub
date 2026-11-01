# PIP-129 — direção escolhida: Mural de Kronasta

Data: 01/11/2026. Branch: `codex/hud-identidade-soulmonsters`.

## Decisão e autoridade

Adotar **B — Mural de Kronasta, revisão ilustrada 2**, como direção dominante da HUD Soulmonsters.

O dono declarou nesta conversa: **«Olha eu gostei bastante da versão B»**. Essa preferência, somada à delegação anterior da escolha na PIP-129, fundamenta a adoção pelo assistente. Não se atribui ao dono aprovação técnica de telas, dados, margens, input ou implementação. Não há autorização de merge ou push decorrente da escolha.

Referência visual: [prancha B](../../art/ui/soulmonsters-v2/pip-128-v2/B-prancha.png). [Comparação das três direções](../../art/ui/soulmonsters-v2/pip-128-v2/index.html). A escolha se refere à **B ilustrada**, não aos painéis geométricos B da v1, que foram rejeitados.

## O que define a direção

Kronasta comunica-se por pintura de bairro, cartazes de campeonato e avisos de oficina. Essa matéria deve dar suporte às informações do jogador: peças ilustradas com contorno de tinta de espessura variável, bordas de papel aplicadas, sobreposições com sombra chapada e ícones desenhados para sua função. O traço continua 2D mangá autoral, coerente com os personagens aprovados.

A forma-assinatura será consolidada na PIP-130: placa impressa com chamada pintada, canto de papel aplicado e união de linha/presilha. Não basta colocar um filete colorido ou sujeira sobre um retângulo. O desenho precisa continuar reconhecível em título, botão, retrato, indicador e pequena interação.

Papéis de cor a preservar: tinta azul-petróleo, papel quente claro, amarelo-sol como foco/chamada; vermelho-terra e menta como acentos. Os valores hexadecimais e os pares de contraste finais ainda serão definidos e medidos na PIP-130, não extraídos como aprovação implícita dos pixels gerados.

## Comparação e concessões

Comparação de design baseada nas pranchas, não em testes com jogadores ou dispositivos:

| Critério | A — Seda viva | B — Mural de Kronasta | C — Carretel e Elo |
| --- | --- | --- | --- |
| Reconhecimento | Construção de pipa clara; risco de folio artesanal genérico | Relaciona bairro, oficina e campeonato, e recebeu a preferência do dono | Conexão entre elementos forte; risco de excesso de cordas |
| Leitura em ação | Superfícies claras calmas; pontas podem ocupar espaço | Tinta/papel e foco pintado separam informação; desgaste precisa ser contido | Etiquetas legíveis; fios podem competir com ações |
| Integração com cenários | Boa leveza sobre vegetação; exige contraste em céu claro | Suportes do bairro atravessam contextos sem mudar o mapa | Objetos de montagem presentes; bobinas não cabem em toda informação |
| Teclado, controle e mouse | Foco por rabiola é viável, não testado | Seleção por área pintada, contorno e marcador é viável, não testada | Nó/percurso exigem não atrasar a seleção; não testados |
| Escala | Varetas/nós fixos, centro expansível | Bordas/presilhas fixas, miolo quieto e texto nativo | Roteamento de fios aumenta trabalho entre proporções |
| Custo proposto | Médio: membranas, reforços e ícones | Médio: placas, cartazes, ícones e poucos acentos reutilizáveis | Maior risco de custo por tela devido a conexões específicas |

**Motivo da escolha:** B reúne a preferência expressa pelo dono e uma linguagem que representa a vida de Kronasta. Dá aos menus uma função no mundo, comporta o desenho mangá e permite reservar o maior impacto para campeonato e grandes acontecimentos. A concessão é disciplinar desgaste e sobreposições para não perder leitura ou transformar toda tela em anúncio de competição.

Não foi demonstrado reconhecimento por pessoas externas, acessibilidade ou diversão a partir dessas imagens. São hipóteses de qualidade a conferir durante a implementação.

## Preservar ao produzir

- Ícones ilustrados próprios, com silhueta, contorno e sombra de cor; não substituí-los por símbolos genéricos só para facilitar a montagem.
- Títulos com personalidade de impressão/pintura. Fonte local legível para valores e conteúdo variável; a tipografia será experimentada no sistema base.
- Seleção amarelo-sol com texto escuro, mudança de forma/contorno e marcador. Não depender apenas de cor ou animação.
- Papel e registros de tinta concentrados no suporte e nas bordas. Texto e números repousam em áreas tranquilas.
- Retratos e personagens no traço aprovado. A geração não redefine rosto, roupa, espécie ou pose canônica.
- Motivos de pipa, linha e amarração em lugares funcionais. A e C ficam como alternativas de pesquisa; não entram como outras duas gramáticas concorrentes.

## Regular a intensidade, mantendo o desenho

| Contexto | Aplicação da direção B |
| --- | --- |
| Exploração | Pequenas placas autorais para área, parceiro e interação; sem painel de madeira permanente ou vegetação decorativa nova. Centro do mundo livre. |
| Batalha | Ações como cartazes de campeonato; estado e números mais regulares. Fios, alvo e enroscada não podem ser cobertos pelos suportes. |
| Pausa e consulta | Mural completo como composição, destinos ilustrados e painel de leitura quieto; tamanho de conteúdo determina reflow/rolagem. |
| Diálogo | Faixa de papel aplicada com retrato autoral e fala limpa. Sem repetir a intensidade de quatro comandos de combate. |
| VS, vitória, item e emblema | Manchete, impressão e impacto maiores, após confirmação real do evento. O texto continua acessível sem efeitos. |

Reduzir ruído não significa voltar aos retângulos básicos rejeitados. A construção ilustrada e os ícones precisam sobreviver na variante compacta.

## Separar concept de implementação

A prancha gerada contém cenários redesenhados e omissões/variações em letras, dados e margens. Nenhuma dessas variações altera mapa, campanha, regras ou conteúdo aprovado. Não usar a prancha inteira como textura de interface.

Na PIP-130, produzir peças modulares: placa, faixas de título, cantos/papel, presilhas, foco, botões/estados, retratos, indicadores e família de ícones. Preparar Theme/tokens e validar como essas peças se repetem. Texto, valores e recursos permanecem nativos; não esticar nós, retratos ou rasgos ao mudar largura. Reutilizar a infraestrutura útil do PIP-61.

Quatro resoluções propostas: 1280×720, 1920×1080, 1024×768 e 1280×800. O tamanho mínimo do texto e o layout adaptativo ainda precisam ser resolvidos. Não herdar as medições da v1 para a arte B nova. Conferir teclado/controle/mouse e movimento reduzido em telas reais, antes de declarar aceite técnico.

## Relação com PIP-61 e próximo passo

A condição de escolha foi atendida. O trabalho novo segue B; o inventário das 12 tarefas antigas e sua absorção/encerramento permanece separado em [ABSORCAO-PIP-61.md](ABSORCAO-PIP-61.md). Nenhum ID, título ou status foi inventado e nada foi alterado no Linear.

**Próxima tarefa: PIP-130**, sistema base ilustrado de Mural de Kronasta. A PIP-131 aplicará o sistema à marca/título; depois as famílias de tela. A decisão não declara essas entregas prontas nem inicia merge.
