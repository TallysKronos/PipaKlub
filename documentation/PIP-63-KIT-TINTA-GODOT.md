# PIP-63 · família de tinta Recorte

Entrega local na branch `godot`, continuação da base PIP-62 (`1be4866` / aceite `165651f`). O cliente web e a HUD da campanha não são substituídos nesta tarefa. O kit será consumido pelo Theme e pelas telas nas tarefas seguintes do épico.

## Peças entregues

64 peças, cada uma em PNG 1× e `@2x` (128 exports):

- Cinco molduras de nanquim com miolo transparente: painel, faixa, botão, item de lista e balão.
- Quatro corpos de balão: fala, grito, pensamento e sussurro. Quatro rabichos separados: esquerda, direita, pensamento e sussurro. O grito reutiliza o rabicho pontudo de fala.
- Três pinceladas de seleção com pontas fixas e miolo elástico.
- Oito respingos (3 P, 3 M, 2 G), quatro escorridos e três rastros; cada um tem versão cheia e só contorno.
- Oito emoções em dupla tinta nanquim/papel: suor, raiva, brilho, exclamação, pergunta, coração, tontura e suspiro.
- Quatro adesivos vazios, com nomes/níveis/quantidades apresentados por Labels no laboratório.
- Duas texturas de linhas de velocidade, uma máscara numérica de transição e três alternativas de retícula.

Manifesto em `godot/assets/ui/recorte-v1/manifest.json`: arquivos, tamanhos, margens, pivôs, alpha, filtro, origem e situação de aprovação. Cores derivadas dos tokens da PIP-62, sem paleta concorrente.

## Arte e montagem

Nove fontes raster originais foram produzidas com a ferramenta integrada `image_gen`, preservadas em `art/ui/recorte-v1/sources/` com metadados originais. Briefs dos prompts e histórico de normalização em `art/ui/recorte-v1/provenance.json`. Não foram utilizadas ilustrações de franquias como entrada.

O script de produção recorta as fontes revisadas, limpa guias muito fracas, normaliza pigmentos e alpha, monta os segmentos e exporta as duas resoluções. Os traços vêm das fontes desenhadas; máscara de wipe e retículas são dados numéricos. Junções de molduras retas recebem reparo de alpha; balões usam um quarto da arte espelhado para fechar curvas e períodos sem fantasmas na emenda. Pinceladas esticam somente o miolo, sem repetir as pontas.

As molduras usam cantos de 48 px lógicos e trechos centrais de 64 px. Balões têm altura mínima de 160 px para não esmagar os lóbulos/pontas. A camada `recorte_ink_frame.gd` é decorativa, ignora input e conserva os cantos também ao escolher a fonte 2×. Geometria de preenchimento e conteúdo permanecem no pai.

`recorte_ink.gd` carrega texturas sob demanda e mantém cache. `recorte_splat_sequence.gd` usa RNG local com semente e saco de variantes por família, sem repetir a fonte anterior na troca de sacos; rotação e espelhamento vêm da mesma sequência. Não altera o RNG do combate, economia, rede ou saves.

## Conferência realizada

- Importação real no Godot 4.7.2, renderer Compatibility/OpenGL, RTX 5070; sem erros ou avisos nos logs da rodada final.
- Prancha nativa renderizada em 1920×1080: `godot/assets/ui/recorte-v1/mockups/kit-tinta.png`.
- Doze vistas nativas de redimensionamento: nove molduras/balões e três pinceladas; larguras 200, 400, 800 e 1600 px e uma linha adicional com fonte 2×. Vistas retas/pinceladas em 1920×1080; balões em 1920×1280 para exibir sua altura mínima completa.
- Inspeção dos 128 PNGs: dimensões, presença de conteúdo, transparência, miolo vazio das molduras e máscara grayscale opaca com centro preto. Comparação dos quatro cantos nas quatro larguras confirmou pixels idênticos nas fontes 1× das 12 peças.
- Reporte reproduzível: `documentation/evidence/pip63/asset-preflight.json`. Capturas ao lado, `stretch-*.png`.
- A revisão visual encontrou e corrigiu cortes de fonte, lacunas em bordas, emendas não periódicas, compressão excessiva de balões e repetição indevida de pinceladas.

Não foram executadas suítes de gameplay, seguindo a orientação para não rodar testes sem pedido. Inspeção de arquivos, importação e renderização do laboratório não equivalem a homologação completa da campanha ou teste físico de controle.

## Limites e aprovação

O kit ainda precisa da aprovação visual do responsável, conforme o terceiro critério da PIP-63. A prancha é um resultado concreto para essa avaliação; não foi marcada como aprovada em nome do usuário. A tarefa permanece em andamento com os dois critérios técnicos atendidos.

As bordas de emoções são traços desenhados com alvo de 4 px, não linhas matematicamente uniformes. Arquivos 2× são exports normalizados; texturas grandes preservam o detalhe existente na fonte gerada e não devem ser interpretadas como desenho nativo 4K. A situação fica registrada na procedência.

Sem push, deploy, publicação Steam/Render ou migração de banco. Nenhuma substituição automática de assets da campanha.

## Abrir para revisar

No Godot, abrir `res://assets/ui/recorte-v1/components/demo_kit.tscn` e executar a cena (F6). **INSPECIONAR 9-PATCH** mostra as quatro larguras e o seletor de peças; **OUTRO RESPINGO** percorre a sequência visual com semente 63. A cena não inicia uma sessão de campanha.

Produção: `node scripts/build-recorte-ink.mjs`. Após importar/renderizar novamente as capturas, inspeção: `node scripts/inspect-recorte-ink.mjs`. O segundo comando apenas lê os assets/capturas e registra o resultado técnico; não confirma aprovação artística.
