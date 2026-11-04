---
name: soulmonsters-environments
description: Crie ou refine cenários e materiais isométricos 2D no estilo de papel vivo de Soulmonsters/PipaKlub, com cores chapadas, transições naturais, relevo e auditoria visual no Godot. Use para biomas, pisos, barrancos, rampas, margens e ambientação; criaturas e interfaces têm fluxos próprios.
---

# Cenários de papel vivo

Produza cenários que mantenham a leitura gráfica aprovada em movimento: massas de cor claras, detalhes de tinta seletivos, transições orgânicas e volumes sustentados. A arte reveste a geometria; não substitui altura, apoio ou oclusão.

## Começar pelo consumidor

- Inspecione as regras do repositório, o cenário atual, os materiais e uma captura real antes de propor mudanças. Preserve escolhas aprovadas e arquivos locais alheios à tarefa.
- Use a engine e o formato existentes. Esta skill tem referências para Godot 4; não autoriza migrar outro projeto para Godot.
- No PipaKlub, leia `documentation/continuidade-terreno-isometrico.md` para desníveis. Trate os valores 64×32 e capturas 1280×720 como contratos locais, não como medidas universais.
- Diferencie textura, prop, terreno, efeito e gameplay. Uma cena visual não valida colisão, natação, dano, navegação ou salvamento.

## Referências por necessidade

- Para criar/reestilizar arte ou escolher um bioma, leia [direção visual](references/direcao-visual.md).
- Para alterar altura, barrancos, rampas, poços ou apoio, leia [geometria e continuidade](references/geometria.md).
- Para preparar arquivos, implementar no Godot ou auditar, leia [produção e revisão](references/producao-godot.md). Ela também localiza os exemplos reais do projeto.

## Fluxo de trabalho

1. Defina o que deve ficar legível: percurso, obstáculos, áreas de interesse e diferenças de altura. Mantenha áreas de descanso visual; distribua detalhes em grupos em vez de preencher tudo.
2. Separe as decisões: **pegada e altura**, **material**, **ocupantes** e **efeitos**. Resolva geometria nova com cores simples antes de texturizar.
3. Para arte raster nova, use a ferramenta de geração/edição de imagens disponível, seguindo a skill dela. Use desenho e shaders nativos para geometria, máscaras e efeitos funcionais. Não substitua pintura solicitada por ruído procedural ou placeholders.
4. Gere uma amostra representativa e confira na escala real. Para famílias, mantenha paleta, vista, densidade, contorno e luz coerentes. A textura final deve sobreviver a uma vista sem efeitos de ambiente.
5. Normalize os fontes de forma determinística: escala, alpha, pivô, repetição e, quando adequado, paleta limitada sem dithering. Preserve originais e registre prompts/origem. Não quantize uma pintura existente sem motivo ou sem escopo para reestilizá-la.
6. Integre com o contrato existente. Use uma máscara estática e irregular para misturar materiais; mantenha escala e fase entre superfícies conectadas. Reutilize funções comuns, não cópias divergentes por bioma.
7. Faça revisão nativa proporcional à mudança. Para relevo novo, examine bocas de rampas, laterais, cantos e margens ampliados, sem ocupantes ou efeitos encobrindo-os. Corrija o defeito na geometria ou material de origem.
8. Entregue uma cena/asset concreto e uma evidência visual. Diga o que foi realmente conferido e se é biblioteca visual, integração local ou gameplay. Não confunda aprovação técnica com aprovação estética do usuário.

## Invariantes que preservam o resultado

- Piso natural não termina em retângulos de material sobrepostos: bordas assimétricas, mistura curta e pequenas invasões recíprocas. Não usar blur amplo como solução única.
- Um desnível exige topo, face e base derivados da mesma pegada. Uma boca de rampa aberta não pode conservar a parede que a atravessava.
- Água/lava rebaixada exige corte real do piso superior. Espuma, luz, partículas e sombras não consertam ausência de volume.
- Objetos, sombras de contato e movimento usam a mesma superfície de apoio. Plantas dobram acima da raiz; pedra e coral rígidos não balançam como folhas.
- Ambiente submerso preserva chão legível. Luz filtrada, cáusticas, bolhas e paleta ajudam a leitura; não equivalem a pôr um retângulo azul sobre uma cena seca.
- Não acrescente suítes de testes ou gere lotes caros por rotina. Respeite o pedido do usuário e as verificações obrigatórias do projeto; revisão visual de uma cena não é teste de gameplay.

## Recurso reutilizável

[assets/terrain_transition.gdshaderinc](assets/terrain_transition.gdshaderinc) contém a função comum usada nas cenas aprovadas: projeção 64×32, ruído estático e mistura irregular de faixa curta. Copie/adapte para a pasta de shaders do projeto e ajuste os `#include` ao destino. O chamador fornece a distância até a borda em células; a função não cria caminhos, alturas ou colisões. Preserve um único módulo compartilhado no projeto.
