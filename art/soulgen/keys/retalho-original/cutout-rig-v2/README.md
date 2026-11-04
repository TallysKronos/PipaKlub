# Retalho original — revisão spritelizada v2

Autor aprovou e enviou o projeto editado. Revisão do rig 2 preserva seus quatro membros reposicionados, pivôs, animações e PNGs embutidos. `author-import.json` registra hash e origem; `author-approved.portable.soulgen.json` é a cópia integral. O construtor respeita essa edição por padrão; `--rebuild-source` é exclusivamente para reconstrução explícita da base.

Identidade preservada: opção A da antiga parceira de Heleana. Esta é a forma original, não a evolução mascarada. A arte de possessão encontrada no Git continua sendo proposta; não foi incorporada.

Abrir: http://127.0.0.1:5241/?preset=retalho-original

Sete partes, quatro cabeças completas e seis ações: vigília, movimento, ataque, dano, vitória e derrota. Rabiola inclui nó e fitas. Contorno em degraus e cores em blocos seguem os guardiões. Ajustados encaixe do pescoço, posição do braço próximo e recorte da sua extremidade proximal; não foram pintados novos pixels por código.

Expressões substituem a cabeça inteira registrada na mesma tela, evitando a troca por uma boca isolada. Vitória serena. Cabeças geradas diferem ligeiramente no desenho externo; não se promete identidade de pixels entre rostos.

`../prepare-v2.py` extrai componentes alpha e registra cabeças com nearest-neighbor. `../build-rig.mjs` exporta 135 frames a 12 fps, sem tinta nas bordas das células. V1 preservada. O editor arquiva rascunhos antigos ao carregar a revisão 2.

Revisão visual feita nas poses renderizadas sobre fundos claro e escuro. Testes técnicos passaram; aprovação artística e inspeção interativa do movimento pelo autor continuam pendentes. Sem alteração do jogo ou publicação nesta etapa.
