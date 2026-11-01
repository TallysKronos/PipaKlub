# Aceite e auditoria

## Quatro resoluções

O dono exige quatro. As suítes locais consultadas têm principalmente 1280×720, 1920×1080 e 1024×768. Portanto não declare que já cumprem quatro.

Matriz inicial proposta para desktop/controle: **1280×720, 1920×1080, 1024×768 e 1280×800**. A quarta é uma proposta operacional 16:10, não uma exigência histórica já validada. Se o épico trouxer outra matriz explícita, use-a e registre a diferença. Mobile/Switch/TV física só entram como teste real quando executados; uma resolução não comprova um dispositivo.

Por tela e resolução, registre tamanho solicitado e obtido, captura nativa, margens mínimas medidas, colisões e cortes. Verifique tanto o conteúdo quanto ornamentos: contorno de foco, rabiola de seleção, retrato, tooltip e escala de texto. Baseie o respiro nos tokens existentes ou nos novos tokens escolhidos, sem inventar valores aprovados.

## Estados e inputs

| Família | Conferir |
| --- | --- |
| Texto/conteúdo | Nomes e descrições longos, números grandes, vazio/cheio, quebra de linha, corte consciente e rolagem |
| Estado | Selecionado, foco, hover, pressionado, indisponível, carregando, erro e retomada conforme a tela |
| Teclado | Foco inicial, Tab/Shift+Tab, setas, confirmar/voltar, Escape e restauração do foco |
| Controle | Navegação direcional, confirmar/voltar, prompts da família correta, troca de dispositivo e ausência de armadilhas |
| Mouse | Alvos, hover sem roubar seleção por acaso, clique fora, rolagem e coexistência com foco |
| Sobreposição | Nenhum movimento/golpe disparado por baixo do menu; pause e retorno preservados |

Diferencie controle simulado de controle físico. Não afirme teste de mouse/controle a partir de uma inspeção de código. Use fixtures isoladas e caminhos reais de navegação, sem tocar em save do jogador. Headless valida estado/contrato, não a leitura visual.

## Acessibilidade — PIP-138

- Contraste de texto e indicador sobre fundos reais claros/escuros; como alvo técnico, 4,5:1 para texto comum e 3:1 para texto grande e indicadores essenciais. Verifique com fontes primárias atuais se for declarar conformidade formal.
- Cor nunca é o único sinal: linha/armação, rival/aliado, seleção, recarga e enroscada têm forma, rótulo ou padrão complementar.
- Texto ampliado e movimento reduzido preservam informação e foco. Efeitos intensos não são necessários para reconhecer estados.
- Fala/transmissão e sons importantes têm alternativa visual; sons de UI não dependem de uma única frequência ou só estéreo.
- Mensagem de erro ajuda a recuperar; tooltip não é o único lugar com instrução essencial.

## Teste de identidade e término

Faça o teste sem logo descrito em identidade.md em cada família; registre onde a direção perde identidade ou prejudica o cenário. Confrontar contra uma referência bonita não substitui os testes de input, margens e estados.

Relatório por tarefa: arquivos, versão do commit, dados usados, tabela de resolução/input, capturas, falhas corrigidas e limitações. Não atribua à auditoria antiga aprovação da arte nova. A PIP-139 consolida `HUD-KIT-v2.md` apenas depois das telas e da auditoria: tokens, forma-assinatura, fontes/licenças, componentes/estados, contratos de input, comportamento, sons, exemplos e antiexemplos.

## Merge e épicos

Merge somente com autorização explícita do dono. A produção de um conceito ou commit local não autoriza merge. Após a escolha PIP-129, absorver/encerrar como substituídas as tarefas antigas somente conforme o inventário real e a autorização para alterar o Linear. Nunca marque ticket concluído com base apenas neste checklist.
