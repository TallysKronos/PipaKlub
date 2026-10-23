# Kael v1 · Avatar Studio

Projeto editável: `kael.avatarstudio.json`. Abra a bancada com `npm run studio:avatar` e clique em **Abrir avatar Kael v1**. O projeto incorpora os PNGs, não depende de caminhos do computador de quem criou.

## Entrega

- 24 desenhos: parado (4 × SE/NE) e andar (8 × SE/NE); SW/NW espelham as direitas.
- Corpo com roupa padrão e cabeça sem penteado; cabelo e mochila são camadas independentes: cabelo preso à cabeça e mochila ao tronco. Não há recortes de braços girando no rig antigo.
- Paleta-chave do Studio: pele, cabelo, jaqueta, camiseta, shorts, tênis, detalhe e mochila recoloríveis. Um penteado e um modelo de roupa nesta entrega; outras silhuetas exigem desenhos próprios.
- Autoria em células 256 × 256, pivô (128,224); exportação em 128 × 128, pivô (64,112), alpha binário. A base sem cabelo tem 174 px de altura nominal; o penteado completa aproximadamente 192 px. A linha dos olhos da guia é uma referência, não foi forçada por deformação da cabeça.
- Parado: 180 ms/quadro. Andar: 100 ms/quadro. Corrida está vazia e não é anunciada como animação disponível no manifesto.

`assets/avatar/kael-v1/` contém base, camadas, manifesto e paleta em 1×. `kael-v1-avatar.zip` é o pacote portátil. `parado.gif`, `andar.gif`, `aparencias.png` e `previa-aparencia.png` permitem revisar o conjunto; `studio-aparencia.png` registra a troca de cores na ferramenta.

## Conferência e limites

Conferência dos 24 quadros: sem reprovações de dimensão, alpha, paleta, pivô ou âncora. Cabelo encosta na cabeça em todos os quadros, com a regra original do Studio. A revisão de limpeza também eliminou o aviso de altura presente nas folhas anteriores. A mochila é menor, fica acima da cintura e a borda do cabelo passa à frente dela. O relatório completo está em `conferencia.json`.

Foram reproduzidos os ciclos e comparadas as quatro direções na bancada. As prévias de camadas e aparência usam pixels do sprite de runtime com zoom inteiro, sem redução fracionária. Foram alterados pele, cabelo e jaqueta e exportado o pacote pela interface. A naturalidade da passada e a transição parado/andar ainda fazem parte da revisão artística; os testes técnicos não constituem aprovação visual. O pacote está marcado como `productionReady: false`. A integração com movimentação, seleção de aparência e saves do jogo não foi feita nesta etapa.

## Origem e reprodução

Identidade: `assets/hub/praca-v1/kael.png` do próprio projeto. Novos desenhos e camadas: ferramenta integrada de geração de imagens, usando essa referência e as guias do Avatar Studio. A silhueta do cabelo é reutilizada por direção para eliminar seu redesenho entre quadros.

Fontes selecionadas: `source/se-limpo.png` e `source/ne-limpo.png` fornecem os quatro parados e os oito passos de cada vista, redesenhados para remover a textura de pintura; as folhas `*-estudo.png` e `*-poses.png` são estudos anteriores; `source/camadas.png` fornece cabelo e mochila. `source/guia-andar.png` veio do Studio; `source/guia-poses.png` é uma guia técnica de poses. `source/se-andar.png` é um estudo anterior rejeitado por repetir a passada, preservado apenas como histórico.

Execute da raiz: `node scripts/build-kael-avatar-v1.mjs`. O preparador recorta células, aplica uma escala uniforme por folha, registra os pés e o centro do crânio e associa as cores aos grupos da paleta por região. Não inventa poses por rotação ou interpolação de peças. O conversor preserva highlights quentes na rampa de pele, em vez de confundi-los com branco dos olhos. O projeto anterior foi preservado em `revisao-anterior/`. A preparação de cores é uma etapa técnica: futuras roupas precisam de nova revisão das regiões, principalmente camiseta/jaqueta e pele/solado.

Testes da ferramenta: `node --test tools/avatar-studio/model.test.mjs tools/avatar-studio/kael.test.mjs tools/avatar-studio/server.test.mjs` (13 testes aprovados). O teste HTTP precisa de acesso ao loopback local.
