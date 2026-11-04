# Jardim das Pipas — relatório da planta, 29/10/2026

**Entregue:** brief, planta Tiled ampliada, JSON de revisão do Godot, referências do Mapa Studio, kit de parque compatível, proposta visual, oito capturas do Godot e conferência de acessos. **Estado: planta conferida e kit em revisão; arte final e integração narrativa pendentes.** Não substitui o fluxo oficial da campanha nem modifica saves.

## Continuação visual

O coreto foi trazido como asset estático, sem código, da revisão fixada `18dec6b87808a45ec23853ff4eb526c37a331b9a` da branch de história. O subconjunto compatível e a origem dos arquivos estão em `art/overworld/kits/parque/FONTES-REMOTAS.md`. O kit novo usa somente os dados consumidos pelo renderer existente; não traz os posicionamentos de folhagem da antiga planta 24×16, shaders ou lógica de outra branch.

As superfícies manchadas foram substituídas por **148 SVGs nativos editáveis**, em cinco materiais e oito pares de transição com 16 máscaras cada. São cores planas, detalhes discretos e continuidade sem contorno de grade intencional. Um sangramento de 0,7 px na rasterização reduz as frestas transparentes entre losangos, sem mover vértices de colisão. Muros reaproveitam a família de pedra do kit local Morro. A árvore ID 19 foi deslocada para (2,10), liberando a leitura do coreto; o auditor do mapa voltou a passar com 1.027 células e zero avisos.

Conferência específica do kit: **792 verificações, zero falhas**; caminhos, correspondência fonte/Godot, dimensões, alpha real das peças, máscaras e pegada do coreto. `kit-conferencia.json` registra o resultado. Godot voltou a importar e capturar sem erro; overworld repetido após a alteração da planta: 38.883 verificações, zero falhas. Nenhum script do jogo foi alterado nesta continuação.

Proposta de pintura: `art/overworld/conceitos/jardim-nina-v1/proposta-de-acabamento.png`, gerada com `image_gen.imagegen`; prompt e referências ao lado. Ela **não passou pelo aceite de alinhamento de 4 px** e não foi recortada para tiles ou usada como fundo. O arquivo mostra direção de arte, enquanto as capturas Godot mostram o que foi efetivamente montado.

## Mudanças

- Planta passou de 24×16 para 40×32 células. Preservados ID da área `jardim-das-pipas`, cena `park-trail`, saídas `quintal`/`park-clearing` e os 42 IDs de objetos antigos. Coordenadas mudaram: uma eventual substituição da área oficial requer migração das posições antigas, não reutilização cega das coordenadas de save.
- Dois caminhos em laço, ramal alto com rampa de três células, dois baús opcionais e três bolsões de mato contornáveis. O coreto é o marco do patamar; não está autorizado esconder suas juntas com árvores.
- Nina no recuo seguro; vestígio posterior separado do início da missão. Conteúdo e quantidades dos baús ainda não aprovados. A rabiola de Carcará continua reservada ao pátio do boss nas Veredas; não foi duplicada no Jardim.
- O convertedor foi chamado pela função `compile()` somente para o Jardim. Não executamos `build()`, que reescreveria kits e cenas de outras áreas. Inventário regenerado pelo próprio gerador.
- Correção da **ferramenta de edição**, não do código de jogo: o Canvas do Mapa Studio agora observa a dimensão real após quebra de linha de cabeçalho/rodapé. Antes a resolução interna permanecia 950×635 enquanto o elemento visível tinha cerca de 950×561, deslocando seleção e desenho. Após correção: buffer 950×561, elemento 950×560,86 (arredondamento de subpixel esperado). O clique de teste voltou a selecionar exatamente 9,24 e depois 10,13 na rampa.

## Conferência técnica

| Conferência | Resultado |
|---|---|
| Auditor do Mapa Studio | **OK; zero erros; zero avisos** |
| Células alcançáveis | 1.027 |
| Destinos visitados pelo modelo | 11, todos com ida/volta e caminho sem mato |
| Rampa v−, u9/u10/u11 | Todas sobem e descem; lateral sem rampa bloqueia |
| Laço alternativo | Continua alcançando a saída quando um trecho da trilha principal é bloqueado no ensaio |
| Objetos antigos | 42 IDs preservados |
| Mapa Studio: modelo + servidor | 7 testes, zero falhas |
| Godot: `overworld_checks.gd` | 38.883 verificações, zero falhas |
| Godot: `morro_map_checks.gd` | 9.386 verificações, zero falhas |
| Captura Godot | 8 imagens reais; log de erros vazio |

`conferencia.json` contém destinos e contagens de passos; `capturas-godot.json` contém câmera/zoom/resolução. A verificação do modelo não equivale a playtest humano de ritmo ou dificuldade.

## Inspeção visual e caminhada

Mapa carregado no Mapa Studio, com conferência verde. Foram testados pela interface: chegada ao recuo seguro (9,24), percurso até a rampa (10,13), passo por teclado rumo ao patamar e chegada à frente do baú (14,6, nível 1). O percurso até saída/retorno e todos os demais destinos também foi conferido célula a célula pelo modelo, sem alegar caminhada manual exaustiva.

Exportações oficiais do botão da bancada: `jardim-das-pipas-referencia.png` (4768×2672) e `jardim-das-pipas-legendas.png` (3576×2004). Não são pinturas novas.

No Godot, vistas `geometria-*` e `kit-*` usam a mesma planta e câmera. Foram examinados a rampa, a chegada alta e um canto externo em 3×: o volume e a cunha se fecham; não há parede na boca da rampa. Uma árvore florida foi afastada do pé da rampa durante a revisão. O patamar é retangular: não há canto interno nesta planta, nem ponte ou margem para fingir que foram validados.

**Problemas visuais ainda abertos:** o coreto e o terreno agora estão montados, mas o coreto conserva mais sombreamento que o alvo simplificado. A rampa ainda é um plano de revisão sem material próprio; bordas de materiais continuam angulares e exigem revisão próxima. A colisão bloqueia o coreto inteiro 4×4; não há promessa de entrar nele sob o telhado. O kit e o conceito permanecem em revisão, sem aprovação final. A comparação lado a lado não deve ser chamada de arte final nem conceito alinhado aprovado.

## Narrativa: o que existe e o que falta

Na planta há um evento de Nina com fala curta proposta e um vestígio com `libera_apos = nina-devolucao`. O convertedor mantém propriedades de eventos, mas não implementa sozinho condições de narrativa. `trajetoria` e `libera_apos` do mapa ainda não são transportados como contrato de progressão pelo convertedor. Os novos eventos e baús não estão conectados a recompensas ou fases oficiais da campanha.

Pedidos ao integrador:

1. Ligar o evento ao estado existente de Nina sem permitir nova recompensa ao retornar; mostrar o vestígio somente após a devolução.
2. Distinguir retrato/sprite de Nina de NPC genérico na cena de revisão. Não redesenhar Assis ou remover o guia de encontros existente.
3. Garantir a saída e o retorno da Rua por destino de entrada, migrando coordenadas antigas quando a planta substituir o cenário oficial.
4. Escolher conteúdo dos baús e persistência de abertura; a planta não concede moeda, material ou XP.
5. Polir a rampa e revisar o acabamento de coreto/terreno na prévia, preservando pegada 4×4. Se o coreto precisar de passagem sob a cobertura, projetar apoios e ordenação em lote separado; não copiar código de outra branch para resolver o desenho.

## Aceite

- [x] Planta sem erro ou aviso; eventos e baús acessíveis; dois níveis e rampa coerente.
- [x] Marco, caminhos alternativos, descanso e encontros opcionais planejados; IDs antigos preservados.
- [x] Referências exportadas e juntas examinadas em 3× sem personagem sobre elas.
- [x] Uma área compilada; suítes de mapa passam; nenhum kit alheio alterado.
- [ ] Conceito e kit do parque finalizados, alinhados e aprovados.
- [ ] Missão, recompensas e migração de saves conectadas à campanha pelo integrador.
- [ ] Playtest humano completo e aceite visual da área pronta.

Não houve push, merge ou publicação.
