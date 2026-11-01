---
name: soulmonsters-designer-de-hud
description: Crie, refine ou audite a identidade visual e a interação de HUDs, menus e transições do Soulmonsters em Godot. Use para benchmark, direções visuais, sistema base, telas, acessibilidade e HUD-KIT v2, com linguagem própria de pipa, Kronasta, almática, Elo e Pipa TV.
---

# Designer de HUD do Soulmonsters

A interface nasce do mundo: papel de seda, vareta, linha, rabiola, carretel; laje, muro pintado e lambe-lambe de Kronasta; almática, Elo e o campeonato da Pipa TV. O teste de identidade é um print sem logo continuar reconhecível como Soulmonsters. Um losango ou uma textura de papel isolados não satisfazem esse teste.

## Antes de trabalhar

Leia `AGENTS.md`, `HUD-KIT.md` e esta skill. Consulte a referência correspondente:

- [identidade.md](references/identidade.md): brief visual, matérias e teste sem logo. Ler ao criar ou revisar direção.
- [benchmark-e-direcoes.md](references/benchmark-e-direcoes.md): pesquisa PIP-127, três propostas PIP-128 e escolha PIP-129. Ler antes de estudar referências ou produzir conceitos.
- [implementacao.md](references/implementacao.md): infraestrutura real, consumidores, arte, Theme, input e dados. Ler antes de alterar o jogo.
- [aceite.md](references/aceite.md): quatro resoluções, estados, teclado/controle/mouse, acessibilidade e evidências. Ler em implementação e auditoria.

O plano e as decisões deste épico ficam em `documentation/hud-v2/PLANO.md`. As definições de mundo e elenco vêm de `documentation/historia/BIBLIA-DA-HISTORIA.md`; não revele os segredos dela em telas iniciais. Identifique quais termos são canônicos e quais são propostas.

## Fluxo

1. Defina tela, tarefa do jogador, dado real, estados e etapa do épico. Consulte o consumidor e uma captura atual antes de redesenhar.
2. Pesquise princípios e documente fontes; diferencie observação visual de inferência. Referência não é identidade a copiar.
3. Em propostas, mostre contexto de jogo, conteúdo plausível e estados; paleta e painel decorativo isolados não são mock funcional.
4. Registre a escolha na PIP-129 antes de consolidar o sistema. Se o dono delegar a escolha, escolha e justifique sem pedir uma aprovação adicional que ele não exigiu. Nesta sessão ele delegou a escolha. Isso não autoriza merge.
5. Implemente por tela sobre a infraestrutura existente. Texto, input e dados permanecem nativos. Não mude balanceamento, recompensas, quests ou saves para caber no desenho.
6. Audite identidade, conteúdo, layout e interação; mantenha provas e limitações. Faça commits pequenos por tarefa. Só declare uma tela pronta com o aceite correspondente conferido.

## Limites

- Godot em `godot/` é o alvo atual; web é referência ou alvo separado quando solicitado. Não migre a engine nem imponha o renderer web ao Godot.
- PIP-61 fornece Theme, tokens, fontes e auditoria de margens reaproveitáveis. Suas 12 tarefas abertas ficam em espera até a escolha PIP-129; não feche nem remapeie tickets silenciosamente.
- Não copie recortes, glifos, fontes proprietárias, paletas completas ou composições de outras franquias. Estude função, hierarquia, ritmo e reconhecimento.
- Não transforme toda tela em placar de campeonato ou mural ruidoso: cenário, conversa e combate têm densidades distintas.
- Nenhum merge sem autorização explícita do dono. Publicação, push e mudanças no Linear seguem o escopo autorizado; um arquivo local não prova atualização de ticket.
- Não exija que toda tarefa use imagens geradas: geometria e layout simples podem ser nativos; raster ilustrado usa a skill de imagem disponível. Preserve fontes e licenças.

## Entrega

Por tarefa, mantenha brief/decisão, arquivos editáveis ou código, referências e proveniência quando houver arte, capturas e relatório do que passou/falhou. A pasta sugerida é `art/ui/soulmonsters-v2/<etapa>/` para propostas e `documentation/hud-v2/` para contratos e QA. Não sobrescreva versões aprovadas.

PIP-139 entrega `HUD-KIT-v2.md`, com componentes reais, usos e limites; não renomeie o kit antigo como se a migração já estivesse concluída. As telas da campanha PIP-91 passam a seguir o guia quando estiver consolidado.
