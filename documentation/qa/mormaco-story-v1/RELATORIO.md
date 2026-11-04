# Mormaço · encontro e libertação · V1

## 1. Arquivos

Serviços `mormaco_story.gd` e `mormaco_overworld.gd`; integração no frontend, diário, save, modelo e apresentação de batalha. Texturas livre/possuído em `godot/assets/campaign/mormaco-v1/`, registros no conteúdo, bounds e retratos. Prompts e limitações em `art/creatures/mormaco/runtime-v1/`. Nenhuma planta, altura, ponte, margem ou kit de terreno foi alterado.

## 2. Verificações

Mormaço: 44 verificações headless e 49 na janela nativa, zero falhas. A vitória foi obtida executando o modelo real com um controlador programado, sem injetar resultado vencedor. Derrota e fuga usam resultados terminais preparados para testar persistência. Inclui pré-requisitos, posição inválida/remota, observação antes do duelo, recarga da batalha, falha de gravação na abertura, conclusão e libertação, repetição negada, descanso, ausência de captura/itens/moedas e restauração da textura livre.

Regressões: Remar39, confiança de Retalho92, Morro9386 verificações, zero falhas; Mapa Studio6 testes passando. Teste geral do overworld executado e resultado registrado abaixo após conclusão. Avisos existentes de imagens do ateliê para exportação e recursos ativos ao encerrar não equivalem a uma exportação validada.

## 3. Capturas

`01-vento-parou.png`, `02-possuido.png`, `03-duelo.png`, `04-libertacao.png`, `05-livre.png`, 1280×720, janela nativa. Revisão individual de apresentação do lago, entrada da batalha e forma livre. A área é o lago C já existente; não foi criado novo mapa nem refeita auditoria de suas juntas antigas.

## 4. Percurso

Ambas as estações do lago (interação24.5,28.5; descanso21.5,30.5) têm caminho a partir da entrada, verificado pelo modelo. Teste posiciona o jogador nas estações e aciona os diálogos reais; não percorreu manualmente toda a região A/B/C com controle físico. O guardião aparece no centro da água e não altera colisão terrestre. Ondulações indicam contato com o lago; a pose inteira ainda pode ganhar máscara de submersão numa revisão visual futura.

## 5. História

Azul + Remar prático habilitam o encontro, sem depender do arco de Retalho. Examinar o ar parado no Pântano A registra a abertura. Duelo Nv.27 no lago C: movimento lento, puxão anunciado, jato com2,1s de preparação e recuperação. Vento da batalha zero; HUD corrigida para “Ar parado”. Vitória desfaz os laços; conversa registra libertação e pista do frio. Não concede captura, XP, itens ou categoria Vermelha. Derrota retorna à entrada, fuga permite recuar; descanso gratuito recupera parceiros. Nada morre ou é removido do banco.

## 6. Integração

Estado do encontro tem tipo próprio validado; operações de vitória/libertação atômicas e idempotentes. Vitória salva antes de retornar ao mundo; libertação permanece pendente se falhar a gravação. Interface informa jato, nome e nível próprios. Formas aprovadas e todas as reservas preservadas. Sem servidor, deploy, merge ou push.

## 7. Pendências de continuação

Bairro7/Caio Garça e sequência da Serra ainda não foram construídos nesta entrega. Não atribuir nova identidade aos conceitos reservados sem decisão do dono.

## 8. Não verificado

Rig Soulgen e animação articulada: não implementados. Duas poses ilustradas com oscilação pequena/transição de cor; não é spritesheet completo de ataque/dano. O combate usa avisos e feedback existentes com parâmetros próprios. Balanceamento com jogador externo, controle físico, Steam Deck e exportação Steam não verificados. Batalha programada não prova dificuldade adequada. Fundo da arena de combate ainda reutiliza a arena aprovada das Veredas, não uma arena pantanosa exclusiva. A transformação com movimento reduzido é imediata; a captura testa esse modo. Não foi feita revisão manual de todas as juntas do mapa porque geometria permaneceu intacta.

Teste geral concluído: `OVERWORLD 507283 checks; 0 failures`. Aviso preexistente do compilador de shader `_painted_floor` em headless permaneceu.
