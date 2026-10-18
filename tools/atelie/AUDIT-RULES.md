# Auditoria de cenários modulares do PipaKlub

Obrigatória para novas criações e revisões do quintal. O JSON editável é a fonte do cenário; corrigir o gerador e regenerar seus arquivos quando houver um gerador. Não corrigir apenas uma captura ou o HTML compilado.

## Verificações automáticas

Ativar `layout.audit.enforce: true`. Novos projetos do Ateliê já nascem com essa opção. O quintal também é auditado durante a construção do jogo. Rascunhos continuam desenhados no editor; a revisão, o teste e a exportação indicam os erros. Salvar o JSON de um rascunho continua permitido.

| Código | Regra | Correção esperada |
| --- | --- | --- |
| ARB-01 | Toda copa tem um tronco centrado, com o mesmo apoio de profundidade. | Alinhar o centro da copa e o tronco; usar o pé da árvore como `sort_y` em ambos. |
| ARB-02 | Sobreposição copa/tronco de pelo menos 25% da altura visual do tronco; preservar pelo menos 25% de tronco aparente. | Encaixar a copa nos galhos, sem deixar ar entre as partes nem esconder a raiz. |
| MUR-01 | Segmentos consecutivos da mesma série não deixam vãos maiores que 1 px. | O passo deve corresponder ao comprimento visual, sem contar margens transparentes. |
| MUR-02 | Espessura e alinhamento constantes por série, tolerância de 1 px. | Usar interiores repetíveis do atlas. Última peça pode sobrepor, mas nunca encolher, mudar de altura ou repetir um terminal. |
| MOB-01 | Banco sem copa sobre a imagem e com faixa frontal de 48 px livre de bases sólidas. | Colocar o encosto ao norte e a aproximação ao sul para esta arte frontal. Outra orientação exige outro sprite e contrato de acesso. |
| MOB-02 | Faixa de aproximação do banco fica sobre piso caminhável. | Reservar espaço para o personagem chegar e sair. |
| PIS-01 | `ground_corner_radius` positivo no mapa. | Usar 24 px no quintal, em grade de 32 px. O renderizador calcula curvas externas e internas da união dos pisos. |

Manter o mesmo nome de série nos segmentos de um muro contínuo e nomes diferentes nas séries separadas por portões. Não renomear peças para contornar a auditoria. O teste de circulação e o validador do editor também verificam camadas, dimensões, atlas e caminhos existentes.

Executar `npm run audit:world`. Para outro projeto: `node scripts/audit-world.mjs caminho/projeto.json`. Os testes de regressão estão em `world-structure.test.mjs`.

## Contrato artístico dos muros

As verificações MUR-01 e MUR-02 validam retângulos, alinhamento e escala. Elas **não detectam** pedras reiniciadas ou terminais repetidos dentro da imagem. A revisão de muros v3 substitui os antigos recortes pela folha `walls-v2.png`, com quatro direções e quatro quinas derivadas de uma moldura conectada. O script `art/world-quintal-modular-v1/audit-wall-edges.py` confere transparência, compatibilidade de alpha nas repetições e variação da silhueta. Textura e iluminação continuam exigindo revisão visual.

Painel reproduzível: `http://127.0.0.1:5210/wall-audit.html`. Exibe oito repetições por direção e os quatro cantos sobre fundos claro e escuro, usando os mesmos recortes do jogo. Terminais livres e junções T/cruzamento precisam de variantes próprias antes de serem usados; no quintal os trechos terminam sob os pilares do portão.

Regras adicionais de aprovação visual, ainda sem validação automática de pixels:

| Código | Regra |
| --- | --- |
| MUR-03 | Retas têm conexões abertas e compatíveis; terminais só aparecem nas pontas. |
| MUR-04 | Topo, espessura, fase das juntas e iluminação continuam entre peças. Rejeitar saliências periódicas mesmo que os retângulos se encostem. |
| MUR-05 | Quinas externas e internas são variantes próprias e preservam as conexões das retas. Não fechar a junção sobrepondo faixas ou alterando escala. |
| MUR-06 | Aprovar retas repetidas oito vezes, retângulo, L, U e portão, sem plantas ocultando as emendas, em fundo claro e escuro. Vazio externo usa alpha real; contornos escuros da arte permanecem. |

Não chamar um objeto ilustrado de tile repetível apenas porque foi recortado. O conjunto precisa ser desenhado e testado para as conexões declaradas.

## Revisão visual obrigatória antes de aprovar

1. Inspecionar o mapa inteiro e depois as junções em zoom de 100% e 200%. Os testes geométricos não conseguem provar a continuidade dos pixels dentro de uma imagem.
2. Árvores: copa presa aos galhos, raiz no chão, escala consistente e base física correspondente. Conferir a sombra e a posição do personagem atrás e à frente.
3. Muros: seguir cada trecho de ponta a ponta. Rejeitar transparência entre módulos, degraus de altura, ornamentos de terminal repetidos, mudança de escala e cantos abertos. Conferir o encontro horizontal/vertical e as extremidades do portão.
4. Piso: conferir quinas convexas e côncavas, entroncamentos em T, cruzamentos e ilhas. Arredondar o contorno do conjunto; não arredondar cada retângulo isolado, criando buracos nas junções.
5. Móveis: encosto, frente, acesso e uso fazem sentido no ambiente; nenhum banco sob uma copa que o esconda. Verificar circulação ao redor dos dois lados.
6. Caminhar da entrada até cada interação e saída. Repetir numa janela menor; nenhum objeto ou controle pode ficar inacessível.
7. Guardar uma captura da visão geral e das junções alteradas. Só então aprovar. Registrar limitações pendentes, sem chamar a verificação automática de aprovação artística completa.

Projetos já salvos no navegador não são sobrescritos por revisões da planta padrão. Abrir a revisão em outra bancada preserva o trabalho do usuário.
