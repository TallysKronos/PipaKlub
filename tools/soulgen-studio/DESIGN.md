# Revisão de produto — Soulgen Studio

## Problemas encontrados

O primeiro editor misturava montagem, animação e entrega no mesmo inspector. A página precisava rolar inteira; o artista perdia a criatura e os controles ao editar. A lista de dezenas de tempos não mostrava intervalos entre poses. Camadas sem miniatura exigiam decorar nomes. Ajustes pendentes podiam desaparecer ao navegar. O resultado da auditoria precisava distinguir validação técnica de aprovação artística.

## Direção aplicada

- Uma bancada estável, com três etapas que compartilham o mesmo projeto. Nenhuma etapa exige uma ordem rígida; a orientação indica o próximo passo sem travar o artista.
- Hierarquia visual com fundo neutro, destaque verde para contexto e seleção, dourado para confirmação/gravação e laranja para impacto. Textos e estados acompanham a cor.
- Biblioteca com miniaturas reais, busca e relações. Seleção fica distinta de visibilidade, bloqueio e isolamento.
- Inspector contextual: geometria na montagem, canal/pose na animação e auditoria/exportação na revisão.
- Linha do tempo proporcional, navegação entre chaves, salto para impacto e referência da pose anterior. As fontes continuam preservadas.
- Proteção explícita dos ajustes: gravar ou descartar dentro da bancada antes de navegar; nenhum descarte silencioso.
- Ferramentas repetitivas simplificadas: importação múltipla, arrastar arquivos, recorte de alpha, foco de câmera, setas, copiar/colar e zerar canal.

## Critérios de aceitação

1. O usuário consegue identificar etapa, seleção e ação ativa.
2. Consegue isolar/inspecionar uma peça sem alterar a exportação.
3. Bloqueio impede geometria, pivô, recorte e pose, mantendo seleção/inspeção.
4. Uma pose copiada só muda a animação após ser gravada.
5. Recortar transparência não desloca a arte visível nem modifica o PNG original.
6. Alterações invalidam a auditoria anterior, e aprovação técnica não é apresentada como aprovação visual.
7. Projetos da versão anterior abrem sem conversão.

## Validação e limites

Testes de operações e do DOM verificam navegação, proteção de ajustes, pesquisa, bloqueio, isolamento e edição de poses. A inspeção no navegador cobriu layout, linha do tempo, gravação, desfazer, isolamento e auditoria do Carcará.

O editor ainda usa movimentos de peças recortadas, sem deformação de malha ou cinemática inversa. Não faz geração automática de arte nem aplica os rigs ao jogo. Animações importadas com muitos quadros têm marcadores densos; zoom temporal e seleção múltipla são evoluções futuras, não funções já presentes. Revisão humana dos encaixes e da anatomia continua necessária.
