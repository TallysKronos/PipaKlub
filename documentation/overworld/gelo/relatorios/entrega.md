# Entrega — Gelo A/B/C/D

## 1. Arquivos criados e alterados
Brief ASCII em art/overworld/briefs/gelo.md. Gerador determinístico desenhar-gelo.mjs, quatro fontes Tiled e quatro mapas compilados, registrados no seletor de prévias. Testes gelo.test.mjs e verificador de capturas. Renderizador ice_structures.gd, shader ice_ground.gdshader e integração condicional em kronasta_forest.gd e forest_structures.gd. Capturador compartilha a deduplicação de cantos verticais já usada na mina. Kit gelo-v1 novo; nenhum kit alheio foi modificado.

## 2. Resultado automático
Quatro partes: CONFERÊNCIA ZERO QUEBRA SEM ERRO, zero erros e zero avisos. Platôs A 55,9%, B 53,6%, C 54,8%, D 51,8%: métrica absoluta sobre o terreno, não porcentagem de um único piso caminhável. Cotas A 1→2, B 2→3, C 3→4, D 4→5; exterior -2. Todas as rampas v-, com duas células de extensão e cinco faixas. Dez células de rampa A/B/C; vinte D. Nenhum degrau solto ou bolsão inalcançável. Cada parte tem três itens, um escondido, e encontro opcional fora da trilha obrigatória. Links combinam direção, material e altitude. Peças têm colisões explícitas e apoio uniforme. A revisão fechou um pequeno furo isolado em C e acrescentou teste contra esse defeito.
Node: 22 testes aprovados. Godot geral: 254516 verificações, zero falhas; Morro: 9386, zero falhas; corte da mina: 8841, zero falhas; margens do pântano: zero falhas. O percurso C e os 22 testes Node foram repetidos depois de fechar o furo. Logs de captura sem SCRIPT ERROR, SHADER ERROR ou CAPTURE FAILED.

## 3. Capturas
A 73, B 76, C 91, D 90 enquadramentos, cada um em geometria, arte e arte-terreno: 990 PNGs nativos 1280×720. Geral em zoom .40 com deslocamento de enquadramento; jogo em 1; juntas em 2,3. Sem personagem cobrindo juntas. Planos completos, oito pranchas de contato e inventário com hashes em relatorios/capturas.json. Incluem rampas, pés, patamares, bordas e cantos; ponte, escada, água aberta e mureta não existem nesta versão. O lago congelado é chão opaco à mesma cota, não um poço de água. Não substitui áreas existentes, portanto não há antes/depois de outro mapa.

## 4. Percurso
Controlador real da prévia Godot: A 24 destinos/48 viagens/10120 quadros; B 25/50/14040; C 25/50/12200; D 45/90/23160. Total 119 destinos, 238 viagens e 59520 quadros, zero falhas. Inclui itens, saídas, todas as rampas nos dois sentidos e suporte dos pés/seguidor. Teste próprio bloqueia cada ascensão D separadamente e verifica a outra, e cada margem do desfiladeiro separadamente. Inspeção visual das quatro gerais, das pranchas de arte e de amostras nativas de rampas, lago, fenda, apoio de árvores e marco final. Geometria e arte-terreno disponíveis para conferência sem peças.

## 5. Conteúdo e coerência
Prévia independente sem novos nomes canônicos ou revelações de história. Clareira com abrigo e pinheiros; lago inteiramente congelado; fenda com desvio pelas duas margens; formação glacial final com duas rampas e retorno. Doze itens de prévia, quatro escondidos, sem concessão online. Cinco peças novas: pinheiro nevado, rocha nevada, cristais, abrigo e formação glacial; superfície de parede azul estratificada. Neve, geada e gelo usam máscaras do terreno; pegadas e estacas azuis sinalizam percurso. Reutilizada apenas a superfície da gruta como ruído de baixa intensidade. Arte original em mangá/cartoon 2D, contorno escuro e sombras chapadas. Fundos pretos conforme preferência do dono.
PNGs das peças têm alfa zero. O shader existente descarta halos semitransparentes; originais foram preservados. Manifesto descreve pivôs, dimensões, escalas e colisões; formação secundária usa 255px e 3×3, final 360px e 4×3. Lago opaco e caminhável; rachaduras são gráficas, não risco de quebra.

## 6. Pedidos ao integrador
Disponível em overworld_preview com IDs gelo-a/b/c/d. Não altera campanha, saves, batalha, servidor ou economia. Integração narrativa, inimigos, áudio, clima, gelo escorregadio e recompensas reais exigem escopo próprio. Nenhum merge, deploy ou push realizado. Branch codex/mapa-gelo.

## 7. Decisões do dono
Revisar os quatro cenários antes de escolher ligação com a campanha, nomes e função narrativa. Kit marcado pending_owner_review. Recomendação: validar a exploração e a leitura dos acessos antes de adicionar dificuldade de movimento sobre gelo.

## 8. O que não foi verificado
Não houve teste manual com controle físico, export/Steam, outras GPUs, desempenho em máquina fraca, campanha completa nem concessão online. As pranchas permitem conferir todo o conjunto, mas nem todas as juntas foram examinadas individualmente em resolução integral. Assets estáticos; não há simulação de neve ou vento, boss, mecânica de gelo ou evento canônico. A grade ainda produz silhuetas em degraus e a parede repete a textura de gelo. O teste geral headless imprime diagnóstico legado do shader _painted_floor; Morro avisa recursos ainda em uso ao encerrar. Os testes concluem com zero falhas e as capturas OpenGL passam sem erro de script/shader. O geral foi executado antes do fechamento de uma única célula isolada de C; Node e percurso C foram repetidos após essa correção.
