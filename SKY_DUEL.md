# Duelo nas Alturas — laboratório 2.5D

Protótipo local contra bot, aberto pelo botão “Duelo nas Alturas · teste” no menu principal, inclusive para visitantes. Continua separado do combate online e não altera XP, moedas, inventário ou o modo atual.

Canvas com projeção em perspectiva de coordenadas x/y/z; nuvens em três camadas; sprites existentes ordenados por distância; câmera deslocada suavemente com a posição horizontal do jogador. Usa a aparência equipada quando disponível. Os sprites ainda são as vistas 2D atuais; esta etapa não cria desenhos de costas nem modelos 3D.

Mouse/dedo arrastado ou WASD/setas guiam o Pipamon. R/Avançar aumenta z (aproxima do rival inicial); F/Recuar diminui z. Roda do mouse também muda z. Espaço/Puxar ataca; Shift/Esquiva reposiciona e protege brevemente. Bot anuncia a puxada antes do ataque. Há pausa, reinício e saída; perda de foco pausa e limpa entradas.

As linhas são segmentos espaciais ligados a âncoras. Mira verde exige distância inferior a 24 unidades e ângulo útil em 3D, excluindo o trecho junto às âncoras. Sobreposição na projeção não basta. Cada puxada válida custa 16 de energia, tem recarga de 0,7s e causa 20 de desgaste. A esquiva custa 22, protege 0,55s e recarrega em 3s. Partida dura até 90s ou até cortar uma linha. Números provisórios para testar leitura e controle.

Builds Worker/Pages incorporam motor e cliente; sem migração de banco. Testes em sky-duel.test.mjs cobrem contato espacial, esquiva, custo, recarga, limites, vitória e reinício. Teste ainda necessário em aparelho físico para avaliar sensação dos controles.
