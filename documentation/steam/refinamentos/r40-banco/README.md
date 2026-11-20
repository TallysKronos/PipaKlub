# R40 — banco da campanha e depósito compartilhado

05/11/2026. Base 5fae0f1b. Godot, armazenamento local.

## Fluxo do jogador

Pausa → Pipamons → **Banco e depósito** abre as duas listas com origem, lotação, arte existente, nome, nível e condição. Banco da campanha: 30 criaturas, incluindo o parceiro ativo; depósito global do perfil: 20. Não foi introduzido um segundo limite de equipe de combate.

Guardar, trazer para a campanha e liberar uma criatura exigem confirmação, inicialmente em Cancelar. Liberar é permanente do ponto de vista do jogo e não se desfaz carregando outro save. Criaturas emprestadas/temporárias, Retalho, Platyx e o parceiro da missão de montaria são conservadoramente vinculados à história; não podem ser depositados. O parceiro ativo também não pode ser transferido. A campanha deve conservar outro parceiro livre de vínculo de história e ter concluído o treinamento do professor. As transferências só ocorrem durante exploração, fora de batalhas e oficina.

Transferir **grava o progresso atual**, mesmo com autosave desligado; a tela e a confirmação avisam isso. Na entrada normal do jogo, o destino de retomada é o autosave 0, preservando os manuais. A ação não é anunciada como concluída antes de gravar o checkpoint e concluir seu recibo. Falha pendente oferece tentativa de conclusão.

## Propriedade e recuperação

- `partner_bank.gd` guarda propriedade por ID da criatura e por `campaignId`, além de todos os atributos da instância. O depósito fica fora dos arquivos arquivados na exclusão de campanha.
- A propriedade atual prevalece sobre cópias antigas do save: uma instância depositada, movida a outra campanha ou liberada não reaparece na campanha anterior. Parceiros comuns registrados ainda pertencentes à campanha são preservados quando ausentes de uma cópia antiga. Isso impede que rollback de arquivo perca a contraparte de uma transferência.
- Parceiros de história não são registrados para reinjeção, evitando ressuscitar Retalho quando uma cena o retira legitimamente da equipe. Um save de batalha antigo cujo combatente mudou de propriedade é recusado com orientação, sem apagar o arquivo.
- O registro usa gerações completas imutáveis, com versão, revisão e checksum. Uma intenção inclui a próxima fotografia da campanha, o destino, a revisão esperada e o recibo. Após o compromisso no registro, a gravação da campanha e a conclusão são retomáveis. Uma operação repetida com o mesmo recibo não muda a propriedade novamente.
- Se a geração mais recente estiver inválida, for futura ou houver duas gerações concorrentes com a mesma revisão, o jogo bloqueia o acesso e preserva os arquivos. Não volta silenciosamente a uma propriedade antiga, o que poderia perder ou duplicar uma criatura.
- São mantidas até oito gerações completas após commits bem-sucedidos; os recibos e registros de propriedade permanecem na geração atual. Falhas de limpeza podem deixar gerações extras, sem alterar o estado válido.
- O limite 30 bloqueia crescimento novo, sem mutilar coleções legadas maiores. Uma coleção antiga com 31 é carregada intacta e pode ser reduzida por transferência; não recebe novas criaturas enquanto exceder a capacidade.

## Escopo de conta e pendências

O depósito é compartilhado pelas jornadas **deste perfil local**, neste computador. Não está vinculado a SteamID, Supabase ou outra conta online e não sincroniza dispositivos. O diretório padrão é `user://account/partner-bank`; ferramentas e testes com pasta de campanha alternativa recebem um depósito isolado nessa pasta. Integrar autenticação, separação por SteamID e conflitos de sincronização exige etapa própria.

O ledger preserva identidade/propriedade; não certifica a economia contra edição de arquivos, restauração de um perfil inteiro ou duas instâncias escrevendo simultaneamente. A proteção de revisão detecta conflitos, mas não substitui um bloqueio exclusivo entre processos. Não há promessa de fsync/durabilidade em corte físico de energia.

**R41 continua pendente:** recusar uma aquisição acima de 30 não equivale a oferecer uma recompensa pendente com escolha de destino. Ainda é preciso revisar Rabbito, Retalho, captura, invocação, itens consumidos e saídas da tela nesse limite, além das regras de recompensas únicas após voltar a saves antigos. A política futura para transferir parceiros essenciais após o encerramento da história também precisa de definição específica.

## Verificação

Nova suíte `partner_bank_checks.gd`: **113 checks, zero falhas**. Cobre limites 29/30/31 e 19/20/21, duas campanhas, atributos completos, recibos, rollback manual, exclusão/desfazer da origem, descarte, legado excedente, parceiro ativo/emprestado/de história, falhas antes do compromisso/na campanha/na conclusão, reabertura com outro armazenamento, corrupção/versão futura/conflito e interface com controle simulado.

O teste de interrupção injeta falhas e reabre o serviço; não representa corte de energia nem encerramento físico do processo. Os perfis são descartáveis, sem saves reais. Capturas a 1280×720 com OpenGL Compatibility/GTX 1650: [banco com restrições](bank.png), [depósito com criatura](populated.png). Foi corrigido o corte do destaque do botão focado na revisão visual.

Regressões executadas, todas sem falhas: resiliência 152; campanha 207; autosave/slots 55; exclusão/reinício 216; título 350; ciclo de menu 55; feedback 35; recuperação de autosave 13. Com a nova suíte de 113 checks, são **1.196 verificações** nas nove suítes selecionadas. A nova suíte passou em headless e no renderizador real; eventos de controle foram simulados na viewport.

Ainda não verificados: conta/Cloud Steam, dois computadores, periférico físico, campanha prolongada com bancos cheios, todos os tamanhos de tela/texto, nova exportação e CI remota. O runner completo de 23 suítes não foi executado neste pacote.
