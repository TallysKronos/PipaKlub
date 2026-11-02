# Mormaço C — forma livre no Soulgen

Identidade existente recuperada de `origin/feature/retalho-bosque-d`: `art/creatures/mormaco/model-c-v1/prancha-c-livre.png`, opção C de areia/gêiseres escolhida pelo autor. Cópia e hashes em `art/soulgen/campaign-redesigns-v1/references/mormaco-git/`. Não confundir com Rabiolava nem substituir outras criaturas por causa dos nomes antigos do roteiro.

Abrir: http://127.0.0.1:5241/?preset=mormaco

Onze peças: torso com placas e duas bases, cabeça, quatro pernas, cauda orgânica, membrana de pipa, rabiola completa com três folhas e dois gêiseres independentes. Água/vapor não fazem parte do torso; as bases permanecem nele. Rabiola herda a membrana, sem duplicar a cauda orgânica. Grandes garras claras, corpo magenta, placas roxas, ventre ocre e olhos âmbar preservados.

Quatro cabeças completas (normal/ataque/dano/vitória) e seis clipes: idle, deslocamento, golpe, dano, vitória e derrota. ID técnico `flight` representa caminhada. Respiração movimenta as plumas de água por pequena escala vertical; golpe aumenta temporariamente os gêiseres. Isso é animação de produção proposta, não efeito de combate ou habilidade implementada. Não foram gerados vídeos.

Arte image_gen com contorno spritelizado, fonte integral em `cutout-rig-v1/source.png`. Extração por componentes alpha e registro completo das cabeças com nearest-neighbor em `prepare.py`; pequenas gotículas desconectadas da fonte não entram nas peças extraídas. Sem repintura por código. `build-rig.mjs` monta e exporta projeto local/portátil, atlas e prévia HTML. 145 frames a 12 fps sem tinta nas bordas.

Verificados estrutura, proporções das peças, seis juntas anatômicas, dimensões, loops e cabeças completas. Membrana/rabiola/gêiseres possuem hierarquia e pivôs de efeito, mas não entram na auditoria de juntas anatômicas. Poses renderizadas inspecionadas em fundos claro/escuro. Encaixes e movimentos aguardam revisão interativa do autor. A fonte magenta não é a forma possuída: a conversão desta será um projeto próprio após revisão da livre.

Sem código de jogo, stats, história ou push alterados. Construtor protege futuras edições importadas do autor por padrão. Para a correção narrativa mais recente, ver `campaign-redesigns-v1/DECISAO-CARRETEIS-DAS-SOMBRAS.md`; Grande Carretel permanece arquivado.
