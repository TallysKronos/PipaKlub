# Linha, armação, guarda e reparos

Atualização: `revisao-combate-demo-2026-10-25.md` registra a revisão posterior jogando. O alcance atual é 48 unidades entre pipas comuns e 66 envolvendo Lacertubo. O ataque comum do boss também respeita a separação entre linha à distância e armação de perto; o texto de 36 unidades abaixo é o histórico da primeira entrega.

Implementação local da primeira parte do novo combate. A migração 031 foi aplicada somente ao banco local isolado. Sem publicação nesta entrega.

## Regras implementadas

- Cortes continuam reduzindo a linha e decidindo rodadas. O menor percentual da linha no encontro fica registrado como desgaste, inclusive quando a linha é reposta para uma nova rodada.
- Atualização a pedido do usuário: sobreposição só habilita o alvo. É necessário atacar (Espaço, botão Atacar ou comando equivalente) com o rival a até 36 unidades para causar dano à armação. Não há dano automático por contato nem exigência de velocidade. Vale o custo de 12 de energia e a recarga de 0,65 s do ataque normal. O mesmo golpe acerta somente um alvo: prioriza a pipa próxima; fora desse alcance, continua atingindo a linha cruzada. Ataques simultâneos podem ferir os dois; só um atacar não causa dano de retorno automático. Guarda e esquiva protegem o alvo. O golpe próprio do boss conserva sua regra corporal anterior.
- Armação chega a zero: encerra o duelo por quebra. Preserva o parceiro, inclusive no Vale pipa; não gera transferência por quebra.
- Guarda: G, botão da tela ou gatilho esquerdo do controle. Janela de 0,5 s, recarga de 20 s, sem gasto de energia. Bloqueia impactos físicos e golpes corporais do Lacertubo; não bloqueia cortes comuns na linha. Durante a guarda, reduz movimento e impede ataque, habilidade e rebicada.
- Armação persiste entre rodadas. Guarda não pode ser renovada mantendo o botão pressionado.
- Desgaste persiste na exploração e nas Trilhas; treinos e partidas casuais não gravam condição. Parceiro com linha ou armação em zero não inicia novo encontro persistente.
- Sr. Assis repara todas as pipas gratuitamente, fora de partidas ativas. Acesso por conversa ou Escola → Cuidar das minhas pipas. A orientação de pipa quebrada oferece coleção ou retorno ao professor, também quando não houver parceiro saudável.
- Níveis, XP, identidade e bônus são preservados no reparo. A condição acompanha a pipa se mudar de proprietário.

## Integração

`kite_conditions` guarda percentuais por pipa, sob RLS e acesso por funções. `server_kite_wear` aceita somente a função restrita do servidor, com recibo por partida/pipa e redução monotônica. A fila de progressão registra desgaste antes de liberar o encontro. Leituras e reparos usam a identidade autenticada; o cliente não envia percentuais.

Reparos são gratuitos e a localização do professor é conduzida pela interface. A função de reparo valida propriedade e ausência de partida ativa, mas não exige um checkpoint geográfico no banco.

## Verificação realizada

- Builds Worker e Pages e verificações de sintaxe dos arquivos alterados.
- Revisão no navegador local em 1131 × 884: barras separadas, botão de guarda com proteção e recarga, resultado, bloqueio de revanche, retorno ao professor e confirmação de reparo.
- Um duelo local com Zeca encerrou com linha 0% e armação 50%; o professor leu os mesmos percentuais salvos e confirmou o reparo.
- Não executada a suíte automatizada, conforme preferência do usuário. Não verificados controle físico, rede externa, produção, todos os parceiros quebrados simultaneamente ou balanceamento completo do boss.
- A revisão manual descrita acima ocorreu antes da troca da colisão automática pelo ataque próximo. Depois dessa troca foram executados apenas verificação de sintaxe e builds; o novo comportamento ainda depende de revisão jogando.

## Próxima etapa do combate

As habilidades atuais permanecem. Na entrega posterior `assinaturas-banner-v1.md`, Rabbito e Lacertubo receberam seus primeiros golpes de assinatura e banners próprios dentro do componente compartilhado. Os demais parceiros, as defesas da IA e uma rodada dedicada de balanceamento por nível ainda ficam pendentes, sobretudo o alvo de dificuldade do Lacertubo no nível 15. Os números acima são a configuração inicial, não um balanceamento aprovado.
