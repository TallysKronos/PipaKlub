# Correção do corte frontal — 31/10/2026

A causa era a retirada completa do topo dos blocos da frente, deixando algumas faces verticais ainda em altura integral. A transição entre cotas também precisava conservar a sustentação do patamar superior.

Agora o corte calcula uma altura de apresentação a partir do chão visível atrás, com seção de 14px. Topo e paredes consultam a mesma altura; uma borda baixa acompanha o contorno medido. A regra vale somente para a mina. Nenhuma célula, colisão, item, rampa ou caminho foi alterado.

Capturas atuais nesta pasta: quatro áreas, geometria e arte, sete enquadramentos por versão (56 PNGs 1280×720). Incluem os extremos e a entrada da borda frontal. antes-depois.png mostra o trecho da imagem apontada; antes-a/b/c/d.png preservam a apresentação anterior. O conjunto maior em ../captures/ é histórico, anterior a esta correção de apresentação.

Verificações: 18 testes Node; 8841 verificações do novo teste Godot mine_cutaway_checks.gd (topos visíveis fechados e vértices coincidentes entre tampas e faces), sem falhas. Overworld: 219019 verificações, 0 falhas. Morro: 9386, 0 falhas. Entroncamento: 50 viagens do controlador real, 0 falhas. Hashes das capturas e scripts em verificacao.json. Não houve teste manual com controle físico ou exportação.
