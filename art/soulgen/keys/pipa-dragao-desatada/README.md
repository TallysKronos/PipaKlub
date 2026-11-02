# Pipa-Dragão desatada — químico B no Soulgen

## Revisão 2 — spritelização pedida pelo dono

O preset ativo agora usa `cutout-rig-v2/`, `artRevision=2`: peças redesenhadas por image_gen no acabamento dos guardiões (Tufanocorte + Carcará como referências de renderização), preservando o químico B como identidade. Contorno escuro em degraus, sombras agrupadas, manchas e brilhos em blocos, menos linha fina e detalhe pequeno. Não é filtro nearest-neighbor aplicado à ilustração anterior nem promessa de pixel art em grade nativa única.

Oito partes, quatro rostos e seis ações foram reexportados na nova fonte: 145 frames/12 fps, nenhum pixel cortado na borda do atlas. A expressão de ataque substitui também o alpha da mandíbula dentro da janela facial para não duplicar a boca fechada; RGBA fora das janelas permanece idêntico. Testes ativos apontam para v2. A versão ilustrada v1 permanece arquivada, não é mais o preset ativo.

`prepare-sprites.py` extrai os onze componentes gerados e registra rostos; não inventa pixels ou recolore o desenho. Revisar o resultado interativamente antes de aprovar. Nenhuma integração no jogo. O editor arquiva o draft de artRevision anterior antes de abrir v2, preservando o rascunho em chave de histórico.

As notas abaixo registram a entrega ilustrada anterior; quando houver conflito, prevalece a revisão 2 acima.

Fonte de identidade: `origin/feature/retalho-bosque-d:art/creatures/pipa-dragao/quimico-b-v1/desatada-estudo.png`, criatura menor à direita. Cópia e hash preservados em `art/soulgen/campaign-redesigns-v1/references/pipa-dragao-git/`. Não usa a proposta azul descartada nem inventa nova espécie.

Mantidos: quadrúpede pesado cinza-lilás manchado, crista escura, olho âmbar, presas, tubos verdes com flanges no tronco, cilindro dorsal, peitoral ocre com símbolo, vela rasgada e rabiola com fitas ocres. A montagem foi derivada com image_gen nativo, seguida de recortes mecânicos; a arte original do Git não foi sobrescrita.

Oito partes independentes: torso, cabeça, quatro pernas, cauda completa e equipamento dorsal completo. Torso conserva tubos/flanges para não deixar mangueiras cortadas nas juntas. Cabeça normal e três expressões registradas em janelas fixas, sem alterar alpha/contorno externo. O rosto de ataque adapta a boca aberta gerada ao limite da cabeça normal; requer revisão de leitura no editor.

Seis ações em revisão: respiração cansada, passo pesado (`flight` é o ID técnico, **não voo canônico**), investida, dano, alívio/vitória e derrota. Impacto proposto em 0,8 s. 145 frames a 12 fps, sem pixels nas bordas de célula. Fonte RGBA possui fundo transparente: alguns visualizadores exibem RGB de pixels com alpha zero como fundo pintado. Não foi feita remoção de cenário por cor ou recoloração da criatura.

Abrir `http://127.0.0.1:5241/?preset=pipa-dragao-desatada`, ou botão correspondente em Projeto e biblioteca. Armazenamento isolado dos demais presets. Arquivos portáteis e prévia animada independente em `cutout-rig-v1/`. Não sobrescreve drafts da Retalho ou guardiões.

Verificado: estrutura, fontes, proporção, fechamento dos loops, rostos, marcador de impacto, fim de derrota, parentesco e encaixe dos pivôs a 30 amostras/s, atlas sem corte. Inspecionada a montagem nas ações e fundos claro/escuro. Corrigidos resíduos de recortes vizinhos e pixels transparentes no registro da boca. Topologia dos tubos e sobreposição das pernas seguem sujeitos à revisão do dono. Não é aprovação artística nem integração no jogo.

A forma sobrecarregada/amarrada e a sequência de libertação ainda não foram montadas. Este pacote é apenas a desatada já existente; não confundir com a forma de três almas. Sem alteração de atributos, dano, recompensas ou história.
