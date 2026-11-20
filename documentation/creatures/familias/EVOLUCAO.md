# Evolução dos Soulmonsters (08/11/2026)

## Regra

| Estágio | Nível | Bônus nos atributos de batalha |
| --- | --- | --- |
| Criança (II) | início (forma da oficina) | 0% |
| Jovem (III) | Nv. 16 | +6% |
| Adulto (IV) | Nv. 32 | +12% |

- Quando o parceiro alcança o nível de uma forma seguinte da família, a evolução fica
  disponível. O jogador confirma na Equipe (botão "Evoluir"). Nada evolui sozinho.
- Quando a família tem mais de uma forma no estágio, o jogador escolhe. A escolha é definitiva.
- A evolução mantém o mesmo parceiro: id, nível, XP, condição e o nome dado pelo jogador.
  Se o nome era o da espécie, ele passa a ser o da forma nova.
- O bônus do estágio soma ao bônus de criação da oficina (até 12%). O teto é 24%.
- Um aviso no mapa ("Evolução disponível · abra a Equipe") aparece quando alguém pode evoluir.
- A cor da linha e as regras de família seguem a forma de origem (`evolution.gd` → `root`).

## Famílias ligadas (jogáveis hoje)

| Parceiro (modelId) | Criança | Jovem (Nv.16) | Adulto (Nv.32) |
| --- | --- | --- | --- |
| `basica` | Carcará | Caravento | Caramastro |
| `mata` | Mata Verde | Folhante | Verdestrama |
| `raio` | Raio de Sol | — | Solguarda |
| `azulao` | Azulão | Azulíneo · Azulume · Azulfazo | Azuláculo · Azulígero · Azultor |
| `rabbito` | Rabbito | Rastro dos Ventos | Mestre dos Fios · Tecelão da Aurora · Arauto da Tempestade · Conde da Última Hora · Velocista Relâmpago |
| `doberman-c` | — | Dóber | Dobrácula |

Lacertubo e Retalho não evoluem.

**Decisões provisórias, a confirmar:**
- A cadeia do Rabbito usa as hipóteses III/IV do plano de povoamento.
- Raio de Sol ainda não tem forma jovem.
- No Azulão, qualquer jovem pode ir para qualquer adulto.

## Arte provisória

As formas evoluídas usam as imagens brutas dos concepts:
- o fundo liso do concept é recortado;
- cada forma vira um quadro só, como o Veskoro;
- os arquivos ficam em `godot/assets/campaign/evolucoes-v1/`.

Cada forma ganha uma entrada `combat` no `content.json` (marcada `provisional`), usada pela
batalha, pela Equipe, pelo mapa e pelos cartões.

Para trocar pela arte final, substitua o PNG ou a entrada `combat` da forma e mantenha o id.
No Azulão, as formas com fundo escuro brilhante ficam com um leve halo no recorte.

## Arquivos

- `tools/package-evolucoes.py`: lê o plano de povoamento e as cadeias e gera:
  - `godot/assets/campaign/evolutions.json`;
  - os PNGs;
  - as entradas `combat`.

  Para ligar mais famílias, acrescente a cadeia em `CHAINS` e rode o script de novo.
- `godot/scripts/campaign/evolution.gd`: regras (`options`, `evolve`, `bonus`, `art`, `root`).
- `godot/scripts/campaign/front_end.gd`: botão na Equipe, tela de escolha, confirmação,
  revelação e aviso no mapa.
- `godot/scripts/campaign/encounter_model.gd`: bônus do estágio nos atributos.
- `godot/tests/evolution_checks.gd`: cadeias, níveis, ramos, nome, bônus, arte e gravação no save.
