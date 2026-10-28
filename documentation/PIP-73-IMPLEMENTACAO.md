# PIP-73 — HUD de exploração compartilhada

Entrega local; sem push, merge ou alteração de status no Linear.

## Aplicado

- Um componente para Rua, Ateliê, Jardim, Clareira, Veredas e cinco áreas do Morro.
- Nome da área recolhe para chip após três segundos. Objetivo desaparece em quatro segundos; mudança do texto e abertura da pausa o revelam novamente.
- Parceiro ativo com retrato em losango, nível real e condição da linha. Cores de alerta usam folha, sol e rabiola; a linha do elo é decorativa em ceu. Não há porcentagem de vínculo porque a campanha ainda não fornece esse atributo.
- Minimapa de caminhos com moldura em losango, norte rabiola e seta papel. Sem marcadores de NPC, baú ou saída.
- Prompt contextual no canto inferior direito, com glyph e no máximo duas linhas. Botões de Equipe/Bolsa/Menu aparecem com mouse ou toque, somem ao usar teclado/controle e recolhem após quatro segundos sem uso.
- Chip de moedas aparece quando muda o valor ou ao abrir a pausa. A pausa continua oferecendo Equipe, Mochila e configurações.
- Avisos de autosave e itens são discretos, duram três segundos e respeitam o limite de três. Apenas item recebe uma pequena pincelada. Falhas de gravação continuam exigindo atenção no diálogo existente, para preservar o bloqueio de progresso.
- Etiquetas dos NPCs do Morro usam o mesmo recorte pequeno.

## Verificado

664 verificações da HUD, zero falhas, com renderização real e 40 capturas de repouso. Matriz: dez áreas em 1280×720, 1280×800, 1920×1080 e 2560×1080. Em todos os casos, a área dos retângulos visíveis da HUD ficou abaixo de 10% após recolher; a medição é conservadora, inclui o retângulo inteiro do minimapa em losango e está disponível em player_visual_audit.gd.

Testados troca de dispositivo simulada, objetivos novos, revelação pela pausa, moedas, limite/expiração de avisos e posição das caixas. Capturas em mockups/revisao/pip73. Dados e armazenamento isolados. Não equivale a teste com controle físico ou aprovação artística dos cenários antigos.
