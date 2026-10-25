# Revisão manual da jornada — 25/10/2026

Base: commit 15ac433. Build local atualizado, servidor em http://127.0.0.1:5262/, banco isolado `.local/journey-review-20261025`. Nenhuma migração ou publicação em produção. Sem suítes automatizadas. Referências usadas: router, game-ui-ux e contratos locais da engine JavaScript/Canvas.

## Conclusão

A demo ainda não pode ser declarada concluível do início ao fim nesta revisão. A confirmação do nascimento na Oficina foi bloqueada pelo limite de pedidos. O resto da exploração foi inspecionado com outra conta local e o atalho oficial de pós-tutorial; isso não substitui uma campanha contínua concluída.

## Percurso observado

- Kael Local: abertura da TV, diálogo de Kael, exploração do quarto, primeira vareta por arraste, presente da mãe, nascimento e nomeação do Rabbito, escada, cômodo inferior, saída para a rua, casa do professor.
- Treino completo: deslocamento, ataque no cruzamento, recuperação de energia, habilidade, esquiva, rebicada e corte final de Nozinho. Retorno por diálogo, quatro starters, escolha da rabiola de Carcará e entrada na Oficina.
- Oficina: quatro varetas, quatro nós (dois erros consumiram linha), recorte por quatro arrastes, etapa de voo e despertar. O servidor bloqueou o salvamento e a confirmação final.
- Ana Local, com atalho pós-tutorial: rua, mapa da cidade, menu de exploração, Jardim, Clareira, duas passagens até Veredas, introdução de Nina, rampa do mirante, baú com rabiola de Azulão, ponte, missão de Nina, encosta, pátio do Lacertubo, aviso de nível, abertura da batalha, pausa, retirada e retorno ao pátio.
- O aviso do boss informa parceiro nível 1 versus recomendado 15. Não foi validada vitória, equilíbrio em nível 15 ou conclusão da missão. Morro do Sol e encerramento da demo não foram percorridos nesta revisão.

## Correções prioritárias

### P0 — Oficina bloqueia a confirmação do nascimento

Tela observada: “Confirmando nascimento…” com “Muitas tentativas. Aguarde 15 minutos. Use Salvar novamente; seus comandos estão preservados.”

Causa identificada no código: `src/accounts.js` aplica 120 pedidos por jogador/IP em janela de 900000 ms a todas as ações de workshop-v3. `tools/oficina-v3/live-client.mjs` salva eventos a cada 3000 ms; `game.mjs` registra ticks contínuos enquanto a etapa está ativa. Aproximadamente seis minutos de atividade podem esgotar a janela, além das leituras e ações iniciais. A contagem continua aumentando a cada pedido recusado. O limite é compartilhado por read/save/start dessa montagem.

Recomendação: separar limites de criação e salvamento, adequar orçamento de checkpoints à frequência real, usar resposta de retomada com tempo correto e garantir que confirmação de uma montagem válida não seja bloqueada pelo próprio uso normal. Preservar idempotência, validação do replay e diário local. Não resolver desativando a proteção inteira.

Evidência: `art/ui-reviews/journey-20261025/workshop-rate-limit.png`.

### P1 — Diálogo do treino cobre os comandos de combate

Durante as lições ativas, o balão compacto do professor ocupa a mesma região inferior que as ações de combate e parte dos indicadores do parceiro. Foi possível avançar com clique no céu, atalhos e controles acessíveis, mas a apresentação visual esconde ações que o próprio texto manda usar. Revisar posicionamento reservado para a fala durante o jogo; no modo de explicação pausada pode continuar usando o painel grande.

### P1 — Sprite da Nina apresenta falhas de recorte

Na ponte, o sprite de Nina aparece fragmentado, com pontos transparentes/recortes atravessando cabelo e roupa, diferente de Kael. Observado em mais de uma posição da câmera. Conferir células, alpha e consumidor do novo atlas antes de editar a personagem.

Evidência: `art/ui-reviews/journey-20261025/veredas-quest.png`.

### P1 — Objetivo inicial e orientação entre áreas

No quarto, antes de terminar a primeira criação, a escada não é uma saída ativa; clicar nela diz que não dá para passar. A opção de dica mostra pontos no quarto, mas falta uma frase curta de objetivo que explique ir à mesa antes de sair. Após nascer Rabbito, a escada funciona.

Ao sair de casa não apareceu um objetivo persistente de procurar Sr. Assis. Na rua, precisei descobrir o destino pelas casas; o acesso ao parque pelo menu fica em Caderno → Jogar → Exploração e campanha → Parque. A saída leste da rua leva ao mapa da cidade. O minimapa progressivo ajuda a mapear o caminho percorrido, mas não orienta sozinho o primeiro destino. Reaproveitar a clareza do objetivo persistente já usado na missão de Nina.

## Polimento após os bloqueios

- Jardim e Clareira compartilham placa, bancos, caminhos e vegetação muito semelhantes. A Clareira precisa de marco e composição próprios para transmitir avanço. A documentação da primeira região já trata isso como próximo trabalho.
- Os quatro cards de starter exibem Ataque 1×, Voo 165 e Defesa 1×. As habilidades diferem e têm explicação do professor; os três medidores não ajudam a comparar. Evitar sugerir diferenças de atributos inexistentes; destacar diferenças reais ou balancear os dados com uma decisão separada.
- Baú do mirante passa a ter aparência de recolhido, mas a ação próxima continua “Abrir baú”. Exibir estado esgotado mais claramente.
- A faixa de ferramentas locais cobre a HUD superior e títulos em algumas telas. É interferência da ferramenta de revisão, não prova de defeito equivalente na produção. Criar modo recolhido para revisão visual fiel.
- Ainda falta medir o percurso de evolução do starter até o nível recomendado 15. Conseguir chegar com nível 1 é permitido e há aviso com opção de recuar; não é por si só um erro. A necessidade é garantir conteúdo e orientação suficientes para a preparação.

## Evidências e limites

Capturas em `art/ui-reviews/journey-20261025/`: starter-choice.png, tutorial-overlap.png, workshop-rate-limit.png, veredas-quest.png, guardian-battle.png. A imagem tutorial-overlap foi capturada durante a troca para o retorno da lição; a sobreposição das ações foi vista nas lições ativas e permanece descrita separadamente. A captura do boss tem a faixa local sobre a parte superior: não atribuir esse corte à HUD de produção.

Nenhuma correção de gameplay foi aplicada nesta revisão. Os ajustes locais anteriores do lobo e do Soulgen foram mantidos. Próxima sequência: resolver salvamento da Oficina; separar fala e comandos no treino; corrigir recorte de Nina; orientar tutorial e transições; então retomar a campanha interrompida e validar vitória/retorno/encerramento com o nível apropriado.
