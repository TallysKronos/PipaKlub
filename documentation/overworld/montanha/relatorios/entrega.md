# Entrega — Montanha A/B/C

## 1. Arquivos
Gerador e testes próprios em tools/mapa-studio; brief em art/overworld/briefs/montanha.md; três fontes Tiled e três mapas compilados; index de prévias. Kit montanha-v1, fontes, prova de repetição 3×3 e manifesto. Construtor mountain_structures.gd; ramificações condicionais nos construtores de floresta e shader de chão. Capturador agora cobre cotas acima de 2 e evita imagens repetidas da mesma coluna de barranco na montanha.

## 2. Resultado automático
A: SEM ERRO, 0 erros/avisos; platô 45,6%; 3 itens, 1 escondido; 12 células de rampa; 0 inalcançáveis/degraus soltos.
B: SEM ERRO, 0 erros/avisos; platô 49,9%; 3 itens, 1 escondido; 12 células de rampa; 0 inalcançáveis/degraus soltos.
C: SEM ERRO, 0 erros/avisos; platô 52,4%; 3 itens, 1 escondido; 24 células de rampa; 0 inalcançáveis/degraus soltos.

Node: 13 testes, 13 aprovados (montanha, modelo, industrial e pântano). Overworld: 186722 verificações, 0 falhas. Morro: 9386 verificações, 0 falhas. Pântano: 0 falhas de margens/pontes. O teste headless geral ainda imprime diagnóstico do shader legado _painted_floor; os testes de renderização das capturas da montanha não registraram erro de script/shader. O primeiro teste do Morro não conseguiu escrever o save temporário no ambiente restrito; repetido com acesso ao diretório de usuário, passou.

## 3. Capturas
captures/a, b, c: geometria, arte e arte-terreno; 66, 76 e 103 enquadramentos por versão respectivamente. Total 735 PNGs nativos 1280×720, além das seis pranchas de contato. Planos em planos/. A geral usa zoom 0,30 para caber a altura; jogo 1,0; juntas 2,3. Um enquadramento cobre toda a coluna de um mesmo canto de barranco, sem repetir a mesma imagem por cada nível atravessado. As juntas não têm personagem. Sem água, ponte ou mureta nesta região. Pranchas revistas para continuidade e amostras ampliadas para textura/acesso/base do marco; dimensões e inventário conferidos pelo verificador de capturas.

## 4. Percurso
Teste com o controlador real da prévia e física do Godot: A 28 destinos/56 viagens/20060 quadros; B 29/58/27420; C 53/106/32320. Total 220 viagens, 0 falhas. Verifica suporte dos pés e seguidor; inclui rampas em ambos os sentidos, itens e saídas. Testes Node asseguram que o cume exige rampas em ambas as cotas de cada parte e que C tem rota alternativa de descida. Não é sessão manual com controle físico.

## 5. Itens e história
Cada parte contém cola-reparo, vareta-bambu escondida e papel-seda em becos acessíveis. Mato opcional fora da travessia obrigatória. Marco rochoso nas três partes. C termina em mirante; não há chefe, personagem, revelação ou nome canônico novo. Prévia independente, sem concessão de itens à conta ou alteração de campanha. A→B conserva cota 2; B→C conserva cota 4; terra e orientação v-/v+ combinam.

## 6. Integração
Disponível no seletor de overworld_preview. Integração de campanha, encontros e economia depende de tarefa específica; não foi modificada. Não houve exportação de jogo, deploy, merge ou envio ao remoto nesta tarefa.

## 7. Decisões do dono
Avaliar a direção visual das capturas. Recomendação: aprovar a leitura de altura e navegação da prévia antes de definir nome canônico, habitantes e ligação com a cidade.

## 8. Não verificado
Controle físico, Steam/export, desempenho em outras GPUs, sessão completa de campanha, concessão real dos itens e aprovação artística do dono. A revisão de todas as imagens foi em pranchas; nem todos os detalhes foram inspecionados individualmente em resolução total. A textura repetida tem padrões reconhecíveis em paredes grandes; a prova 3×3 foi preservada e isso pode receber variante adicional após aprovação. O fundo azul representa profundidade atmosférica de prévia, sem panorama distante pintado. Não há promessa de conclusão artística de produção.
