# Cais Velho — mapas A/B/C, entrega visual inicial

## 1. Arquivos
Gerador determinístico tools/mapa-studio/desenhar-kronasta-cais.mjs; três TMJ e JSON compilados, índice de preview; harbor_structures.gd, adaptações condicionais a forest.harbor nos construtores e fundo preto; kit cais-v1 com seis recortes/alpha real e fonte/prompt em art/overworld/kits/cais-v1. Teste cais_navigation_checks.gd. Brief antes dos tiles em art/overworld/briefs/cais-velho.md.

## 2. Resultado automático

### Parte A

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 55.4% · 3 itens (1 escondidos) · 8 células de rampa · 0 inalcançáveis · 0 degraus soltos

### Parte B

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 57.9% · 3 itens (1 escondidos) · 8 células de rampa · 0 inalcançáveis · 0 degraus soltos

### Parte C

CONFERÊNCIA ZERO QUEBRA: SEM ERRO · 0 erros · 0 avisos
Platô 60.0% · 3 itens (1 escondidos) · 16 células de rampa · 0 inalcançáveis · 0 degraus soltos

Links A↔B↔C: piso de pedra cota1, saída v− / chegada v+. Água cota0, terraços2 e mirante3. Platô informado é proporção absoluta do mapa; água não conta. Conferência inclui cada evento e item no percurso de duas células, não apenas as saídas. Foram corrigidos bolsão atrás do mirante C, item escondido bloqueado por casa B e item sobre banca B.

## 3. Capturas
captures/{a,b,c}/{geometria,arte}/: 63 por modo em A,64 em B,82 em C, total418 PNGs. Planos enumeram todos os cantos, pontas/encontros de guarda-corpo, pés/chegadas de escada, duas cabeceiras da ponte e enquadramentos de jogo. Revisão de três gerais em cada modo, pranchas reduzidas de rampas/cantos e amostras nativas ampliadas. Capturas não ocultam junta com personagem. Não há cachoeira nem poço natural; a doca é rebaixo construído retangular, de água real abaixo do cais.

## 4. Percurso e testes
Caminhante e seguidor reais:2098 verificações, zero falhas após casas/props finais, ida/volta a todos os eventos, itens, saídas e rampas. Mapa Studio Node6 testes sem falhas. Morro9386 sem falhas. Suite geral do overworld454762 verificações, zero falhas na execução final. Relatório gerado de outras áreas revertido antes do commit.
Avisos já presentes: shader_compiler em _painted_floor no modo sem janela; Morro informa recursos/objetos ainda em uso ao encerrar; importação emitiu aviso safe-save. Nenhuma proteção do editor foi desativada.

## 5. Itens e história
Nove materiais existentes, três por parte, um escondido por parte. Lugares preparados para Neril/Ossian em A, Vaelis/Rhuna em B, Marisol em C. Descanso B e atalho C→A exigindo flag cais. Sem boss selvagem, nova revelação ou espécie inventada. Tema da bíblia: barcos de pesca com pipas de sinalização, campeã Nv.21, próximo bairro Vila Operária. Os interiores das casas não existem: portas são detalhe de fachada decorativa, sem prometer entrada funcional.

## 6. Integração pendente
Nesta entrega o Cais é preview de mapa, não região liberada na campanha. Catálogo segue playable=false; nenhum save, prêmio ou batalha foi alterado. Falta gerar/adaptar sprites do elenco aprovado, atribuir suas imagens aos eventos, escrever/configurar cinco duelos e diálogo, ligar atlas/checkpoint e validar desbloqueio após Feira, vitória e retorno. Não usar retratos de concept como sprites recortados de fundo branco. Não houve push, merge ou deploy.

## 7. Pontos para revisão
Kit é arte inicial, não aprovação automática do dono. Mesma fachada reaproveitada em volumes de tamanho diferente produz repetição; próximos ajustes podem variar tintas, portas e telhados mantendo a geometria. Mapa intencionalmente seguro; sem mato selvagem nem tabela de espécies nesta rodada. Efeitos de vento/água e som próprios não foram adicionados. Píeres A são estruturas de pedra com tabuleiro de madeira, não pontes flutuantes de um apoio só. Barcos são decoração na água não caminhável, sem mecânica de embarcar.

## 8. Não verificado
Não foi inspecionado cada PNG individual em tamanho nativo; todas as imagens foram geradas, mas a revisão de juntas foi por pranchas e amostras. Portanto não declarar acabamento visual final de todas as margens. Sem teste manual prolongado de controle físico, Steam Deck, exportação ou campanha desde o prólogo. Ainda não avaliados combate/economia por estes mapas não estarem integrados. Capturas sem personagens não validam futura oclusão dos sprites. Assets de kit têm recortes definidos por caixa após inspeção; não foram desenhados novos tiles de navegação. Não afirmar região completa ou jogável na campanha.

### Correção de recorte no kit
Na inspeção nativa foi encontrado fragmento da âncora do barco dentro da caixa de recorte da banca. Corrigido por separação do maior objeto conectado do alpha, preservando arte/fonte original e alpha nas bordas. Empacotador reproduzível tools/package-cais-kit.py; capturas de arte refeitas após reimportar. Não era objeto de jogo colocado no muro.

## Atualização posterior: integração da campanha
A seção6 descreve o estado da entrega visual anterior. A integração foi implementada posteriormente: sprites estáticos dos cinco NPCs, catálogo de duelos, atlas/checkpoints, quinto emblema, descanso e retorno. O requisito textual `cais` do atalho agora consulta a conclusão permanente do campeonato, não uma flag inexistente. Neril foi reposicionado de(24,30) para(22,32) para evitar oclusão pela casa; nenhuma geometria mudou. Capturas de campanha e limites da verificação estão em ../../qa/cais-v1/RELATORIO.md. A aprovação dos conceitos não foi tratada como aprovação automática dos novos sprites.

Rhuna também reposicionada de(34,31) para(31,32) após captura mostrar oclusão pela casa da doca. Sem alteração da geometria.
