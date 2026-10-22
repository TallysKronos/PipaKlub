# Pipamons das referências do anime — revisão v1

Dois spritesheets 4×4 com 16 poses cada, adaptados com image_gen para ilustração 2D de papel vivo. Os identificadores urso-menta e olho-origami são provisórios: nomes oficiais não foram informados.

**Status: precisa de limpeza. Não aprovado para produção.** A geração manteve resíduos coloridos e brancos nas bordas, inclusive após duas tentativas de correção. O validador de atlas rejeitou a margem mínima de 8 px (quadro 00: 3 px no urso e 0 px no ciclope). Os JSONs são mapas de recorte de rascunho, não certificados de qualidade. A inspeção visual também identificou variação de escala e pivô que deve ser revista após a limpeza. Nenhum arquivo foi integrado, publicado ou adicionado ao inventário.

## Conteúdo

- `revisao/`: PNGs originais da versão com melhor composição, JSONs com recortes inteiros, tempos, prévia animada e relatório de pendências.
- `sources/`: todas as versões preservadas, sem alteração de pixels.
- `generation-log.json`: prompts e referências usadas.
- `pipamons-anime-revisao.zip`: pacote portátil da pasta revisao.

## Mapa das animações

| Estado | Quadros (base zero) | Durações em ms | Reprodução |
|---|---|---|---|
| Repouso | 00–03 | 220, 150, 220, 220 | Loop |
| Voo | 04–07 | 130, 110, 130, 110 | Loop |
| Ação | 08–11 | 160, 180, 110, 180 | Uma vez, volta a repouso |
| Dano | 12–13 | 150, 210 | Uma vez, volta a repouso |
| Vitória | 14–15 | 300, 420 | Loop |

As ações são poses de animação; não definem novas regras de combate ou poderes. Ambos os PNGs medem 1254×1254, RGBA com transparência. As células alternam 313 e 314 px: usar os retângulos do JSON, nunca assumir 320 px. O pivô 0,5/0,5 é inicial e ainda exige revisão anatômica. A prévia mantém escala fixa entre os quadros.

Abra `preview.html` na pasta extraída para revisar animações. Fontes de identidade: os dois PNGs fornecidos pelo usuário (03f9e870 e 404ef44b). Direção de estilo: referências e instruções da skill Pipamonsters.
