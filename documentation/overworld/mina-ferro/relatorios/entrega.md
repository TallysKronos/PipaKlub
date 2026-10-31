# Entrega — Mina de ferro A/B/C/D

## 1. Arquivos criados e alterados
Brief em art/overworld/briefs/mina-ferro.md. Gerador determinístico e testes próprios em tools/mapa-studio. Quatro fontes Tiled e quatro mapas compilados, registrados no seletor de prévias. Construtor mine_structures.gd e shader mine_ground.gdshader. Integração condicional no construtor de floresta e corte de teto em forest_structures.gd; outros biomas preservam o comportamento anterior. Capturador aceita deslocamento vertical opcional e remove repetições do mesmo canto entre cotas na mina. Kit mina-ferro-v1 com seis PNGs novos, fontes originais, prompts completos, QA de alfa, manifesto e prancha. Nenhum kit alheio foi regravado.

## 2. Resultado automático
A, B, C e D: CONFERÊNCIA ZERO QUEBRA SEM ERRO; 0 erros e 0 avisos.
A: platô 77,6%; B/C/D: 100%. A métrica é de cotas absolutas e inclui a rocha bloqueada: não significa que 100% do chão caminhável seja um único platô. Cada parte tem dois pisos caminháveis com acesso por rampa; cotas 0→1, 1→2, 2→3, 3→4. Paredes chegam à cota 6.
Cada parte: 3 itens, 1 escondido, 0 inalcançáveis e 0 degraus soltos. Rampas expandidas: 10 células em A/B/C, 20 em D; todas v-. Links A↔B↔C↔D têm direção, terra e cotas compatíveis. Os apoios dos pórticos têm colisão apenas na base, com vão central livre.
Node: 18 testes aprovados (mina, modelo, montanha, industrial e pântano). Godot overworld: 219019 verificações, 0 falhas. Morro: 9386, 0 falhas. Pântano: 0 falhas de água/margem. Os testes próprios conferem fontes compiladas, ligações, apoios uniformes das peças, itens e trilhos sobre chão válido, com carrinhos alinhados aos ramais. Capturas não registraram SCRIPT ERROR, SHADER ERROR ou CAPTURE FAILED.

## 3. Capturas
71 enquadramentos de A, 69 de B, 81 de C e 76 de D, em geometria, arte e arte-terreno: 891 PNGs nativos 1280×720. Planos em planos/. Gerais em zoom .46 com deslocamento de enquadramento; jogo em zoom 1; juntas em 2,3. Não há personagem cobrindo juntas. Pranchas de contato nas pastas de cada parte. Verificador de inventário/dimensões/hashes: tools/mapa-studio/verificar-capturas-mina-ferro.mjs; resultado em relatorios/capturas.json. Sem ponte, água ou mureta nesta versão, portanto essas capturas não se aplicam. A caverna anterior não foi substituída: a mina é um novo conjunto de mapas.

## 4. Percurso
Controlador real e física da prévia do Godot: A 24 destinos/48 viagens/9280 quadros; B 25/50/15020; C 25/50/10820; D 45/90/23540. Total 119 destinos, 238 viagens e 58660 quadros, nenhuma falha. Inclui acesso aos itens e saídas, pés e seguidor, todas as rampas nos dois sentidos. Em D os dois acessos oferecem circuito real de retorno. A inspeção visual incluiu as gerais e pranchas das quatro partes e amostras nativas de rodas, minério, pilares e rampas. Não houve teste manual com controle físico.

## 5. Conteúdo e coerência
Prévia independente, sem nome canônico novo ou revelação da bíblia. Pátio de carga, entroncamento, frente de extração e grande veio são títulos funcionais. Ferro é identificado por hematita vermelho-terra; o grande veio está no piso da sala final, próximo da circulação. Há 12 itens de prévia, 4 escondidos; sem concessão online. Mato técnico foi apresentado como cascalho escuro opcional, fora da via principal. Seis novos sprites: carrinho cheio, vazio, minério, guincho, ferramentas e estoque. Reusados seis tipos de formações e três superfícies da gruta seca cavernas-v3. Trilhos retos/curvos, dormentes, junções, pórticos, escoras e lanternas são módulos nativos. Total de 76 peças com colisão explícita, além dos trilhos e luzes de cenário. Os PNGs têm alfa zero; halos semitransparentes das fontes são descartados pelo shader de recorte existente. Escala uniforme e pivôs ajustados no jogo.

## 6. Pedidos ao integrador
Disponível no seletor de overworld_preview com IDs mina-ferro-a/b/c/d. Não foi alterada campanha, save, banco, servidor ou economia. Mineração coletável, trem/carrinho controlável, inimigos, som e animações exigem tarefas separadas, se desejados. Nenhum merge, deploy ou push foi feito nesta tarefa. A alteração anterior do fundo preto da montanha foi preservada em commit antes de abrir a branch codex/mina-ferro.

## 7. Decisões do dono
Revisar os quatro mapas em jogo antes de definir ligação com a campanha, nomes canônicos ou recursos da economia. Recomendação: manter os carrinhos estacionados nesta primeira versão e validar primeiro exploração e leitura do cenário.

## 8. O que não foi verificado
Export/Steam, outras GPUs, desempenho em máquina fraca, controle físico, sessão de campanha completa, concessão real dos itens e aprovação artística do dono. O conjunto foi revisado por pranchas; nem todos os detalhes foram examinados individualmente em resolução integral. Carrinhos e guinchos são estáticos. A luz é uma indicação gráfica, sem iluminação dinâmica ou sombras móveis. Tetos do lado da câmera são retirados de forma deliberada, igualmente em geometria e arte; colisões do terreno continuam ativas. Curvas dos trilhos são decorativas, sem simulação ferroviária. Há recortes em degraus próprios da grade. O teste geral headless ainda imprime diagnóstico legado de shader _painted_floor, e o teste do Morro emite aviso de liberação de recursos ao encerrar; as verificações desses testes passam. As capturas de renderização da mina passaram sem esses erros de script/shader.
