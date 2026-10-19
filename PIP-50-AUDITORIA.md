# PIP-50 · Auditoria e direção de interface

Base auditada: `feature/ui-kit-consistente` (commit 9446300), em 1280×720, com conta nova (abertura) e conta antiga (quintal). Capturas reproduzíveis em ambiente local (`LOCAL_TRADE_SLOT=p50-audit node scripts/local-trades.mjs`).

## Direção: o PipaKlub como guia de navegação

O jogador não navega por botões; navega **puxando a linha**. A seleção é uma pipinha presa por uma linha, que se move até a opção focada, como quem dá linha e recolhe. Papel, bambu e rabiola continuam como matéria-prima, mas aplicados com hierarquia:

| Papel na tela | Linguagem | Uso |
|---|---|---|
| **Informação** | Texto sobre papel, sem moldura de botão | Nomes, descrições, números, objetivos |
| **Opção navegável** | Tipografia (Lilita One) sem caixa; foco = pipinha + linha + amarelo de sol | Menus, listas, escolhas de diálogo |
| **Item colecionável** | Slot de papel preso com fita; foco = anel amarelo; equipado = selo verde; bloqueado = sépia + cadeado | Parceiros, Dex, mochila |
| **Comando** | Glifo do dispositivo + verbo, no rodapé | Confirmar, voltar, detalhes, abas |
| **Ação principal única** | Fita laranja do kit, uma por tela no máximo | "Voar", "Equipar" quando não há rodapé |

Referências usadas como estudo, não como modelo visual: menu inicial de Hades (arte protagonista e poucas opções tipográficas), diálogo de Hades (retrato e avanço discreto), lembranças de Hades e depósito Digimon (grade navegável e painel de detalhe). Paleta, fontes e materiais continuam os do PipaKlub (papel creme, terracota, azul-petróleo, verde de quintal e amarelo de sol).

## Matriz de telas

| Tela | Informação | Seleção | Comandos | Problemas encontrados |
|---|---|---|---|---|
| Entrada (visitante) | Marca, descrição | Treino, Amigos, Regras | Entrar | Botões com rótulo quebrando em duas linhas ("TREINO LIVRE"); três botões com o mesmo peso |
| Abertura (quarto/TV) | Fala, cena | TV, Desenhos, Mesa (texto solto) | Continuar depois, Examinar · E | Escolhas parecem texto, comandos parecem as escolhas; letras de 11–12 px; faixas pretas laterais em 16:9 |
| Quintal | Perfil, XP, missão, moedas | Destinos do cenário | Trilho de 5 ícones, engrenagem, "Caminhar até…" (select), "Aproxime-se" | Select de formulário para andar; trilho e engrenagem duplicam o menu; botão desabilitado ocupa espaço |
| Diálogo do Sr. Assis | Título, fala | — | Uma fita ("Conhecer os parceiros") | Sem retrato nem nome destacado; a fita ornamentada é o elemento mais forte da tela; cobre a cena inteira de baixo |
| Menu principal | Título | Seis blocos | "Voltar ao quintal" (fita), dica de teclado | Blocos com moldura pesada parecem botões de app; voltar como fita; dica só de teclado |
| Opções | — | Lista | — | Cada opção é uma fita de largura total: nove botões iguais empilhados |
| Mochila | Rabiolas | Cartões | Duas fitas laranja iguais | Duas ações principais com o mesmo peso |
| Missões | Trilhas e progresso | — | Duas fitas laranja | Idem; progresso como texto corrido |
| Parceiros | Detalhe, nível, atributos | Grade 3 colunas | Busca (campo), filtro (select), Equipar, Histórico | Campo de texto e select exigem mouse/teclado; detalhe com rolagem; ações em fita no meio do painel |
| Pipa Dex | Registro, história | Grade 3 colunas | Busca, filtro, "Animação" (select), Pausar, Reiniciar | Controles de depuração de animação expostos ao jogador |
| Combate | Linha, energia, tempo, placar | — | Leque de ações | Painéis do jogador e do placar maiores que o necessário; linha "Treino local · WASD / arrastar" fixa |
| Pausa | Aviso | Rebicada (select) | FPS, 3 ícones, Continuar, Regras, Sair | Select; números técnicos (fps) na pausa |
| Resultado | Ranking | — | Jogar de novo, Voltar | Abre por cima da pausa quando ela está aberta (sobreposição de camadas) |

## Regras que o piloto aplica

1. **Elemento não interativo não imita botão.** Textos, títulos e números ficam sobre o papel, sem moldura.
2. **Foco único e visível desde a abertura** (pipinha + linha + amarelo), diferente de passar o mouse (realce leve), selecionado (sublinhado de linha) e equipado (selo).
3. **Rodapé contextual** com glifo do dispositivo e verbo. Os glifos trocam entre teclado, Xbox e PlayStation conforme o último dispositivo.
4. **Voltar fecha só o nível atual** e devolve o foco à opção de origem.
5. **Busca e filtros sem teclado**: filtros viram abas (LB/RB ou Q/E); busca fica num comando opcional (Y / F).
6. **Detalhe acompanha o foco**; equipar exige confirmação explícita.
7. **HUD de combate compacta** nos cantos, sem cobrir pipas, linhas ou o cruzamento.
8. **Movimento reduzido**: a pipinha salta sem animar; nada pisca.

## Piloto (etapa 2)

Quatro superfícies no mesmo sistema, para revisão antes de expandir: menu principal, diálogo do Sr. Assis, coleção de parceiros e HUD de combate. Ligado por padrão nesta branch; `?classico` no endereço volta ao visual anterior para comparação. Nenhuma regra de jogo, economia ou autoridade do servidor muda.
