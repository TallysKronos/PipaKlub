# Rebicadas — estudos para skills de linha

Propostas de design, ainda sem implementação. A prancha visual é um sketch de gestos e trajetórias, não um contrato final de física ou balanceamento. Criada com image_gen; prompt em prompt.txt.

| Rebicada | Gesto proposto | Movimento no céu | Efeito condicional | Resposta do rival |
| --- | --- | --- | --- | --- |
| Puxão | Puxar com força e soltar | Descida rápida seguida de subida, em U | Janela de crítico durante a subida se a linha atingir o trecho vulnerável e cumprir alinhamento/ângulo | Sair do cruzamento ou esquivar na retomada |
| Chicote lateral | Puxada curta para um lado e soltura | Varredura lateral em S | Corte de flanco quando a linha encontra o alvo; direção importa | Recuar em profundidade ou mudar a altura; erro deixa recuperação |
| Estilingue | Sustentar tensão e liberar | Pequeno recuo, depois avanço rápido | Aceleração para buscar contato; carga não garante dano | Antecipar o avanço pela carga visível |
| Laço | Movimento circular do pulso | Volta curta para trocar o ângulo da linha | Nova oportunidade de cruzamento; não prende automaticamente o alvo | Interromper a preparação ou sair do arco |
| Folha solta | Ceder um trecho e retomar a tensão | Deriva descendente com recuperação lateral | Reposicionamento defensivo; sem ataque durante a queda | Pressionar o ponto de retomada |
| Duplo toque | Duas puxadas curtas em ritmo | Dois pulsos verticais em zigue-zague | Segundo pulso pode reduzir a proteção de uma guarda ativa se atingir a faixa correta | Quebrar o ritmo com esquiva ou reposicionamento |

## Regras a validar no protótipo

- O jogador precisa de indicação clara de preparação, liberação e recuperação.
- A skill de linha modifica a manobra e complementa a habilidade do Pipamon. Não atribui automaticamente espécie, classe ou raridade.
- Contato usa a geometria do modo de batalha: espacial em 2.5D, e não mera sobreposição na imagem. Trajetória da pipa e linha tensionada são objetos diferentes.
- Crítico e quebra de guarda exigem contato válido; nunca afetam todos os inimigos por apertar o botão.
- Folha solta é proposta de evasão por movimento, não invulnerabilidade automática.
- Valores de custo, carga, dano e recarga permanecem em aberto. Começar testando Puxão e Folha solta permite comparar ataque e defesa.
- Em tela sensível ao toque, o gesto deve ser feito num controle de linha dedicado para não conflitar com arrastar para pilotar. Alternativa inicial: botão de skill com apertar/segurar/soltar e direção selecionada.

Legenda: azul representa trajetória; coral representa linha rival; estrela marca contato válido. A página não altera o jogo, o banco ou a produção.
