# Cut-ins de assinatura v1

Atualização dos remakes: o banner ativo do Nozinho agora usa `creatures/remakes-soulgen-v2/nozinho-signature.png`, uma exportação da pose de impacto do rig aprovado. A primeira ilustração abaixo permanece como histórico. Não foi redesenhado o remake para o banner.

Imagens geradas com a ferramenta image_gen em 2026-10-25, a partir de identidades aprovadas do projeto. Não substituem os sprites nem os rigs existentes.

- Rabbito: referência `art/soulgen/keys/rabbito/color-rig-v2/source.png`. Arte original 1672 × 941, opaca, sem texto. Preserva papel creme, turquesa, olhos gráficos, varetas, nós e remendos. Prompt: close dramático 2D cel de face e torso em ataque, fundo azul profundo com vento turquesa, sem 3D/aquarela/UI.
- Lacertubo: referência `assets/creatures/lacertubo-v2/portrait.png`. Arte original 1774 × 887, opaca, sem texto. Preserva cabeça em cunha, vela dorsal, papel laranja/turquesa e estrutura de PVC creme. Prompt: close dramático 2D cel em três quartos, garra avançando, vento âmbar, sem anatomia orgânica de dragão/3D/UI.
- Nozinho: `nozinho.png`, 1254 × 1254, com transparência. Gerado via image_gen usando `assets/creatures/nozinho/sprites.png` como referência. Brief: criatura redonda feita de corda dourada trançada, orelhas em laço, rosto turquesa, olhos âmbar, punho projetado e laço conectado ao corpo; pose dinâmica em três quartos, contorno escuro e cel shading, vento turquesa, sem texto/UI/cenário. O novo PNG é ilustração do cut-in; os sprites aprovados são preservados. Fonte original preservada em `.codex/generated_images/01a1469a-fff7-79e1-8e15-5638d2f7a257/exec-0f918fd4-f72c-4d89-ab7e-eac8883b1b4c.png` no ambiente de criação.

Consumo: `manifest.json`, `src/signature-banner.js` e CSS. Uma única silhueta recortada e máscara de gradiente integram a ilustração à faixa, sem esticar a arte. Nome e golpe são texto DOM. Rabbito e Lacertubo são opacos; Nozinho preserva alpha. A máscara compartilhada integra as três composições.

Entrada de 820 ms; o preparo do golpe dura mais, deixando a arena livre antes do impacto. Movimento reduzido elimina o deslocamento. Não há pausa ou bloqueio de input causado pelo banner.

Correção v2 do Rabbito: `rabbito-v2.png`, editada via image_gen a partir da primeira ilustração. As duas orelhas agora partem da coroa da cabeça, com bases contínuas e bambu ligado à raiz. Removida a orelha isolada no alto à direita. A versão v2 é a usada no manifesto; a primeira permanece apenas como histórico de produção.
