# Duelo nas Alturas — laboratório 2.5D

## Rebicadas de linha

Seis skills selecionáveis no laboratório. Segurar E ou o botão prepara a manobra; soltar executa. Após 1,2s ela é liberada automaticamente. A + E escolhe a direção esquerda; a direção padrão é direita. Movimento manual, ataque comum e esquiva ficam bloqueados durante a manobra. Pausar ou sair cancela uma preparação pendente sem devolver energia ou recarga. A animação já liberada pausa e continua junto com o duelo.

| Skill | Energia | Recarga | Efeito |
| --- | --- | --- | --- |
| Puxão | 28 | 4s | Mergulho e subida; janela de crítico de 32 durante a retomada |
| Chicote lateral | 26 | 4,5s | Varredura em S, até 24; erro deixa 0,85s de recuperação |
| Estilingue | 32 | 5s | Recuo e avanço de 150 unidades em profundidade, até 28 |
| Laço | 30 | 5s | Volta para mudar o ângulo, até 20; um corte recebido interrompe |
| Folha solta | 20 | 3,5s | Descida e recuperação lateral; sem dano ou invulnerabilidade |
| Duplo toque | 30 | 4,5s | Dois pulsos automáticos de 8 e 18; segundo ignora e desfaz guarda ativa |

Cada janela só pode acertar uma vez e exige o contato espacial real das linhas. A guarda do bot é sinalizada durante a preparação de sua puxada e reduz outros golpes. Custos e danos são provisórios. Rastro azul tracejado indica trajetória, linha sólida indica geometria de contato; destaque dourado marca crítico e texto confirma quebra de guarda. Movimento reduzido usa destaques estáticos para os impactos. A skill da linha ainda não está ligada à loja nem ao combate principal: esta integração é exclusiva do laboratório.

Protótipo local contra bot, aberto pelo botão “Duelo nas Alturas · teste” no menu principal, inclusive para visitantes. Continua separado do combate online e não altera XP, moedas, inventário ou o modo atual.

Canvas com projeção em perspectiva de coordenadas x/y/z; nuvens em três camadas; sprites existentes ordenados por distância; câmera deslocada suavemente com a posição horizontal do jogador. Usa a aparência equipada quando disponível. Os sprites ainda são as vistas 2D atuais; esta etapa não cria desenhos de costas nem modelos 3D.

Mouse/dedo arrastado ou WASD/setas guiam o Pipamon. R/Avançar aumenta z (aproxima do rival inicial); F/Recuar diminui z. Roda do mouse também muda z. Espaço/Puxar ataca; Shift/Esquiva reposiciona e protege brevemente. Bot anuncia a puxada antes do ataque. Há pausa, reinício e saída; perda de foco pausa e limpa entradas.

As linhas são segmentos espaciais ligados a âncoras. Mira verde exige distância inferior a 24 unidades e ângulo útil em 3D, excluindo o trecho junto às âncoras. Sobreposição na projeção não basta. Cada puxada válida custa 16 de energia, tem recarga de 0,7s e causa 20 de desgaste. A esquiva custa 22, protege 0,55s e recarrega em 3s. Partida dura até 90s ou até cortar uma linha. Números provisórios para testar leitura e controle.

Builds Worker/Pages incorporam motor e cliente; sem migração de banco. Testes em sky-duel.test.mjs cobrem contato espacial, esquiva, custo, recarga, limites, vitória e reinício. Teste ainda necessário em aparelho físico para avaliar sensação dos controles.
