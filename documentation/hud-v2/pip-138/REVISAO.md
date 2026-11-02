# PIP-138 · Acessibilidade do Mural

Implementação local. Sem push, merge ou alteração de status no Linear. Esta é uma auditoria de leitura, input e apresentação da interface, não uma certificação de acessibilidade completa do jogo.

Código auditado: commit `eb86b4c2`. Resumo das execuções em `suites.json`.

## Correções

1. **150% utilizável e persistido.** A interface era testada nessa escala, mas a preferência só oferecia até 130% e descartava 150% ao carregar. Agora as quatro opções compartilham `Preferences.TEXT_SCALES`. A escolha real na tela foi gravada e recarregada em configuração isolada.
2. **Configurações sem truncar as opções importantes.** Seções em duas colunas nas larguras menores; larguras de tabs e seletores acompanham a escala. “Acessibilidade” e “Máximo · 150%” aparecem por inteiro. Rodapé pode quebrar em linhas. A área central continua rolável verticalmente, com foco acompanhado pelo scroll.
3. **Foco com forma.** As opções de diálogo, tabs e ações que usam `dialogue_option.gd` recebem um ponteiro estático na margem interna, além da mudança de cor. O texto não se desloca. Labels de opções desativadas usam tinta opaca, sem depender de transparência para informar indisponibilidade. As etiquetas do Varal já possuíam marcador próprio, preservado.
4. **Movimento reduzido preserva a informação.** Números de dano duravam apenas 80 ms nesse modo. Agora ficam estáticos por até 800 ms, com fade nos últimos 200 ms; sem gotas ou deslocamento. A onomatopeia fica menor nesse modo. O tempo e os efeitos do modo normal permanecem iguais.
5. **Contraste do boss.** O vermelho da arte de warning dava cerca de 3,50:1 para a tinta clara no trecho amostrado, insuficiente para o texto pequeno conforme a meta interna. O título, nome e subtítulo agora têm uma base nativa de tinta recortada, com 17,05:1 para o par sólido usado. A arte vermelha continua nas laterais e a silhueta do evento permanece distinta.
6. **Boss e VS ampliados.** Ambas as apresentações passam a receber a escala de texto do consumidor real de batalha. Os layouts reservam mais altura para os textos; o botão de pular usa texto nativo, cresce e fica a 24 px da borda inferior. A apresentação possui o próprio tema para evitar aplicar a escala duas vezes.

Nenhuma mudança em XP, combate, recompensas, quests ou formato de save. Preferências continuam separadas da campanha.

## Evidência atual

| Suíte | Checks | Falhas |
| --- | ---: | ---: |
| mural_accessibility_checks | 295 | 0 |
| mural_dialogue_checks | 292 | 0 |
| mural_menu_checks | 683 | 0 |
| mural_battle_checks | 795 | 0 |
| controls_checks | 44 | 0 |
| boss_presentation_checks | 67 | 0 |
| **Total funcional, sem contar execuções repetidas** | **2.176** | **0** |

A suíte nova foi executada em headless e em renderização nativa. Os testes de controle usam eventos injetados; não houve teste com controle físico. A suíte de controles antiga gravava em `user://`, indisponível neste ambiente, e inicialmente falhou em duas verificações de persistência. Foi ajustada para uma pasta temporária isolada e passou novamente, mantendo as mesmas verificações.

40 capturas nativas em 1280×720, 1920×1080, 1024×768 e 1280×800, com texto 100/150%: configurações no topo/rodapé, diálogo com foco, aviso do Lacertubo e VS. As capturas de apresentação são fixtures com retratos reais, não um playtest da campanha. 64 medições nativas de glifos dentro das áreas seguras, sem falhas. A inspeção inicial encontrou botão de pular fora da margem com texto ampliado; corrigido antes das capturas finais.

## Contraste e sinais complementares

`tools/audit_mural_contrast.py` mede luminância sRGB nas texturas reais: recorte central de 16%, pixels opacos, percentil 5 das razões de contraste. Também verifica os pares sólidos semânticos. Os 20 casos passaram na meta interna de 4,5:1. O menor dos pares/texturas finais medidos foi 5,47:1. Isso não afirma que todo pixel de toda tela, CRT ou vídeo está conforme uma norma; ornamentos e cantos são excluídos da área de texto pela auditoria de layout.

| Informação | Alternativa à cor/som já presente |
| --- | --- |
| Linha, armação e energia | Rótulos distintos, valores e barras segmentadas |
| Ação recarregando / sem energia | Mensagem de disponibilidade e valor/custo |
| Enroscada | Título e instrução da ação; não só cor da linha |
| Seleção | Marcador estático e foco nativo |
| Emblema pendente | Cadeado/posição e filtro; contagem explícita |
| Boss e mudança de fase | Warning nomeado, HUD própria e rótulo de fase |
| Carregamento | “Carregando…”; modo reduzido mantém símbolo estático |
| Erro ao salvar | Mensagem e ação de tentar novamente; comemoração não concede recompensa |
| Fala | Texto e interlocutor na interface; blips são opcionais |

Menus e diálogos mantêm seus testes de teclado, mouse e controle simulado; o mapeamento pode usar símbolos Xbox, PlayStation e Switch sem trocar posições físicas. Não foi criada promessa de suporte a hardware Nintendo nesta etapa.

## Limites e continuidade

Não houve playtest completo, avaliação por pessoas com deficiência, teste de leitor de tela, ensaio auditivo em equipamentos diferentes, verificação formal de flashes de vídeos ou certificação WCAG. Aberturas pré-renderizadas e o filtro CRT precisam continuar na avaliação final. Os avisos de acesso a `user://logs` e cache de shader são limitações do ambiente de teste, registradas nos logs locais.

Os relatórios antigos das suítes foram preservados; cópias das regressões desta execução estão nesta pasta. A próxima etapa é PIP-139: auditoria final e documentação dos componentes reais no HUD-KIT v2.
