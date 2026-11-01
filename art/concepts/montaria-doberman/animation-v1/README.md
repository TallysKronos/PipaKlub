# Montaria com Kael — animação baseada nas edições do usuário

## Regra para os próximos lotes

Gerar somente S, N, E, SE e NE. Derivar W ← E, SW ← SE e NW ← NE por
espelhamento horizontal de cada célula, mantendo a sequência e os tempos.
Refletir pivôs, encaixes e máscaras junto com a arte. Os jobs já enviados
deste lote ficam registrados como histórico; não são o modelo de custo para
os próximos. Ver a regra de espelhamento em `MANUAL-DE-ASSETS.md`.

`sources/` conserva uma cópia exata do PNG da montaria, do PNG retocado do
Kael e do manifesto de encaixes no início desta geração. `manifest.json`
registra SHA-256, sementes nos workflows, IDs dos jobs e estado real de cada
clipe. Não substituir essas fontes se houver novas edições: abrir outra versão.

`references/` contém oito composições sem guias de editor, com o encaixe,
as máscaras de perna e o ângulo distante aplicados como no Godot. Fundo
magenta uniforme para permitir recorte posterior. As imagens são composições
determinísticas dos PNGs editados, não desenhos novos.

## Fluxos locais

Foram preparados três fluxos por orientação (idle, walk, run): 24 opções.
Preparado não significa executado. O estado de execução está no manifesto.
Começar pela caminhada sudoeste para revisar anatomia, apoio e estabilidade
antes de consumir GPU no restante do lote.

Após a revisão da primeira caminhada, foram enviados **16 clipes**:
caminhada e corrida nas oito direções. Os oito idles continuam apenas preparados.
`index.html` é a galeria de acompanhamento: mostra referências enquanto o
respectivo vídeo não chega e passa a oferecer reprodução quando recolhido.
Atualiza a cada 30 segundos enquanto houver trabalho pendente.

- MiniMax H3 instalado, sem nós de parceiro ou créditos de API.
- 512 × 512, 124 frames a 24 fps, 16 passos, sampler res_multistep/beta.
- Referência editada no condicionamento e como guia inicial e final.
- Câmera fixa, movimento no lugar, quadril preso ao assento e cores constantes
  são restrições do prompt; não são garantias do modelo.

`tools/soulgen-studio/run-mount-motion.mjs <URL local descoberta> submit|status|collect <ação-direção>`
envia um clipe, consulta ou recolhe seus resultados. O cliente verifica a fila
antes de enviar, confirma modelos/nós instalados e conserva o histórico.

`queue-mount-motion.mjs <URL>` enfileira os clipes restantes de caminhada e
corrida, aceitando trabalhos já presentes somente quando pertencem a este
manifesto. `watch-mount-motion.mjs <URL>` acompanha os jobs enviados, recolhe
MP4/histórico e cria folhas de contato. Ele não aprova nem integra arte.

Os vídeos originais ficam em `video-original/`. Examinar quadros e loops antes
de extrair spritesheets, remover fundo e integrar. Esta pasta não altera
automaticamente as imagens ou as animações usadas pelo jogo. Os PNGs editados
do usuário continuam sendo as fontes ativas.
