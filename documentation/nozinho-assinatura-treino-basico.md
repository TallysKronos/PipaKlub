# Nó de Vendaval e ensinamentos básicos

Nozinho recebeu a assinatura Nó de Vendaval. Custo 35 de energia, recarga de 22 s, preparo de 1,65 s, dano-base de 32 na armação e área de impacto de raio 78. A engine valida custo, alcance e temporizadores. O alvo é marcado no início; fugir da marcação, esquivar ou usar guarda no impacto evita o golpe. O banner compartilhado usa a nova ilustração `assets/ui/signatures-v1/nozinho.png`; o efeito de impacto desenha um laço dourado e turquesa. As animações existentes de habilidade são reutilizadas durante o preparo e impacto.

O tutorial mantém os cinco checkpoints atuais e não altera o banco. Na etapa de energia, a instrução explica a recuperação automática ao soltar ataque, aponta a barra azul, permite continuar voando e pede esperar até 90%. O progresso aparece no diálogo, com instruções equivalentes para teclado, toque e controle.

A etapa de ferramentas ganhou uma demonstração segura da assinatura do Nozinho após a rebicada. O professor explica G/Guarda e o tempo de 0,5 s; o aviso “Guarda agora!” acompanha o fim do preparo. Para avançar é necessário bloquear de verdade: usa o mesmo contador de bloqueios e o mesmo resolvedor do combate. Tentativas repetem com recarga abreviada e proteção da armação somente nesse exercício, sem gravar desgaste. O diálogo distingue a recarga real da guarda, de 20 s.

Revisão manual: repetição do primeiro voo com Mata Verde, movimento, acerto no cruzamento, energia de 25% até a conclusão da meta de 90%, habilidade, esquiva, rebicada e demonstração real da assinatura. O bloqueio do Nó de Vendaval concluiu o exercício e liberou Avançar. O treino não concedeu recompensas nem substituiu a coleção. Encontrado e corrigido um identificador duplicado: o estado do diálogo agora usa `flightCoachStatus`, separado da nota da HUD `flightStatus`, para não esconder avisos ou erros de salvamento.

Não houve suíte automatizada nem publicação. Verificação técnica por builds e sintaxe; revisão visual do banner no componente real em 1131 × 884 e do treino em 1280 × 720. Evidências locais em `artifacts/nozinho-signature/`. A leitura visual do banner não comprova balanceamento nem controle físico.
