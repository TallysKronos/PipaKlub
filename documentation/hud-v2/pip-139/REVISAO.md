# PIP-139 · Auditoria final e guia vivo

**Atualização após a revisão humana:** o dono informou que o teste encontrou muitos problemas e determinou reconstruir as telas no Figma. A aprovação visual não foi obtida. O plano de reconstrução está em [figma-rebuild/BRIEF.md](../figma-rebuild/BRIEF.md). Os achados individuais ainda não foram fornecidos; as métricas abaixo conservam seu alcance técnico e não são usadas para invalidar o relato.

**Parte técnica local pronta; aceite final pendente.** O [HUD-KIT v2](../../../HUD-KIT-v2.md) está disponível no repositório local para as telas futuras da campanha PIP-91. Não houve push, merge, comentário ou mudança de estado no Linear.

Código auditado: commit `149fa2fb`. Resumo verificável em [suites.json](suites.json).

## Escopo observado e critérios externos

A descrição real da [PIP-139](https://linear.app/pipaklub/issue/PIP-139/auditoria-final-da-hud-propria-e-hud-kit-v2-guia-vivo-para-as-telas), consultada em 02/11/2026, pede auditoria com `capture_campaign.gd --audit`, dez capturas sem logo avaliadas por alguém de fora, kit publicado no repositório e encerramento do épico antigo.

O conector Linear voltou a funcionar nesta etapa. O inventário retornou 17 subtarefas do PIP-61, duas Done e 15 abertas; não se assumiu que continuavam sendo apenas as 12 citadas no começo. Descrições completas e estados observados em [linear-inventory.json](linear-inventory.json). O [mapa de absorção](../ABSORCAO-PIP-61.md) indica destinos e escopos parciais. O épico não foi marcado como concluído.

## Auditoria nativa

37 estados × quatro resoluções × texto 100/150% = **296 PNGs**, gerados pelo consumidor real de campanha em processos nativos OpenGL. O runner usa dois lotes por resolução/escala para liberar memória, configurações temporárias isoladas e fixture de campanha em memória. Não lê nem grava a jornada do jogador. Não é um percurso conquistado de gameplay.

Estados: título/menu, jornadas, configurações, controles, quarto, rua, professor, prática, oficina, parque, trilha, clareira, cinco áreas do Morro, conversa do Morro, batalha de bairro, boss, batalha ativa, impacto, pausa de batalha, vitória, vitória sem foco de janela, derrota, equipe, bolsa, lobby, mapa, cuidado, Dex, evolução, emblemas, identidade, missões e Kronasta.

Matriz física: **1280×720, 1920×1080, 1024×768 e 1280×800**. O stretch da configuração real do projeto foi conservado; `PAPER_DONE` registra tanto o viewport físico como o lógico. A coleção de PNGs teve suas dimensões verificadas e SHA-256 registrados em [integridade.json](integridade.json).

Resultado final:

| Medição | Resultado |
| --- | --- |
| Imagens esperadas / conferidas | 296 / 296 |
| Observações de texto nativo | 2.312; sem alertas finais |
| Observações de glifos instrumentados | 2.136; sem vazamento da área segura |
| Exceções de script nos lotes finais | Nenhuma |
| Links locais do guia/README conferidos | 34, sem destinos ausentes |
| Novo teste do auditor | 4 checks, zero falhas |
| Novo teste de identidade, bolsa e controles | 80 checks, zero falhas |

As contagens são observações repetidas na matriz, não número de componentes únicos. A auditoria genérica cobre controles nativos; a instrumentação Paper cobre os consumidores que a usam. Textos desenhados manualmente, como parte da oficina e da lição, não viram automaticamente glifos instrumentados. Seus PNGs foram produzidos, mas zero controles detectados nesses casos não significa certificação automática do desenho.

## Correções realizadas na passagem final

- Cartões de equipe da identidade tinham só 4 px internos: passaram a 8 px.
- Em 150%, a identidade crescia além do painel. Agora possui escala própria aplicada uma vez, navegação lateral mais larga, conteúdo rolável por página e botão de retorno dentro da tela. Dados e histórico permanecem os mesmos.
- A mochila empurrava paginação e rodapé para fora em 720p com texto ampliado. O conteúdo agora tem scroll externo com `follow_focus`, rodapé que quebra em linhas e largura adequada para a ação de cuidar.
- O rótulo “Esquiva / corrida na exploração” não cabia na coluna de remapeamento. Agora pode quebrar em linhas, mantendo fonte e informação.
- O auditor confundia o retângulo inteiro de Labels com seus glifos e contava conteúdo invisível sob scroll como vazamento. Passou a medir linhas pintadas e recorte dos ancestrais. **Foco escondido pelo scroll continua sendo falha.** Os quatro testes novos comprovam tanto os falsos positivos corrigidos como a detecção de vazamento real/foco cortado.

A captura foi ampliada para lotes e para Dex, evolução, identidade, missões, emblemas e Kronasta, antes ausentes da lista. As retentativas foram restritas aos seis estados afetados, mantendo o restante da matriz e seus registros. Evidência anterior em `campaign-audit-before-recheck.json`; evidência final em `campaign-audit.json`, com `latestLog` e `recheckedShots`.

Os novos testes usam eventos de teclado injetados e foco programático; não são teste com controle físico. Verificam scroll até o alvo, botão de retorno, troca de página, texto comprido e preservação do snapshot. A PIP-138 conserva as provas de mouse/controle simulado e de contraste; não foram atribuídos novos testes físicos a esta etapa.

## Kit entregue

O guia contém decisão/dosagem, cores e fontes locais, propriedade de Theme, áreas seguras e cortes por família, componentes/consumidores reais, ícones salientes, foco e modal, tempos/movimento reduzido, buses e prioridade de sons, persistência, padrão de raiz, roteiro para tela nova, exemplos corretos/errados, comandos de revisão e limites de adoção.

`HUD-KIT.md` foi mantido como contrato do cliente web e ganhou um direcionamento explícito ao v2 Godot. Isso evita apagar a documentação de um consumidor ainda existente. O README do pacote de runtime também aponta ao guia novo. Não se renomeou o kit antigo como se toda a interface já estivesse migrada.

## Pendências de aceite — não ocultadas

| Critério | Estado |
| --- | --- |
| Auditoria técnica registrada e correções de layout verificadas | Concluído localmente no escopo descrito |
| HUD-KIT v2 disponível para revisão | Concluído localmente; sem push |
| Dez capturas sem logo | Preparadas em [teste-cego](teste-cego/index.html) |
| Resposta de pessoa externa ao projeto | **Pendente**; não substituída por avaliação do assistente |
| Adoção visual integral dos consumidores de compatibilidade | **Parcial**, conforme tabela abaixo |
| Encerramento do PIP-61 no Linear | **Não realizado**; não fechar sem resolver os escopos parciais e o aceite |

A identidade, mochila, configurações e controles ainda reutilizam partes de desenho/infraestrutura anteriores. A oficina e a lição também possuem apresentação própria. A inspeção não autoriza afirmar que todas essas telas já compartilham a matéria ilustrada do Mural. Os escopos funcionais das PIP-71, PIP-76 e PIP-77 foram marcados como absorção parcial no inventário, em vez de encerrados por semelhança de título. O critério antigo de proibir qualquer vazio no cenário também não foi reaplicado: o dono posteriormente pediu o diorama flutuante sobre fundo escuro.

Avisos locais conhecidos: acesso negado a `user://logs`/cache e uso legado de `Image.load_from_file` em props do professor/casa. Não são exceções de script na matriz, mas esta passagem não certifica exportação. Não houve avaliação por pessoas com deficiência, ensaio em TV/Switch, leitor de tela, medição formal de flashes de vídeo ou avaliação auditiva em diferentes equipamentos.

O próximo trabalho é revisar a resposta externa e decidir os destinos dos escopos parciais. A PIP-139 e o épico antigo não são declarados fechados por este relatório.
