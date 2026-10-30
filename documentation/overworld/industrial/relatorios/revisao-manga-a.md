# Pátio de Cargas — revisão visual 2D, 30/10/2026

## 1. Arquivos
Gerador `tools/mapa-studio/desenhar-industrial.mjs`, planta/compilado A, renderizador `industrial_structures.gd` e novo `industrial_dressing.gd`. Kit industrial próprio: fachada ortográfica ilustrada e carga em palete, com fontes preservadas. B e C mantêm sua composição anterior.

## 2. Conferência automática
Gerador: A/B/C sem erros e sem avisos. A: 50,8% platô, 3 itens (1 escondido), 14 células de rampa, zero bolsões e degraus soltos. Acrescentadas cinco pegadas de carga com colisão, sem alterar relevo, acessos ou ligações. As novas peças entram na blocagem e no teste de implantação existente.

## 3. Capturas
A: `../captures/a/{geometria,arte,arte-terreno}/`, 53 vistas por versão. Novas vistas: `doca-viva`, `deposito-vivo`, `carga-detalhe`, implantações 6–10. Comparação do mesmo enquadramento em `../captures/a/comparacao-manga.png`. Revisão nativa da doca, da carga e dos acessos; demais juntas preservadas e recapturadas, sem atores. Superfícies de concreto não foram redesenhadas.

## 4. Percurso
Prévia real A: 33 destinos, 66 viagens, 18.760 quadros, zero falhas após as novas colisões. Node industrial/modelo: 8 testes passaram. Godot geral: 117.089 checagens/zero falhas. Morro: 9.386/zero falhas. O primeiro teste Morro não conseguiu gravar arquivos temporários no sandbox; repetido com acesso de escrita do Godot e passou. Diagnósticos legados de shader e recursos na saída continuam, sem afirmar log silencioso.

## 5. Itens e história
Mantidos todos os itens e a condição de região independente. Paletes, carretéis e tambores apenas comunicam expedição/manutenção. Nenhuma nova recompensa, narrativa, interação ou porta funcional.

## 6. Integrador
Preservar os PNGs no export conforme limitação anterior de importação. Arte nova é revestimento e peça separada, não fundo único. Fachada é uma elevação plana mapeada no volume medido. Três contatos do palete são alinhados à pegada com transformação afim; transparência usa o shader de recorte do kit para rejeitar a névoa fraca da geração.

## 7. Avaliação do dono
Primeiro alvo visual aplicado apenas em A, como combinado. Aguardar avaliação desta direção antes de propagar a fachada e o acabamento para B/C. Aprovação artística ainda pendente. Commit local; sem publicação.

## 8. Não verificado
Export empacotado, controle físico, campanha, desempenho prolongado e todas as imagens abertas individualmente em tamanho nativo. Nenhuma animação nova. Esta revisão melhora a doca, mas não declara os três mapas concluídos artisticamente. A frente da fachada é ilustrada, laterais e volumes continuam nativos. Fontes e prompts em `art/overworld/kits/industrial-v1/fontes/` e `prompts-manga.md`.
