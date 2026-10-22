# Eremor v3 — nó no peito e expressões registradas

22/10/2026. Correção solicitada a partir da captura em que o nó estava à frente do antebraço e da ausência de expressões.

## Nó

O nó continua filho do tronco, com posição (78,118), largura 50 e pivô (103;138,177). Foi deslocado para o peito entre os braços e reduzido para continuar legível sem ocupar o antebraço. Profundidade 4, abaixo do braço próximo (6) e da cabeça (5), acima do tronco (3). A passagem do braço à frente encobre o nó naturalmente; não há mudança artificial de profundidade durante a ação.

A referência anatômica registra `knot` atrás de `armNear`. O audit avisa se essa ordem for invertida. A montagem anterior foi mantida nos projetos/exportações v2.

## Expressões

Arte criada com image_gen a partir da cabeça existente. Fonte em `source/expressions-generated.png`, prompt em `source/expression-prompt.json` e registro em `prepare-faces.py`. O script alinha e compõe a arte pintada na região dos olhos, preservando focinho, mandíbula e toda a anatomia externa. Não desenha olhos por código.

| Ação | Expressão | Intervalo |
|---|---|---|
| Repouso e planagem | Neutra | Ação inteira |
| Golpe | `fierce`: olhar concentrado | 0,24 até antes de 1,80 s |
| Dano | `hurt`: olho fechado e tenso | 0,03 até antes de 0,90 s |
| Vitória | `happy`: olho curvo e relaxado | 0,35 até antes de 2,70 s |

Fora das janelas, a cabeça retorna à neutra. Todas as cabeças têm 347×277 px, mesmo retângulo de desenho, pivô e canal alpha. Janela de verificação: (52,50,144,130), em pixels da cabeça. A máscara interna segue a região dos olhos para não modificar a marca da testa. A expressão substitui uma textura; permanecem sete chamadas de desenho, sem uma cabeça ou face extra sobreposta.

`face-validation-v3.json` comprova alpha idêntico e zero alterações fora da região registrada. O auditor nativo do Soulgen repetiu a comparação sobre as imagens realmente carregadas: alpha e pixels externos idênticos nas três expressões.

## Verificações

- 31 testes passaram no conjunto Soulgen/Carcará. O novo teste verifica ordem real das chamadas de desenho, uma única cabeça, expressão correta no instante do impacto/dano/vitória e retorno à neutra no final.
- Testes geométricos a 60 Hz e revisão anatômica permaneceram sem desvios fora da tolerância após reposicionar o nó.
- Navegador: revisão de repouso, preparação do golpe, dano em 0,14 s e vitória em 1,30 s; troca de expressões exibida no estado da bancada e na prévia. Nó visível no peito em repouso, encoberto quando o braço passa à frente.
- Exportação pela interface real: `exports/eremor-v3.png` + `exports/eremor-v3.atlas.json`, 163 quadros, 2048×5376 px, zero quadros vazios ou cortados. Verificação reproduzível: `audit-export.py 3`.
- Projeto portátil: `eremor-v3.soulgen.json`, também salvo pela interface do editor. Sete peças, dez imagens incorporadas e cinco ações. O alias `eremor.soulgen.json` aponta para a revisão atual.

Inspeção em `review-faces-v3.png`, `review-poses-v3.png`, `review-hurt-v3.png` e `review-happy-v3.png`. A entrega é local ao Soulgen; não altera o catálogo, a economia, o banco, a tela inicial ou o overworld do jogo. Aprovação técnica não substitui a revisão artística do responsável.
