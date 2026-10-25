# Alvaneve · O Inverno que Aprendeu a Confiar

Dragão de papel branco/ciano/lavanda, asas de pipa com bambu e rabiola com folhas de gelo. Nove peças articuladas em vista oblíqua para a direita. Todas mantêm exatamente a proporção largura/altura dos recortes originais: define-se apenas a altura e calcula-se a largura. preserveSourceAspect ativa verificação de esticamento no exportador. Não altera os rigs já aprovados pelo autor.

Soulgen: http://127.0.0.1:5240/?preset=alvaneve

Cinco ações: Brisa do inverno, Voo cristalino, Sopro frio, Recuo e Confiança conquistada. Ciclos fechados e ações únicas retornam ao neutro. Expressões preservam a silhueta e os pixels externos à janela facial. Fonte ImageGen de 25/10/2026 preservada em color-rig-v2/source.png; prompt e referências em prompts.json. prepare.py mede componentes e registra expressões, sem redesenhar olhos ou anatomia por código. build.mjs monta pivôs próprios e exporta projeto portátil, prévia HTML com controles e miniatura, review.png em dois fundos e review-full.png com os 116 quadros do atlas de estudo (12 fps/256 px). Montagem lógica 272 × 256; PNGs na resolução original.

Reprodução: Python/Pillow para prepare.py, Node com @napi-rs/canvas para build.mjs (SOULGEN_CANVAS_MODULE aceita instalação externa). Verificação técnica não equivale à aprovação artística. Aguarda revisão do autor. Atlas, sprites e saves do jogo preservados.

## Revisão 2 — coxas e mãos do autor

Montagem recebida preservada em author-layout.json: cabeça, corpo, asas erguidas, rabiola e mãos duplicadas mantêm posições/pivôs/inversões originais. As duas peças inferiores antigas foram substituídas por pernas completas com coxa, joelho e pé, geradas em thighs-source.png e normalizadas sem esticar. Mão duplicada ganha canal próprio nas cinco ações, com giro oposto, mais balanço suave no voo. Nove peças no total. As pernas são articuladas no quadril como peças contínuas. Referências de socket antigas não se aplicam à montagem do autor; testes verificam preservação, proporção, limites, ciclos e animação da cópia.

Revisão 3 aprovada em 25/10/2026: approved-layout.json preserva o arquivo final do autor, incluindo reposicionamento da perna próxima e inversão horizontal da distante. build.mjs aplica a montagem final e as animações exatamente como recebidas.
