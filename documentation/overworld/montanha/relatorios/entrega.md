# Entrega — revisão visual Montanha A/B/C

## 1. Arquivos criados e alterados
Mesmos IDs e mesma branch codex/mapa-montanha. Gerador, brief e fontes Tiled/compiladas reconstruídos. Novo panorama-v2 e macico-v2, fontes preservadas e manifesto atualizado. Construtor mountain_structures: distribuição autoral de maciços em vez de grade de pedras, marco crescente por parte, vegetação do sopé e panorama com enquadramento conforme a altitude. Shader de chão: paletas por trecho, rocha e terra com variação; bordas dos barrancos menos saturadas. Sustentação externa estendida com o mesmo contorno do terreno; rocha bloqueada agora tem volume acima da trilha. Antes/depois em comparacao/.

## 2. Resultado automático
Gerador: A, B e C SEM ERRO, 0 erros e 0 avisos.
A: platô 88,8%; B: 84,2%; C: 82,1%. Cada parte: 3 itens, 1 escondido; nenhum inalcançável ou degrau solto. Rampas: A 12 células, B 12, C 24; todas v-. Conexões mantêm material terra, cotas 2/4 e direções v-/v+.
Node: 14 testes aprovados. Godot overworld: 186722 verificações/0 falhas; Morro: 9386/0; pântano: 0 falhas. Teste adicional impede regressão ao modelo de corredores sem massa de sustentação. Dados resumidos em testes-v2.json.

## 3. Capturas
Planos próprios, vistas gerais, jogo em zoom 1 e detalhes de juntas em zoom 2,3, sem personagens. Geometria, arte e arte-terreno. 121 enquadramentos em A, 143 em B, 189 em C: 1359 imagens nativas 1280×720. Mesmo canto em vários níveis usa um enquadramento da coluna inteira. Verificador confere dimensões, inventário e hashes em capturas.json. Pranchas de contato para conferência do conjunto; comparacao/ contém versão anterior e comparação lado a lado.

A vista geral prioriza o terreno explorável. O corpo da montanha continua abaixo do enquadramento, em vez de terminar como plataforma suspensa. O panorama é cenário distante, sem colisão ou passagem aparente integrada à planta. Não há água, mureta ou ponte neste percurso.

## 4. Percurso
Controlador real da prévia: A 28 destinos, 56 viagens, 20060 quadros; B 29/58/27460; C 53/106/32800. Total 220 viagens, nenhuma falha. Itens, saídas, rampas nos dois sentidos, pés apoiados e seguidor conferidos pelo teste. Rotas centrais têm curvas e larguras próprias; C mantém volta alternativa. Revisão visual em gerais e pranchas, com amostras ampliadas de acesso, paredes e apoio de peças. Não houve sessão manual com controle físico.

## 5. Itens, pistas e revelações
Preservados os três itens por parte e o mato opcional. Sem nova informação de história, chefe, NPC ou nome canônico. Sopé verde, encosta exposta e cume aberto são diferenças ambientais, não eventos de campanha. A crista de C ganhou escala de marco e vista para montanhas distantes. Região continua prévia independente, sem concessão de recompensas à conta.

## 6. Integração
Disponível no seletor de overworld_preview. Campanha, economia, save e combate preservados. Nenhum deploy, merge ou push nesta revisão.

## 7. Decisão do dono
Revisar as novas capturas. A recomendação é conferir esta composição no jogo antes de qualquer integração narrativa.

## 8. Não verificado e limites
Não testados: controle físico, export/Steam, outras GPUs e ciclo completo de campanha. Revisão do conjunto por pranchas; nem todas as imagens foram inspecionadas individualmente em tamanho integral. O terreno ainda usa uma grade isométrica: contornos têm degraus e a textura de parede repete padrões em faces extensas. O panorama é uma pintura fixa no espaço do mundo, sem parallax. Não há aprovação artística do dono. O teste headless geral ainda imprime diagnóstico de shader legado _painted_floor; isso é separado do renderer da montanha. O teste do Morro também pode emitir aviso de liberação de recursos ao encerrar, embora as verificações passem.

Revisão conferida após as capturas: foram retiradas as faces externas inclinadas experimentais porque geravam fendas na ordenação de profundidade. As faces finais continuam verticais e fechadas, com grande profundidade; a silhueta superior e os volumes bloqueados foram reconstruídos. Isso melhora a sustentação, mas ainda deixa leitura de terraços geométricos; uma montanha inteiramente orgânica exigiria modelar contornos fora da grade com o mesmo contrato de colisão. Esse limite está explícito para revisão do dono.
