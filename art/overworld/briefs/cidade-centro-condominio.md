# Centro e Condomínio (Lajes): plantas próprias das partes A–C

Até 07/11 as seis partes eram cópias da planta da Feira do Largo com fachadas trocadas. Agora cada
parte tem planta própria, escrita por `tools/gerar-mapas-cidade.py` (determinístico) e compilada por
`tools/compilar-mapas.mjs`:

```
python3 tools/gerar-mapas-cidade.py
node tools/compilar-mapas.mjs kronasta-centro-a kronasta-centro-b kronasta-centro-c \
  kronasta-lajes-a kronasta-lajes-b kronasta-lajes-c
```

Eventos (rivais, saídas, chegadas) vêm da versão original versionada (`01e7fa0c`), então rodar o
gerador de novo não duplica nada. Âncoras da história resolvem para a célula andável mais próxima.
Só peças já existentes: `bambuzal-casa` (vira prédio do bairro; no Centro, a casa em 6,5 ganha
campanário), `feira-banca` (quiosque cívico), `arvore-grande` (dentro do que se anda; a `arvore`
comum some na frente do caminho), bancos, postes, vasos, flores, biruta, pipa-presa, lixeira.

Vista geral: `documentation/overworld/kronasta/captures/cidade-centro-condominio-geral.png`
(linhas: Centro A/B, Centro C/Lajes A, Lajes B/C).

## Centro

| Parte | Lugar | Estrutura (abrir → estreitar → abrir) | Marco |
| --- | --- | --- | --- |
| A | Praça da Matriz | Avenida entre dois terraços nível 1 (adro da igreja a oeste, casario a leste) → abre na praça; duas escadarias sobem aos terraços | Igreja com campanário; chafariz rebaixado com mureta ajardinada |
| B | Estúdio da Pipa TV | Largo da emissora com jardins → escadaria única → platô do estúdio (nível 1) com saída norte | Prédios do estúdio, antenas de vento, pipas do cenário |
| C | Arena do Centro | Largo → escadaria → arquibancada (nível 1) → segunda escadaria → ringue no alto (nível 2) | Arena (landmark) |

Itens: A 100 papel-seda escondido no adro, 101 cola no casario; B 102 linha no jardim oeste, 103
papel no platô; C 104 cola ao lado da arquibancada.

## Condomínio (Lajes)

| Parte | Lugar | Estrutura | Marco |
| --- | --- | --- | --- |
| A | Portaria e Praça | Avenida → muro com portão único (estreitamento) → praça interna com canteiros → escadas às torres (nível 1) | Quatro torres e a portaria |
| B | Clube e Piscina | Alameda térrea → escadaria → deck elevado (nível 1) em volta da piscina rebaixada | Piscina com muros de concreto até a água |
| C | Terraço | Saguão → escadaria → jardim suspenso (nível 1) → escadaria → cobertura (nível 2) | Arena da cobertura (landmark) |

Itens: A 105 linha na torre leste, 106 papel escondido na torre oeste; B 107 cola escondida no
jardim, 108 papel no jardim leste; C 109 linha no jardim suspenso.

## Água construída

Piscina e chafariz seguem a regra de `AGENTS.md` (sem retângulo de água como decalque): a água fica
no nível 0 e o piso em volta no nível 1, então os muros descem de verdade até a cota da água. Formas
retangulares aqui são estruturas construídas, de propósito.

## Conferência

- `audit()` do Mapa Studio sem aviso nas seis partes; nenhuma rampa sobre peça ou evento.
- Testes do Godot que passam por estas cenas: `kronasta_regions_checks`, `qa_jump_checks`,
  `champions_meeting_checks`, `endgame_story_checks`, `tyler_optional_checks`,
  `release_travel_checks`, `city_restoration_checks`.
- Revisado em captura de jogo (zoom 1) e vista geral.

**Não verificado:** detalhe ampliado (zoom ≥ 2) de cada boca de escada; versão em cores chapadas;
percurso automático completo andando por todas as escadas nos dois sentidos (a conferência de rampas
do Mapa Studio cobre a ligação de níveis, não a leitura visual).
