# PIP-75 — Título, menu e jornadas

Entrega local. Sem push, merge, publicação ou mudança no Linear.

## Visual e navegação

- Fundo ilustrado do bairro com pipas e ruínas e logotipo original Soulmonsters: Elo das Ruínas, gerados pelo image_gen integrado. Kael usa o retrato existente, separado do fundo.
- Ilustração em cover uniforme, logotipo e retrato sem deformação. Botões e todos os dados funcionais são UI nativa.
- Tela de título com Pressione Start a 1 Hz, estático com movimento reduzido.
- Menu principal em corte diagonal de tinta: Continuar, Nova jornada, Configurações e Sair. Seleção em papel com rabiola, recuo de 18 pixels e foco na primeira ação disponível.
- Jornadas em três faixas, com área e miniatura derivadas do checkpoint real, parceiro equipado, data em UTC e tempo registrado. O adesivo AUTO identifica o salvamento automático da campanha.
- Slots ocupados não podem ser sobrescritos ao começar nova jornada. Saves inválidos continuam preservados, com ação indisponível.
- Exclusão confirmada no diálogo mangá com foco em Cancelar. Arquivos são arquivados no diretório local da campanha; Desfazer exclusão funciona também após reabrir a lista e nunca sobrescreve um slot ocupado.
- Entrada na jornada usa mancha ceu. Voltar funciona com teclado/controle; configurações mantêm o retorno ao menu.

## Dados de tempo

Metadados opcionais playSeconds e savedAt, sem mudança da versão do formato. Tempo registra duração da sessão, incluindo pausa; não reconstrói horas antigas. Arquivo legado sem tempo mostra Tempo sem registro e, após salvar, informa que existe histórico anterior. Regras, economia e recebimento de recompensas permanecem nos mesmos serviços.

## Verificação

349 verificações específicas sem falhas, incluindo 0, 1 e 3 saves reais isolados, foco, entrada e retorno por eventos de teclado e controle simulados, slots com nome longo, margem da rabiola, recuperar exclusão, rejeitar revisão obsoleta e arquivos antigos sem tempo.

Capturas renderizadas em 1280×720, 1280×800, 1920×1080 e 2560×1080, em mockups/revisao/pip75. Renderização antes das últimas assertions adicionais: 306 verificações sem falhas, sem mudança visual posterior. Campanha: 206 sem falhas. Percurso completo com Morro: 209 sem falhas. Sem teste de controle físico nem novo build publicado.

## Assets

PNG finais e prompts completos em godot/assets/campaign/title-v1/manifest.json. As fontes geradas originais foram mantidas em .codex/generated_images. Fundo sem texto; apenas o logotipo contém lettering em imagem. Alpha do logotipo preservado; nenhuma alteração raster posterior. Os PNG também estão incluídos no filtro do preset de exportação para o carregamento de fallback.

Revisão visual solicitada: fundo neighborhood-soulmonsters-v2.png com Azulão, Carcará, Rabbito e Mata Verde voando. Camada de Kael removida do menu. Arte anterior preservada; prompt e referências registrados no manifesto de title-v1.

Correção após rejeição do usuário: a versão v2 foi substituída por neighborhood-soulgen-v3.png. As referências desta geração são os arquivos atuais de art/soulgen/keys: Rabbito (concept color-rig-v2), Guaravento, Flautrevo e Marulume (preview color-rig-v2). Conferidos formato facetado, remendos, olhos, cores, armações e rabiolas. Nenhum spritesheet antigo é referência da v3. Prompt completo soulgen-v3-prompt.txt. A versão v2 fica marcada como rejeitada no manifesto e não é consumida pelo menu.

Revisão v4: Rabbito mantido como referência aprovada; demais criaturas substituídas pelos quatro iniciais reais de journey.gd (Carcará, Azulão, Mata Verde, Raio de Sol). Referências renderizadas diretamente dos rigs atuais em title-v1/reference-rigs. Fundo ativo neighborhood-starters-soulgen-v4.png.

Refino de Jornadas: retrato do parceiro equipado derivado do atlas da batalha; nome separado da localização; prévia do local atual preservando proporção; comandos empilhados com Excluir secundário. Faixas de 150 px com Containers e texto nativo, sem alteração no formato de saves. Verificação visual em capturas de 0/1/3 saves e resoluções 1280x720, 1280x800, 1920x1080 e 2560x1080.

Configurações: fundo ilustrado compartilhado com Jornadas, grupos Imagem e conforto/Controles, descrições e estados explícitos; largura limitada, rolagem com foco, comandos compactos e símbolos preservados. Capturas em quatro resoluções; validação com preferências e saves isolados. Não houve teste com controle físico.

Pausa refinada: recorte diagonal em ciano, Retomar em papel quando focado, comandos com espaçamento e ícones compartilhados; resumo escuro com parceiro equipado e barras de condição. Cena permanece visível sob véu. Validação isolada pause_visual_checks.gd: 41 verificações sem falhas em quatro resoluções, incluindo foco inicial, limites dos comandos e suspensão/retomada real da exploração. Capturas pausa-* em mockups/revisao/pip75.

Equipe e Mochila: fundo ilustrado compartilhado e placas escuras; retratos sem distorção, parceiro ativo em ciano, barras de linha/armação e experiência. Mochila com categorias e detalhes em contraste claro; estado vazio explícito limpa os dados anteriores. Capturas equipe-* e mochila-* em quatro resoluções. Runner isolado pause_visual_checks.gd: 61 verificações sem falhas, incluindo navegação de rotas e limpeza de filtro vazio. Sem teste com controle físico.

Controles: comandos agrupados em Exploração/Batalha, duas colunas com teclas visíveis, instrução curta, retorno e restauração compactos. Capturas controles-* em quatro resoluções. Runner isolado ampliado: 125 verificações sem falhas, incluindo remapeamento válido para T, conflito com Q, cancelamento por Esc e visibilidade dos 12 comandos. Preferências de teste isoladas.

Confirmações de sistema: placa central com título, consequência explícita e foco inicial em Cancelar; exclusão de jornada e restauração de teclas usam o mesmo componente. Falas narrativas preservadas. Restauração agora requer confirmação. Corrigido retorno de Controles para Configurações pela rota em maiúsculas. Runner visual: 133 verificações sem falhas, quatro resoluções.

Auditoria de navegação final: foco das confirmações restrito a Cancelar/Confirmar via Tab e vizinhos direcionais, sem alcançar ações atrás do modal. Eventos reais simulados de Tab/Esc validam fechar modal sem sair da página e retornar de Controles para Configurações. Troca pela ação Escolher parceiro persiste equippedPartnerId. Runner em quatro resoluções: 169 verificações sem falhas, usando saves/preferências isolados. Capturas atualizadas. Alterações locais, sem publicação ou mudança de status no Linear.

Aprovação visual do usuário em 28/10/2026: menu e refinamentos internos aprovados para envio ao Git. Teste com controle físico e conferência do executável exportado permanecem pendentes.
