# Platyx C — animação v1

Aprovada visualmente pelo dono nesta conversa. Produção futura no modelo Soulgen solicitada; esta versão serve de referência de identidade e gestos, sem afirmar que já foi convertida.

Fonte: image_gen integrado, baseado exclusivamente no design C aprovado em ../exploracao-v3/design-c.png. Primeira geração descartada por margem insuficiente. Segunda geração corrige o espaçamento; fonte final 1254×1254 (a ferramenta não entregou os 2048 solicitados).

16 poses: repouso 4, ataque 4, dano 3, derrota 1, vitória 4. Movimento/flight reutiliza repouso explicitamente; não há um ciclo de voo próprio. Ataque retraído, proteção do rosto no dano, comemoração discreta. Vitória tem um quadro de salto; o empacotamento alinha os pés e não preserva sua elevação física, que fica como pose.

Empacotamento reproduzível: tools/package-platyx-v2.py. Detecta corredores transparentes próximos às divisões nominais para evitar cortar a cauda do segundo quadro de ataque; verifica sete colunas vazias na divisão e margem mínima de 3 pixels na fonte. Uma escala comum preserva proporções relativas; base dos pés em y=228 nas células 256×256. Atlas 1024×1024 com alpha original preservado. Fonte e recortes não são rig. GIFs são prévias de ciclos, não gravações do jogo.

Integrado localmente como platyx-draft em content.json, com cadência por ação e dano/ataque sem loop. Arte antiga preservada. Alteração não concede a espécie nem muda atributos, recompensas ou combate.

Verificação: empacotador passou os 16 recortes e os seis mapeamentos; atlas final inspecionado. Fluxo nativo Godot Beira-Canal: 60 verificações, zero falhas. Captura 1280×720 do encontro com Grampo revisada em documentation/qa/beira-canal-v1/07-grampo-duelo.png: modelo C aparece completo e voltado ao adversário. A captura do teste é de repouso; não constitui revisão visual completa das transições em tempo real. GIFs permitem revisar os quadros de cada ação. Importação emite o aviso de safe-save do editor já existente, sem alterar proteções. Não houve push, merge ou deploy.
