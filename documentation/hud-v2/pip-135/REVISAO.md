# PIP-135 — Menus com construção própria

Varal, Pipa Dex, evolução e porta-emblemas agora usam os dados da campanha Godot. A crítica do dono ao aspecto chapado mudou a direção desta etapa: em vez de reaplicar o mesmo papel, cada tela ganhou sua construção física. O lobby também recebeu os cartazes Mural e ícones salientes.

## Arte e tarefas

- **Varal:** etiquetas com fio, pregador e rabiola; tecido tensionado para o parceiro; barras em forma de fio com nós e cores distintas. Escolher parceiro e cuidar continuam chamando as operações existentes. Ações ficam fora da rolagem. A montaria mantém ícone e condição de saúde. O Varal mostra os parceiros existentes, sem inventar capacidade de depósito ou transferências.
- **Dex:** caderno encadernado com abas. Sete espécies com arte de combate realmente disponível no Godot. Conhecimento vem de sightings, acquiredModels e parceiros já possuídos. Não concede descoberta ao abrir. Prosa reaproveitada do catálogo autoral; condições de obtenção exclusivas da versão online foram excluídas.
- **Evolução:** diagrama de varetas, nível atual/próximo e teto real, XP e atributos da curva partner_levels/encounter_model. O conteúdo Godot não define árvores de transformação: a tela apresenta progressão real de nível, sem prometer desbloqueios inexistentes. No nível máximo não aparece uma meta fictícia de XP.
- **Emblemas:** estojo costurado com 12 posições; filtros Todos/Conquistados/Pendentes; nome, bairro, chefe e data já existentes no save. Selecionar nunca concede uma insígnia.

Arte, fontes, prompts, cortes e versões em art/ui/soulmonsters-v2/pip-135-v2/. O estudo de composição não virou screenshot de fundo. Produção usa cinco peças vazias e textos, barras, retratos e controles nativos. As primeiras ferragens de meio de borda deformavam; os assets foram corrigidos para manter ornamentos nos cantos fixos. Nenhuma aprovação artística do dono é inferida dos testes.

## Conferência

| Prova | Resultado |
| --- | --- |
| mural_menu_checks.gd | 683 verificações, zero falhas |
| lobby_checks.gd | 66 verificações, zero falhas |
| emblem_case_checks.gd | 61 verificações, zero falhas |
| mural_dialogue_checks.gd, regressão do botão compartilhado | 292 verificações, zero falhas |
| Margens de glyphs do lobby no renderer nativo | 64 verificações, zero falhas; padding-*.json |
| Capturas nativas | 40: cinco famílias × quatro resoluções × texto 100/150% |

Matriz: 1280×720, 1920×1080, 1024×768 e 1280×800. Testes incluem lista cheia e vazia, nome longo, erro com retry, nível máximo, botões de equipar/cuidar fora da rolagem, ícone de montaria, conhecimento da Dex e ausência de mutação ao consultar. As áreas de conteúdo excluem os cantos pintados; viewport de scroll fica integralmente dentro desse espaço. Elementos cortados na borda de uma lista ou descrição são conteúdo rolável; foco e teclas permitem acessá-los.

Teclado, mouse e controle foram exercitados por eventos nativos simulados. Tab/ombros mudam seção; detalhes têm foco próprio para rolar por cima/baixo e retornar à lista pela esquerda. As suítes existentes conferem bloqueio de comandos sob o overlay, retorno ao lobby e restauração do foco. Não houve teste com controle físico ou uma sessão integral de campanha. Inspeção visual nativa complementa os testes; os 64 glyph checks medem os rótulos desenhados do lobby, não alegam cobrir toda letra de toda tela.

Os harnesses de lobby e emblemas agora usam pastas isoladas sob tmp/ no workspace, pois user:// não era gravável no ambiente. O destino de save do jogo não mudou. A antiga asserção por índice de filho na PIP-76 foi atualizada para o estado/retry do novo álbum; essa suíte visual completa não foi reexecutada aqui.

Persistem avisos ambientais de logs/cache e de configuração do editor. As suítes antigas também avisam sobre carregamento direto de imagens da casa/professor. Não se alega validação de exportação. Capturas são feitas uma resolução por processo, para limitar memória durante a auditoria.

Sem alteração de balanceamento, curva de XP, recompensas ou formato de save. Sem merge, push ou mudança de ticket no Linear. Galeria em index.html; dimensões e hashes em integridade.json. O próximo conjunto é PIP-136, resultado e grandes momentos.
