# Kit da fachada — recortes complementares

15/11/2026. A pintura da etapa 2 foi aceita para continuar. Este kit prepara as camadas da fachada para montagem e ordenação no cenário, sem substituir a casa atual ainda.

## Conteúdo

Sete PNGs RGBA de 654 × 601 px, com âncora comum em (326, 540). O canvas compartilhado mantém o alinhamento sem compensações diferentes por peça. Os recortes são complementares e remontam a pintura exatamente. Não contêm as superfícies ocultas atrás da varanda, vegetação ou móveis, portanto não são blocos genéricos para construir outras casas.

O manifesto `kit.json` registra ordem sugerida, pegadas propostas e limites de conteúdo de cada recorte. As pegadas são referências de montagem, não colisores já aprovados. A fonte editável está em `../fontes/kit-nativo.aseprite`, com sete camadas de recorte, uma fonte oculta e uma camada vazia do documento.

## Passada de pixel

A importação no Aseprite ajustou a fonte de 1308 × 1202 para 654 × 601. A remoção do fundo preservou os contornos escuros e as áreas internas. A paleta passou a 45 cores, usando as rampas da ficha e dois acentos amarelo-esverdeados para conservar as flores e folhas do concept. Foram agrupados 2644 pixels com vizinhança dominante para reduzir manchas isoladas. Uma correção localizada posterior limpou as manchas da porta e das placas da calçada, preservando o vidro, a moldura e os puxadores.

É uma edição assistida por ferramentas de pixels no Aseprite headless, com seleção de regiões e cores por código. Não houve desenho manual com mouse. A saída original e a pintura aprovada permanecem intactas.

## Conferências executadas

- Remontagem dos sete PNGs com zero diferenças em relação a `../kit-remontado.png`.
- Zero sobreposição entre pixels opacos dos recortes.
- Zero pixels com alpha parcial e 45 cores opacas no conjunto.
- Inspeção em fundo claro e escuro, em escala 1×, ao lado do recorte real do Kael de 70 px em `../kit-convivencia.png`.
- Revisão independente da conversão. A primeira versão recebeu um bloqueio pelas manchas da porta e calçada. A comparação com a versão corrigida escolheu a nova, com 8,8/10 e bloqueio resolvido. Evidências em `../revisao/a.png` e `b.png`.

As medidas verificadas estão em `qa.json`. A ferramenta `validate` não está exposta pelo conector Aseprite nesta sessão. A conferência de recortes foi executada no Godot pelo gerador abaixo.

```powershell
& './.local/godot/Godot_v4.7.2-stable_win64_console.exe' --path godot --script tools/casa_kael_v2_kit_review.gd --rendering-method gl_compatibility
```

## Calibração antes da integração

A pintura preserva o design aprovado, mas não é um decalque métrico do blockout. A porta resulta em aproximadamente 75–80 px nesta conversão, contra os 92 px propostos na ficha. A posição relativa do portão também difere da coordenada canônica u 4,4. A prévia de convivência demonstra densidade e leitura, não resolve esses dois desvios.

Antes de substituir o runtime, ajustar esses acessos aos apoios do mapa e conferir as faces no lote 8,6 × 7,2. Não esticar a imagem inteira com escalas independentes para esconder o desvio. Depois separar o estado aberto do portão, conectar a entrada ao checkpoint existente, substituir a decoração antiga que se duplicaria e conferir a oclusão do Kael nos dois lados do muro.

Colisões, caminhada, entrada na casa, retorno de campanha e montagem no mapa ainda não foram alterados ou testados. Os interiores permanecem no blockout.
