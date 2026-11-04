# Bambuzal — relatório de construção

1. Arquivos: plantas Tiled e mapas compilados `kronasta-bambuzal-a/b/c`, gerador `tools/mapa-studio/desenhar-kronasta-bambuzal.mjs`, kit SVG `bambuzal-v1`, construtor `bamboo_structures.gd`, integração em `kronasta_forest.gd` e `view.gd`. Escadas de `forest_structures.gd` agora derivam a cota de base, inclusive 1→2. Briefs em `art/overworld/briefs/`.
2. Resultado automático: ver `conferencia.json`. A 72,3%, B 75,7%, C 87,3% de platô; três itens por parte, um escondido, zero bolsões inalcançáveis/degraus soltos. Todas: CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos.
3. Capturas: `captures/a`, `captures/b`, `captures/c`, versões `arte` e `geometria`. Área inteira, entrada, centro, platôs, saídas e detalhes enumerados nos planos de captura. Sem personagem nas juntas. Não há ponte, poço ou cachoeira nesta região.
4. Percurso: `bambuzal_navigation_checks.gd` exerceu o controlador e seguidor reais, ida/volta de todos eventos e células de rampa: 2544 verificações sem falha. `bambuzal_flow_checks.gd` caminha pela campanha entre os cinco duelos e três mapas. Não foi exploração manual com controle físico.
5. Revelação: corte noturno de bambu/varetas para o Bando. Somente a pista definida na bíblia §7.2; Nara, Dito, Célia e Bento aprovados pelo dono. Itens de materiais existentes; nenhum novo item de história inventado.
6. Integração: realizada pelo agente principal na campanha, sem atribuir lógica de batalha ao construtor. Ver `documentation/campaign/pip-105-bambuzal.md`.
7. Dúvidas: nenhuma pendente para este mapa; cena de Tyler e espécies novas permanecem em demandas futuras.
8. Não verificado: exportação final, controle físico, jogabilidade completa manual de todos duelos, todas resoluções. Capturas 1280×720. O tema dos prédios e bambus reutiliza construção vetorial 2D; não é arte pintada nova para cada casa. Avisos headless/recursos remanescentes das suítes estão descritos no relatório da campanha.
