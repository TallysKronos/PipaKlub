# Feira do Largo — campanha local

## Comportamento

Entrar por Kronasta após vencer Kleie. Veyra 15 e Orven 16 na parte A; Zafri 16 e Nymel 17 em B; Dona Zulmira 18 em C. Quatro desafios em ordem, depois campeã. Defesa e reconquista reutilizam o contrato de bairros: perder o título exige nova qualificação, sem remover o emblema histórico.

Apito: comprar uma única vez de Seu Lalau em A por 20 moedas; experimentar no antigo pátio do guardião nas Veredas; retornar e vencer Lalau 16; receber as 20 moedas de volta e a indicação do beco; vencer Grampo/Platyx 17 em B; trocar o apito falso pelo verdadeiro, uma única cópia. Derrota ou fuga não avança a história e permite nova tentativa. O apito verdadeiro é requisito do duelo com Zulmira, mas não impede os quatro desafios. O descanso em B custa 12 moedas; equipe saudável não paga. Professor continua gratuito.

Item e resultado são guardados atomicamente no save local com recibos. Não há repetição de recompensa de história. Lalau usa Mata verde como parceiro provisório existente; a bíblia não define sua espécie. Esses dois duelos entregam desbloqueio de história, sem XP nem rabiola extra. Desafios do bairro usam o sistema normal de XP/moedas. Valores propostos, ainda sem balanceamento manual.

Faixas de mato fora do percurso pavimentado usam os dois rascunhos já existentes, níveis 15–17. Não foram criados Pombo de jornal, Gato de saco ou Papagaio nesta etapa; eles continuam pendentes de arte e contrato de espécie.

## Arquivos e validação

feira_story.gd concentra compra, porta, dois encontros e descanso; distritos.json define os duelos; gerador da Feira grava eventos; checkpoint, state, atlas, HUD, objetivos e frontend reconhecem as novas cenas/etapas. Novas propriedades são opcionais em saves antigos. Não foi necessária migração de banco.

Testes isolam os saves em diretórios próprios. feira_campaign_checks.gd testa sequência, preço, repetição, perda/fuga, suspensão/retomada, entrega, falha de gravação e desbloqueios. feira_flow_checks.gd percorre com controlador real, abre diálogos pelo frontend, compra/testa o apito, instancia os sete duelos e confere emblema e apito retido. As vitórias são forçadas para verificar fluxo/transações, não medem dificuldade. Capturas em documentation/qa/feira-v1/.

## Limites

Aparências dos seis moradores são propostas em revisão, poses estáticas. Barracas ainda usam o passe de geometria/cores; acabamento pintado posterior. A porta é apresentada por interação contextual no pátio existente, sem novo interior/portal explorável. Ao vencer a Feira, Cais e Caverna do Mural têm o desbloqueio registrado; como ainda não têm campanha construída, não são destinos falsamente liberados no atlas. Preservada a promoção Verde já realizada com Nina; não repetir o exame que a bíblia antiga colocava depois do Mural. Não há conversão Soulgen do Platyx nesta etapa. Sem certificação online, exportação, teste com controle físico, merge ou deploy.

## Resultados desta revisão

- Serviço da Feira: 78 verificações, zero falhas.
- Fluxo nativo 1280×720: 59 verificações, zero falhas; captura da recompensa revisada e corrigida para identificar Feira do Largo, sem o antigo texto fixo Bambuzal.
- Regressões: Beira-Canal 80; fluxo Beira-Canal sem janela 51; Bambuzal 143; campanha base 207; visual da campanha 25; regras de distritos 451; atlas 175; Morro 9.386; overworld 401.536; Node Mapa Studio 6 testes — todos sem falhas. O teste do atlas agora verifica que bairros com requisito ainda não cumprido recusam viagem sem mutar o save, em vez de presumir todos abertos.
- Algumas suítes antigas emitem avisos de recursos no encerramento. Importação mantém o aviso preexistente de safe-save; não se alteraram proteções.

Capturas revisadas: 01-praca, 02-mercado, 03-zulmira, 05-grampo-platyx e 06-emblema. Não houve revisão manual completa de dificuldade, nem inspeção individual de toda interação possível com controle físico.
