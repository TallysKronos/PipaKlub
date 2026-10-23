# Kael — avatar modular v1

Esta é a revisão inicial preservada para rastreabilidade. O preset atual usa a [revisão 2, com quatro direções e ombros revisados](../kael-v2/README.md).

Abra `http://127.0.0.1:5245/?preset=kael` na prévia desta sessão. No servidor padrão (`npm run studio:sprites`, porta 5240), use **Projeto e biblioteca → Abrir Kael · Avatar modular**. O parâmetro `?preset=kael` também funciona lá.

## Entrega

Oito peças independentes: cabelo, cabeça, tronco/roupa, dois braços, duas pernas e mochila. Preset ilustrado preserva cabelo azul, jaqueta azul, camiseta escura e tênis com detalhes dourados. O jogador poderá assumir outra aparência: Kael é a opção inicial.

Quatro tons de pele, dois cortes, quatro cores de cabelo e duas jaquetas: **64 combinações**. Os 45 PNGs incluem pele em cabeça, pescoço, mãos e tornozelos. Paleta de pele é aplicada em regiões da anatomia; não é um filtro global sobre o personagem. Cabelo e roupas possuem texturas próprias. Não há escolha de gênero nem formato corporal nesta entrega.

Seis ações: repouso, caminhada frontal, corrida frontal, aceno, recuo e comemoração. Não existem expressões faciais alternativas ainda: o rosto continua neutro. Ombros, pescoço e cabelo têm referências anatômicas auditáveis; todas as opções preservam pivôs, profundidade e curvas.

`kael.soulgen.json` é um projeto portátil com os PNGs incorporados. `rig-data.mjs` é o preset de autoria com caminhos locais. Salvar projeto mantém a aparência selecionada e a biblioteca de alternativas; exportar atlas/runtime gera o visual atual. A recuperação do preset local usa caminhos locais para evitar exceder a quota de armazenamento com as texturas incorporadas. Mantenha o JSON como cópia independente.

## Escopo de integração

Esta entrega está no **Soulgen Studio**, com vista frontal. Não substitui o sprite de quatro direções no jogo nem persiste aparência na conta. Antes dessa integração, produzir e auditar costas e perfis com os mesmos slots; compartilhar a seleção de aparência entre vistas; conectar o perfil e salvar a seleção de forma validada. Não espelhar uma frente para simular costas.

Não reutilizar os pivôs de criaturas. Não esticar recortes para compensar proporção. Peças substitutas devem seguir as caixas de montagem do preset; o cabelo sempre herda a cabeça. O contrato mede conexão de pivôs, não prova cobertura de pixels: conferir extremos no fundo claro e escuro.

## Fontes e reprodução

Arte produzida com a ferramenta nativa `image_gen`, usando `assets/hub/praca-v1/kael.png` como referência de identidade. Prompts completos em `prompts.json`; fonte selecionada preservada em `source/parts-generated.png`. Recorte, registro e mapeamento de paletas determinísticos em `scripts/build-kael-avatar.mjs`. A transparência da fonte foi preservada, sem fundo pintado ou remoção por chave de cor.

Execute `node scripts/build-kael-avatar.mjs` para reconstruir. Relatório de tamanhos, recortes e alpha: `asset-report.json`. Testes: `node --test tools/soulgen-studio/kael.test.mjs tools/soulgen-studio/model.test.mjs tools/soulgen-studio/workflow.test.mjs tools/soulgen-studio/editor.test.mjs tools/soulgen-studio/server.test.mjs`.
