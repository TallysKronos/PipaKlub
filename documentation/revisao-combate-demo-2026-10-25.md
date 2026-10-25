# Revisão local do combate e da jornada

## Entrega

Escola com dez lições. As novas lições ensinam ataque na armação, guarda, assinatura e uma revanche de treino entre Rabbito nível 15 e Lacertubo. Usam a engine real; não concedem XP, parceiros ou vitória de campanha, nem gravam desgaste. A revanche pode ser repetida após vitória ou derrota.

O ataque comum segue a mesma regra para jogador e boss: perto, atinge a armação; longe, precisa de cruzamento e atinge a linha. Sobreposição sem ataque não causa dano. Alcance entre centros: 48 unidades para pipas normais e 66 quando uma delas é Lacertubo.

Lacertubo possui 250 pontos em cada reserva independente, linha e armação. Ataques comuns causam 18% do dano quando protegido e 120% durante a recuperação. Após resolver a assinatura, inclusive quando evitada, ele abre uma recuperação de 2,2 s. A assinatura do Rabbito segue sua regra própria e ignora essa redução dos ataques comuns. Estes valores são uma primeira calibração, não um balanceamento final aprovado.

A HUD do boss separa linha e armação. Os avisos distinguem proteção, abertura, preparação e momento do impacto da assinatura. Há feedback de dano corporal, proteção, guarda bem-sucedida e assinatura evitada. O especial do jogador informa quando falta um alvo ao alcance. Segurar Espaço durante o fim do combate não deve confirmar automaticamente o diálogo de resultado.

## Oficina e continuidade

O limite de requisições separa leitura, salvamento, início e cancelamento. O salvamento periódico não divide mais a mesma cota baixa de início de montagem. A etapa final também oferece dois cliques, firmar e soltar, submetendo os mesmos comandos e limiares da interação por pressão. A saída do tutorial não restaura o menu por cima do diálogo de conclusão. Nomes públicos vêm da Dex, preservando apelidos pessoais.

## Evidências manuais

- Ataque corporal: armação inimiga caiu para 79%, mantendo a linha em 100%.
- Guarda na lição: assinatura bloqueada com armação em 100%.
- Pulo do Elo na lição: armação inimiga caiu para 62%, mantendo a linha em 100%.
- Conta Kael local: nascimento confirmado pelo servidor, três estrelas e bônus de atributos de 6%; parceiro salvo e tutorial concluído. O nome antigo exibido nesse nascimento foi corrigido depois para o nome da Dex.
- Boss original com 190 e sem proteção: vitória fácil por pressão contínua. Versão intermediária com 300: derrotas observadas. Versão com 250: reposicionamento e guarda levaram o boss a 15 de linha, com 22% de linha e 100% de armação do jogador na última observação antes do encerramento. O resultado final dessa tentativa não ficou registrado de forma inequívoca; não conta como vitória comprovada da calibração final.

Capturas locais em `artifacts/combat-review/`: ataque corporal, guarda, assinatura, nascimento e comparação inicial. Não são conteúdo distribuído do jogo.

## Limites da revisão

Não foi executada suíte automatizada, conforme solicitado. Builds e sintaxe são verificados separadamente. O ciclo completo de campanha, da abertura à vitória final das Veredas, ainda precisa de uma passada contínua; esta revisão não certifica a demo inteira. Controle físico, latência externa e sons audíveis não foram homologados. A calibração final do boss ainda precisa de vitória e derrota registradas em sessões sem pausas frequentes.

As migrações 030 e 031 estão somente no banco local isolado. Não houve publicação desta revisão nem alteração do Supabase de produção.

## Continuação da revisão e candidato local

Base atualizada com os remakes até `f7d08be`. A sessão de revisão independente usa `localhost:5263`, banco `.local/demo-release-review-20261025`; a sessão do jogador continua em `127.0.0.1:5262`, banco `.local/journey-review-20261025`. O avanço do jogador não foi reiniciado.

Correções adicionais:

- Lacertubo permanece parado durante a contagem inicial. Antes, caía na IA comum durante a apresentação e se aproximava antes do início do duelo.
- O Canvas aceita foco programático. Fechar a pausa devolve o teclado à arena, evitando que Espaço e setas continuem acionando o antigo botão do menu.
- Retomar a pausa envia a confirmação ao servidor tanto nas Trilhas quanto em encontros selvagens. Antes, a retomada contemplava apenas Trilhas.
- O balão da lição do guardião foi deslocado para baixo da HUD superior.
- A investida comum tem aviso próprio a partir de 40% da preparação, separado do especial. A mensagem manda acompanhar o fechamento do círculo já desenhado sobre o boss; não implica invulnerabilidade durante toda a preparação. Vida, dano, recargas e tempos da engine foram preservados nesta continuação.

Na revanche com as regras reais, foi observado contra-ataque após esquiva perfeita, redução da linha do guardião até 27/250 e derrota explícita com linha do Rabbito em zero e armação em 53%. A captura de derrota está em `artifacts/combat-review/guardian-250-defeat.png`. Isso confirma dano, resposta defensiva e encerramento por linha, mas **não comprova vitória nem aprova a dificuldade final**.

O controle por navegador não reproduziu de modo confiável teclas mantidas. Foi criado um painel explícito de comandos locais, opt-in por `LOCAL_COMBAT_REVIEW=1`, exclusivo da revanche de prática. Ele mantém entradas de movimento/ataque, usa a movimentação e os custos normais e não concede progresso. Não integra o build público. Pausas e entradas assistidas limitam a conclusão sobre reflexos de um jogador com controle físico.

Builds Worker e Pages concluídos. Verificação sintática: 111 módulos de `src` e scripts selecionados, além do script embutido de `docs/index.html`, sem erros. Nenhuma suíte automatizada foi executada. A campanha contínua, vitória final do boss e ritmo real de evolução até o nível recomendado permanecem sem homologação; não apresentar este candidato como demo certificada do início ao fim.
