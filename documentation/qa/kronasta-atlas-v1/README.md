# Kronasta — carta regional interativa

Atualização 01/11/2026: adicionados Mina de ferro (4 partes), Geleira de Kronasta (4 partes) e Recifes de Kronasta (3 partes). São agora 15 marcadores e 28 destinos. Capturas atualizadas. Conferência: [integração regional](../integracao-regional-2026-11-01/README.md).

31/10/2026. Implementação local no Godot, sem push.

Depois do treino/oficina, M abre a carta regional. Selecione um círculo e escolha a entrada no painel lateral. Setas/controle navegam entre controles; Enter confirma. M ou Voltar ao jogo fecha; Escape segue o retorno padrão dos menus. O mapa esquemático anterior permanece em Mapa da área. Antes de concluir a introdução, o mapa continua local e não libera viagem antecipada.

Disponíveis: Vila do Primeiro Vento, Parque dos Ventos, Bosque dos Ventos, Morro do Sol, Pântano, Montanhas e Distrito Industrial. São 17 pontos de chegada, incluindo partes A/B/C. A viagem usa a transação do save e uma entrada com apoio caminhável; não concede XP, vitória nem desbloqueio de missão. Os caminhos físicos do Morro mantêm suas travas.

Pântano/Montanhas/Distrito são áreas de exploração em desenvolvimento. Entram pela campanha com o parceiro e câmera existentes, sem criar chefe, história ou encontros aleatórios novos. As saídas internas A/B/C usam o resolvedor existente. A carta permite retornar à vila.

Apagados: costa, planícies, ruínas, cavernas e vulcão. Podem ser selecionados para leitura, mas o botão de entrada permanece desativado e o serviço rejeita destinos sem implementação. Os nomes descritivos e a distribuição geográfica da carta são propostas visuais, não novas revelações canônicas.

## Arte e implementação

Arte original gerada pela ferramenta image_gen, copiada para `godot/assets/campaign/maps/kronasta-atlas-v1.png`. Carta ilustrada 2D de aventura em nanquim e cor, sem texto na imagem: nomes, círculos, caminhos, foco, estado atual e botões são controles do Godot. Pontos posicionados após conferir os marcos na imagem final. Uma fonte de dados, `kronasta_atlas.gd`, define os destinos públicos e a rede; `hud_kronasta_map.gd` apresenta a carta. Futuras entradas são liberadas adicionando seus destinos reais à fonte e ao contrato de save, não clareando a imagem.

Direção do prompt: ilha regional de Soulmonsters em atlas 2D anime/mangá, contornos azul-escuros, cores cel, vegetação verde-sálvia, rios azul-petróleo, montanhas douradas, vulcão coral, cidade moderna, pontes e trilhas, rosa dos ventos e pipas no mar; sem nomes, marcadores, botões, moldura ou marca d'água.

## Verificação

- `kronasta_atlas_checks.gd`: 109 verificações aprovadas. Destinos reais, suporte do spawn, save e reload, rejeição dos futuros, abertura pelo comando M do controlador, carregamento do Pântano no adaptador de campanha, seleção dos pontos e acesso ao mapa local.
- Capturas nativas renderizadas 1280×720 e 1920×1080 nesta pasta. Inspeção visual da composição, nomes e rodapé.
- `campaign_checks.gd`: 206 verificações aprovadas.
- `park_journey_refinement_checks.gd`: 157 verificações aprovadas; recompensas reduzidas preservadas.

Não houve teste com controle físico nem nova travessia de todas as partes dos mapas nesta entrega. Os testes não validam as futuras regiões como jogáveis. Save pessoal preservado.
