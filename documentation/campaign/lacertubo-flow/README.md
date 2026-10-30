# Fluxo da missão do Lacertubo
## Alterações
- Celina e seu último treino foram deslocados do pátio para a aproximação anterior (38,35). Todos os NPCs humanos ficam a pelo menos 16 células do boss.
- Nina permanece no Jardim; removida sua duplicata posterior nas Veredas.
- Eventos NPC sem identidade não recebem mais automaticamente a aparência do professor. Assis continua vinculado ao evento de orientação.
- Rastros indicam o canal, os canos e a preparação no banco.
- Aproximação a menos de oito células apresenta o guardião com foco de câmera e fala do Kael, uma vez por salvamento. Fechar a fala restaura câmera e controle; movimento reduzido usa reposicionamento imediato.
- O boss usa os quadros idle existentes. A área imediata não dispara encontros aleatórios.
- O confronto continua sendo uma escolha, com nível recomendado e possibilidade de recuar. Equipe incapacitada recebe orientação para o banco.
- Vitória destaca a coleta; rabiola maior com marcador no chão. Atalho só fica disponível após recolhê-la. Objetivo aponta retorno à Nina.
- IDs dos duelos, XP e recibos existentes preservados.

## Evidências
- Jornada e combates: 91 verificações, zero falhas, nível 8 alcançado pelos duelos opcionais.
- Integração da campanha: 104 verificações, zero falhas; movimento real do controlador, vitória com comandos de combate, coleta, entrega, recarga de save, fuga e derrota. O processo em modo headless permaneceu aberto após emitir o relatório e foi encerrado; os resultados são os do relatório emitido.
- Revisão nativa 1280×720: 19 verificações, zero falhas, com câmera animada. A rodada anterior também conferiu movimento reduzido. Este roteiro usa vitória sintética apenas para inspeção visual pós-combate; o combate real foi exercitado na integração.
- Saves isolados em tmp; nenhum save de campanha do usuário foi utilizado.
