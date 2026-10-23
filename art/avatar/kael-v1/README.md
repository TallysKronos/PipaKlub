## Correções da auditoria v3 · 23/10/2026

Estado atual em [CORRECOES-V3.md](CORRECOES-V3.md): desembarques compartilhados, assento mais profundo, casca nativa com cores chapadas, escada redesenhada, rampa de cabelo Preto revisada e bancada com zoom/rolagem e campos em uma coluna. As fontes de caminhada v5 substituem as v4; eliminam os avisos de altura, mas a alternância anatômica ainda precisa de revisão artística. Não considerar a ausência de avisos técnicos uma aprovação final da caminhada. Suíte atual: 442/443, com a reprovação geométrica histórica da sala preservada. Sem deploy.

As seções abaixo registram as versões anteriores.

---

## Revisão visual v2 · 23/10/2026

A descida agora segue a abertura da escada e recorta o personagem na borda do piso: ele não caminha para fora da plataforma. O móvel de apoio define a ordem de desenho; a cama permanece sólida durante a descida. São 280 ms de aproximação e 3,52 s nos oito degraus.

Sentar e levantar deslocam o contato gradualmente entre piso e assento. Clique no piso ou movimento solicita levantar e só libera a próxima caminhada ao terminar. A prévia também caminha até o sofá e a escada antes de iniciar a interação, sem teleporte de depuração.

Os 16 desenhos de andar e os 12 de sentar/sentado foram revisados. A pose sentada tem tronco ereto e pernas à frente. As alças frontais medem 34×34 na autoria, com âncora (17,12). A fase da caminhada acompanha a distância realmente percorrida e pausa quando parado. A alternância anatômica da passada ainda merece refinamento artístico: esta revisão não a certifica como final.

Sete móveis principais receberam cores mais chapadas: sofá, mesa de centro, mesa de jantar, cozinha, cama, guarda-roupa e escrivaninha. Piso, paredes, escadas e detalhes menores continuam com a arte anterior. As imagens preservam suas caixas nativas e âncoras, com escala uniforme; não houve deformação por colunas. Fontes e dimensões estão em `interiores-v2.json`.

Fontes geradas com a ferramenta integrada de imagens a partir da identidade do projeto: `source/andar-{se,ne}-v4.png`, `source/sentar-{se,ne}-v2.png`, `source/sala-flat-v2.png` e `source/quarto-flat-v2.png`. A preparação técnica separa componentes conexos, normaliza escala por sequência e associa a paleta. A evidência `revisao-v2-cenario.png` mostra o assento na sala; `revisao-v2-descida.png` mostra a oclusão pela abertura.

Validação: 441/442 testes aprovados, incluindo contatos, saída contínua do sofá, passos por distância e recorte restaurado após desenhar. Permanece a reprovação anterior de `home-layout.test.mjs`, que consulta o relatório geométrico histórico da sala. Build Worker, build Pages e `audit:world` concluídos. O auditor dos 52 desenhos não encontrou falhas de cabelo/mochila; o aviso sentado SE foi eliminado. Restam três avisos de altura na caminhada (2,2%, 3,5% e 2,9%). Não houve deploy nesta revisão.

Reprodução da revisão atual, na raiz: `node scripts/extend-kael-avatar.mjs`, `node scripts/build-kael-home-actions.mjs`, `node scripts/polish-kael-interiors.mjs`, `node scripts/audit-kael-avatar.mjs`, `node build.mjs` e `node build-pages.mjs`. O preparador de ações usa as fontes v2 por padrão; `--legacy-source` seleciona o conjunto anterior. Prévia local: `AVATAR_REVIEW_PORT=5248` com `node tools/avatar-studio/game-review-server.mjs` (em PowerShell, defina a variável via `$env:AVATAR_REVIEW_PORT='5248'`).

As seções abaixo são o histórico anterior à revisão v2, inclusive seus números de testes e limitações daquele momento.

---

## Integração de 23/10/2026 (anterior à revisão v2)

O pacote atual contém 52 desenhos: os 24 aprovados de parado/andar e 28 novos de subir, descer, sentar e sentado. Há três peças: cabelo, bolsa e alças. As quatro direções usam SE/NE desenhadas e espelhos SW/NW; escadas têm uma orientação desenhada e seu espelho.

O jogo consome os PNGs de runtime em assets/avatar/kael-v1, recolore por paleta e compõe as mesmas camadas do Studio. A abertura e a exploração usam esse avatar. Meu perfil permite escolher cores; a aparência fica salva neste navegador por conta, sem sincronização com o servidor. Ainda não há seleção de outros cortes de cabelo ou modelos de roupa.

A mochila mantém os encaixes originais dos 24 quadros e atraso de um quadro, limitado a 2 pixels de runtime para não descolar durante transições. A bolsa NE mede 60×64 na autoria. As alças SE ficam abaixo do rosto. A subida/descida dura 3,52 s: oito degraus de 16 px no runtime, quatro quadros por degrau. Sentar toca uma vez e passa ao loop sentado; mover-se ou escolher Levantar encerra o assento. O sofá usa altura de assento e ponto de contato próprios.

Verificação: conferencia-integracao.json inspeciona todos os 52 quadros, incluindo cabelo e mochila; os GIFs por ação permitem conferir movimento. A pose sentada SE ainda apresenta aviso de 3,1% de variação de altura; não há reprovação de pivô, paleta, cabelo ou mochila. A prévia usa o renderizador real da sala/quarto, sem conta ou banco: npm run review:avatar (porta 5247). A evidência revisao-no-cenario.png registra o assento alinhado e duas cores alteradas na interface.

Reprodução incremental: node scripts/extend-kael-avatar.mjs; node scripts/build-kael-home-actions.mjs; node scripts/audit-kael-avatar.mjs. Esses scripts preservam os desenhos e encaixes antigos. Não execute o builder v1 antigo para atualizar este pacote.

Validação de código: build Worker e build Pages concluídos; audit:world aprovado. Suíte completa: 437/438 aprovados, com a reprovação já existente em home-layout.test.mjs (geometria dos móveis / relatório Iso Studio). Após o ajuste final de levantar por teclado/clique, os 10 testes da abertura passaram novamente. Não foi feito deploy no Render nesta entrega.

As notas abaixo descrevem a entrega anterior de 24 quadros, antes desta integração.

---

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
