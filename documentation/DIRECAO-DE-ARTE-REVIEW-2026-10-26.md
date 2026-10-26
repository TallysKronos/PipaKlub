# Revisão de direção de arte e design sênior — campanha Godot

Implementação posterior: [correções e itens ainda abertos](DIRECAO-DE-ARTE-CORRECOES-2026-10-26.md). O diagnóstico abaixo registra a situação antes dessas mudanças.

Data: 26/10/2026. Referência: HUD Recorte fornecida pelo usuário. Escopo: diagnóstico e plano de acabamento; esta revisão não altera a arte nem a implementação do jogo.

## Parecer

**A identidade está reconhecível, mas o conjunto ainda não está aprovado para apresentação comercial.** Papel claro, nanquim, recortes, pipas e rabiolas formam uma direção viável. O problema principal é a relação entre esses elementos: decoração grande, conteúdo pouco hierarquizado, telas com densidades muito diferentes e famílias de arte com acabamentos incompatíveis.

A migração preservou funcionalidades, mas ainda apresenta vários sistemas como formulários sobre um fundo comum. Um kit consistente precisa também de composições próprias para escolher um parceiro, conversar, explorar, lutar e receber uma recompensa. Repetir a mesma moldura não resolve essas diferenças.

Este é um julgamento de direção, não uma nota objetiva de qualidade. Funcionalidade aprovada no playtest anterior não equivale a aprovação artística. Nenhuma mudança de marca ou substituição da direção Recorte está autorizada por este parecer.

## Evidência e método

- Revisão comparativa de 24 estados em três pranchas e inspeção ampliada de 16 capturas, principalmente a 1270 × 710.
- Conferidas também quatro capturas do percurso com progresso conquistado: rua, professor, coleta nas Veredas e anúncio do boss. Elas ajudam a distinguir aparência de fixture de aparência durante o fluxo real.
- A matriz de sete resoluções do playtest anterior foi usada como contexto; não foi executada novamente nesta revisão. O novo trabalho é a avaliação visual e de composição, não outra declaração de 448 novos testes.
- Conferência do HTML Recorte e dos contratos de assets. O contraste ruim da oficina foi localizado também no consumidor: texto escuro `#143e48` desenhado diretamente sobre a ilustração.
- Não foram avaliados aqui áudio, sensação por controle físico ou continuidade de animação quadro a quadro. Uma imagem parada não aprova movimento, timing ou anatomia entre poses.

Pranchas: [menus e narrativa](art-review-images/contact-0.jpg), [mundo e pausa](art-review-images/contact-1.jpg), [coleção e combate](art-review-images/contact-2.jpg). Os contatos servem para comparação; leitura deve ser julgada nas imagens individuais.

## O que preservar

- **Veredas:** vegetação de formas amplas, contorno desenhado, canos como marco e caminhos de terra oferecem um alvo de linguagem ambiental mais claro que a rua inicial.
- **Retrato da mãe:** personagem proporcional fora da caixa, nome separado e área de fala legível. É uma composição aproveitável para os demais diálogos.
- **Pausa diagonal:** mantém o mundo reconhecível sob o véu e cria uma divisão funcional entre navegação e resumo.
- **Papel claro com texto escuro:** funciona para detalhe de item e seleção. Pode proporcionar descanso entre superfícies escuras.
- **Ícones de pipa, linha e rabiola:** vinculam a interface ao universo. Devem ganhar significado específico por item e ação.
- **Cantos fixos e ornamentos separados:** preservar a arquitetura modular. Corrigir composição não exige voltar a esticar cards inteiros.

## Achados priorizados

P1: impede leitura de informação necessária. P2: compromete compreensão, hierarquia ou coesão. P3: acabamento. As prioridades abaixo são desta revisão artística; não substituem os resultados funcionais anteriores.

| ID | Prioridade / tela | Evidência e efeito | Correção e critério de aceite |
| --- | --- | --- | --- |
| AD-01 | P1 — Rua/interação | “E · Entrar no ateliê” ocupa uma coluna de aproximadamente uma letra. O retângulo pode estar dentro da tela e ainda assim ser ilegível. Não foi capturado pelo detector anterior de cortes geométricos. | Dar largura mínima baseada em conteúdo ao prompt, limitar a duas linhas naturais e ocultar moldura vazia. Conferir o mesmo componente no professor. Aceite: frase reconhecível de relance, tecla separada, sem quebra no meio de palavras. |
| AD-02 | P1 — Oficina/vento | “Rajada” e o cronômetro escuros desaparecem sobre madeira e sombras. São instruções da ação em andamento. | Inserir suporte de valor estável, seta direcional e contraste independente do fundo. Aceite: direção e tempo legíveis em fundo claro/escuro, com CRT ligado e desligado; não depender de um ponto favorável da ilustração. |
| AD-03 | P2 — Material da HUD | Molduras cinza-azul com múltiplos filetes, pontas ciano e pequenos chanfros lembram placas rígidas. A referência pede recorte e nanquim; o efeito atual se aproxima de metal. | Simplificar filetes, usar sombra sólida deslocada e assimetria controlada de tinta. Ciano deixa de marcar todos os cantos. Aceite: componente reconhecível como papel/tinta sem precisar de uma pipa decorativa ao lado. |
| AD-04 | P2 — Sistema de cor | Na rua e na escolha inicial, vários botões coral simultâneos têm o mesmo peso. No parque, atalhos equivalentes aparecem escuros. | Definir papéis estáveis: neutro para atalhos, papel para seleção, ciano para jogador/foco, coral para ação principal ou rival conforme contexto, ouro para prêmio. Aceite: existe uma ação dominante por grupo, e o mesmo papel mantém aparência entre telas. |
| AD-05 | P2 — Combate/composição | Em 1270 × 710 a região ilustrada ocupa aproximadamente 41% da imagem; o rodapé mede perto de 200 px e as laterais exibem uma pipa grande. As criaturas ficam pequenas para a importância que têm. | Redistribuir espaço para o confronto; HUD em camada independente da arena; barra compacta de ações. Aumentar leitura dos parceiros pela composição/câmera, sem distorcer sprites. Aceite: criatura, alvo e estado prioritário percebidos antes da decoração. Não preencher ultrawide esticando a arena. |
| AD-06 | P2 — Combate/hierarquia | Linha, armação e energia têm pesos próximos. “Seu parceiro” não ajuda a identificar a criatura; a habilidade exclusiva F está apenas no texto inferior. | Dar protagonismo à condição decisiva, agrupar recursos, nome/nível reais e habilidade exclusiva com o mesmo sistema visual dos demais comandos. Aceite: em captura reduzida ainda se identifica quem luta, quem está em risco e qual ação está pronta. |
| AD-07 | P2 — Unidade ambiental | Rua ampla e plana, interiores isolados, Veredas pintadas e arena muito detalhada parecem etapas de produção diferentes. A oficina usa perspectiva frontal e iluminação dramática distinta. | Aprovar guia comum de contorno, detalhe, luz e escala; adaptar cada perspectiva à função sem exigir câmera idêntica. Priorizar rua e arena para se aproximarem da linguagem 2D de formas amplas das Veredas. Aceite: uma prancha das áreas parece pertencer ao mesmo jogo, preservando variação de bioma. |
| AD-08 | P2 — Decoração global | A mesma pipa coral grande aparece no menu, diálogo, oficina e batalha. Somada às pipas nos cards e cantos, compete com conteúdo e denuncia repetição de template. | Reservar o adorno grande para capa/transição; nos menus, variar por contexto; em combate, reduzir ou retirar do campo de atenção. Aceite: nenhum ornamento ganha mais peso que a criatura ou ação principal. |
| AD-09 | P2 — Escolha inicial | Quatro nomes em barras extensas não apresentam as criaturas nem apoiam uma escolha descrita como única. | Fazer seleção com prévia do parceiro ou silhueta, conforme a intenção narrativa, mais característica e habilidade reais; confirmação independente. Aceite: jogador explica a diferença entre opções antes de confirmar. Sem atributos inventados para preencher card. |
| AD-10 | P2 — Equipe | Cerca de dois membros visíveis em cards muito altos; o botão interno ocupa uma faixa enorme e as criaturas são pequenas. Em um monster tamer, a coleção deveria protagonizar a tela. | Lista compacta ou grade com detalhe do selecionado, retratos maiores e estado ativo explícito. Não mostrar vagas falsas. Aceite: comparar a equipe exige menos rolagem e o mon é mais marcante que a moldura. |
| AD-11 | P2 — Mochila | Ícones iguais para rabiolas distintas, imagem de detalhe simples ampliada e hierarquia fraca da seleção. Itens de missão se confundem com materiais comuns. | Criar família de ícones com silhueta e cor próprias; indicar selecionado sem depender só do foco; selo e contexto para item de missão. Aceite: distinguir objeto, quantidade e função sem abrir todos os itens. Escala nítida do ícone validada no tamanho real. |
| AD-12 | P2 — Recompensa | Faixa central e rodapé separam emoção e progressão. A criatura celebrando tem pouco destaque; o resultado parece um recibo de XP sob a arena. | Compor um bloco de resultado com pose real da criatura, título, progressão e itens próximos; manter continuar visível sem rolagem e sem obrigar esperar contagem. Aceite: vitória e derrota diferem por pose, forma e mensagem, além de cor. |
| AD-13 | P2 — Boss | A placa de metal, rebites e faixas de risco destoa das molduras de papel. O anúncio reaproveita o cenário ensolarado da vila, embora o encontro venha dos canos das Veredas. | Manter a ameaça com recorte rasgado, tinta coral e marca do boss; produzir variante de arena coerente com o lugar. Aceite: encontro parece especial dentro do mesmo universo, não uma interface de outro jogo. Não alterar a janela de combate apenas por apresentação. |
| AD-14 | P2 — Minimap | Terreno preto/papel em losango tem pouco parentesco com o mundo ilustrado e pode parecer uma máscara provisória. Só a seta está claramente explicada. | Simplificar caminhos e limites num desenho de mapa próprio, com descobertas e norte legíveis. Arte decorativa fica fora da área cartográfica. Aceite: localizar uma saída visível sem confundir vazio, bloqueio e área ainda desconhecida. |
| AD-15 | P2 — Configurações | O losango móvel e uma linha não comunicam com clareza os estados ligado/desligado em uma imagem parada; listas largas têm muita distância entre texto e estado. | Acrescentar texto de estado, agrupar rótulo e interruptor, manter foco distinto da seleção/ativação. Aceite: usuário diz quais opções estão ligadas sem clicar nem interpretar só a cor. |
| AD-16 | P2 — Diálogos/abertura | O botão “Avançar” ocupa quase toda a largura e tem mais presença que a fala. O fundo de menu e o adorno coral continuam muito ativos em cenas íntimas. | Preservar retrato/nome; usar indicador compacto de avanço, alvo acessível e atalhos equivalentes, com fundo de suporte mais discreto. Aceite: rosto e texto são os dois primeiros focos; avanço continua inequívoco. |
| AD-17 | P3 — Marca/menu | Menu anuncia PipaKlub, enquanto a direção atual é discutida como Soulmonsters. É uma decisão de produto pendente, não erro a corrigir automaticamente. Os três slots vazios repetem a mesma imagem e mensagem. | Confirmar relação entre marca/universo antes de produzir logo; diferenciar slot vazio e ocupado com informação útil. Aceite: título, campanha e nomes de sistema têm vocabulário consistente. |
| AD-18 | P3 — Tipografia | Famílias previstas existem, mas a fonte condensada e a escala do campo reduzem leitura em vários lugares. Retícula/CRT somam textura a texto pequeno. | Fixar estilos por função e escala de leitura independente; aplicar textura com menor intensidade na superfície de leitura. Aceite: texto longo não condensado, suporte estável e revisão em tamanho real, não apenas zoom de screenshot. |

## Diretriz visual proposta

**Recorte artesanal, desenho 2D e energia de aventura brasileira.** Nanquim define a silhueta; papel dá respiro; nós, varetas e rabiolas explicam estrutura. As diagonais conduzem o olhar, sem inclinar textos longos. A personalidade vem da composição e do traço, não da quantidade de enfeites.

Regras para a próxima implementação, como metas propostas:

1. Três níveis de leitura: ação/estado principal, contexto de apoio, informação secundária. Não dar a todos o mesmo tamanho ou cor.
2. Um único detalhe ilustrado dominante por composição de menu; combate privilegia criaturas e telegráficos.
3. Papel ou tinta planos nas superfícies de leitura. Textura discreta; borda fixa e sombra sem aspecto de bisel metálico.
4. Texto e ícones crescem por escala própria. Campo de jogo, moldura, retrato e ornamento mantêm transformações independentes.
5. Nove partes para painéis, três para faixas; cantos e pontas preservados. Testar curto, longo, vazio, cheio, foco, erro e desabilitado antes de propagar o componente.
6. Cor acompanhada por texto, forma ou ícone. “Pronto”, “selecionado” e “ligado” não são o mesmo estado.
7. Monstrinhos são o foco em escolha, equipe e resultado. Nenhum adorno genérico deve receber mais área e contraste que eles.

## Produção de assets necessária

| Família | Produzir / ajustar | Manter separado |
| --- | --- | --- |
| Molduras Recorte | Painel tinta, painel papel, faixa, aba, foco, desabilitado; mesma linguagem e cortes | Texto, ícones, área clicável e adornos |
| Rabiolas e materiais | Ícone distinto para cada objeto efetivamente existente; variação de missão Nina | Quantidade, nome, selo de missão |
| Combate | Ícones das ações reais, habilidade exclusiva e estados de prontidão/recarga | Custo, tecla, tempo restante |
| Boss | Marca do Lacertubo e faixa de perigo em papel/tinta; arena contextual das Veredas | Nome, nível, barras e regra de início |
| Coleção | Retratos a partir das artes aprovadas; recorte e proporção uniformes | Nome, condição, nível e progresso |
| Ambientes | Alvo comum de rua/arena/oficina apoiado nas formas e contornos das Veredas | Personagens, colisão, itens e prompts |

Não gerar toda essa lista de uma vez. Primeiro aprovar uma tela de combate e uma tela de equipe em tamanho real, com os assets dentro delas. Esses dois alvos resolvem a maior parte da linguagem de apresentação e coleção; depois produzir as famílias.

## Sequência recomendada

1. **Resgate da leitura:** AD-01 e AD-02, estados textuais dos interruptores e escala da HUD. Nenhuma nova geração necessária para corrigir os dois P1.
2. **Tela piloto de combate:** composição, hierarquia das barras, ação exclusiva e material Recorte. Usar o combate comum para não mascarar problemas com efeitos de boss.
3. **Tela piloto de equipe:** retratos, lista/detalhe, seleção e escala. Aprovar junto à escolha inicial e recompensa.
4. **Família de assets:** molduras, itens e marca do boss após aprovação dos pilotos; registrar fontes/prompts e recortes no manifesto.
5. **Coesão do mundo:** rua e arena antes de preencher espaços com decoração. Depois oficina e variantes de encontros.
6. **Aceite:** comparar pranchas, revisar em 1280 × 720, 1920 × 1080, 4:3, 16:10 e ultrawide; CRT ligado/desligado, textos longos e movimento reduzido. Repetir o percurso funcional só após alterações que afetem interação/layout.

**Critério de encerramento:** leitura prioritária inequívoca, criaturas protagonistas, identidade Recorte reconhecível em todas as famílias e nenhum P1 visual aberto. A revisão atual estabelece esse plano; não declara os achados corrigidos.
