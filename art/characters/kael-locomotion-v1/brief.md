# Kael — repouso e corrida

Manter o personagem aprovado: cabelo azul penteado em pontas, jaqueta azul com faixas marfim e abas compridas, camiseta preta, fone ciano, calça cinza com faixa preta e botas de sola clara. Nenhuma troca de identidade ou de escala entre os estados.

- Grade 64×96, pivô 32,94, altura de referência 86 px, oito direções na mesma ordem da caminhada existente.
- Idle: pose neutra das referências já aprovadas, pés apoiados; respiração de 1 px com cabeça atrasada em relação ao tronco. Pernas/pés fixos. Dois ciclos de respiração na sequência de 2,2 s. Sem deslocar a figura inteira.
- Corrida: seis ciclos no vídeo-guia local de cinco segundos; contato, compressão, impulso e voo; braços dobrados e opostos às pernas, leve inclinação para a frente, cabeça consistente e abas com atraso. Selecionar um ciclo e limpar na paleta existente. Não acelerar a caminhada para fingir um novo desenho.
- Animações de item, salto e escada têm prioridade sobre a corrida. Diálogos, pausas e movimentos de cutscene não ganham velocidade.
- Movimento: caminhada atual mantida; corrida inicialmente 1,8×, sem stamina nova. Shift segurado no teclado, L3 para alternar no controle e botão visível de corrida no HUD. Preservar colisões, relevo e apoio do seguidor.

## Storyboard

Idle: alto → tronco cede → cabeça acompanha → tronco volta → repouso; repetir sem salto de apoio. Corrida: contato D → compressão D → impulso D → voo D → contato E → compressão E → impulso E → voo E. Conferir tanto a silhueta parada quanto a emenda 8→1.

Referências: oito imagens em `references/`, copiadas das referências originais do Kael que deram origem aos vídeos de caminhada. Workflows e prompts em `workflows/`, exclusivamente MiniMax H3 local, sem nodes de API paga. Aseprite headless é usado para desenho/revisão/exportação dos pixels e fontes editáveis.
