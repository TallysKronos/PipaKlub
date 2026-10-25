# Assinaturas: Rabbito e primeiro boss

Atualização: a revisão manual de combate e a calibração posterior estão em `revisao-combate-demo-2026-10-25.md`. As pendências abaixo descrevem a primeira entrega das faixas.

Entrega local, sem alteração de banco ou publicação. Usa um componente de faixa diagonal para todos os Pipamons, com máscara de imagem e texto DOM. Nesta versão só existem duas artes e dois golpes, conforme o escopo pedido.

## Identidade e apresentação

Rabbito: **Pulo do Elo**, papel turquesa e creme, orelhas com bambu, nós e remendo. Lacertubo: **Ruptura dos Canos**, papel laranja/turquesa e estrutura de PVC creme. Ilustrações 2D originais geradas via image_gen a partir dos modelos aprovados; referências, dimensões e notas em `assets/ui/signatures-v1/README.md`.

Faixa ocupa cerca de 26% da altura da tela. A arte é recortada pela silhueta compartilhada e desaparece gradualmente sob o texto, sem esticar o PNG. A entrada dura 820 ms. Não pausa a simulação nem intercepta clique ou teclado. Movimento reduzido elimina o deslocamento. Os PNGs são pré-carregados.

## Integração de combate inicial

- Rabbito: T, botão próprio ou gatilho direito. Custa 40 de energia, recarga 24 s, preparação 1,4 s, dano-base 38 na armação, ajustado por ataque/defesa.
- Lacertubo: automático, primeira oportunidade após 6 s, recarga 20 s, preparação 1,5 s, dano-base 44 na armação.
- Para ambos, a ativação exige alvo vivo a até 440 unidades. A posição é marcada no início: o impacto não segue a fuga do alvo. Sair do círculo (raio 85/95), esquivar ou acertar a guarda permite evitar o golpe. A faixa sai antes do fim da preparação.
- Durante a preparação, o atacante tem movimento reduzido e não usa ataque comum, esquiva, guarda ou habilidade simultaneamente. As habilidades anteriores continuam disponíveis fora desse período.
- O servidor calcula custo, temporizadores e dano. O cliente só envia a intenção; o contador de ativações identifica cada anúncio sem repetir a cada snapshot.

Esses números são uma configuração inicial e não constituem balanceamento aprovado do boss no nível 15.

## Revisão realizada

Builds Worker e Pages; sintaxe da engine, do cliente e do JS compilado; revisão visual das duas composições no navegador a 1131 × 884. Prévia em `/local/signatures` no servidor local, com o mesmo componente usado no jogo, claramente identificada como prévia sem combate.

Sem suíte automatizada, conforme preferência do usuário. Ainda não revisados em partida os novos impactos, a janela de defesa, controle físico ou comportamento sob latência. Nenhuma alegação de balanceamento final.
