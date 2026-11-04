# Oficina de pipas · arte mangá v1

Integração local no fluxo Godot. A escolha de rabiolas agora usa o ateliê ilustrado existente, retrato do Sr. Assis e área com rolagem. A montagem recebeu um tampo novo visto de cima, área turquesa de trabalho e bandeja de bambu; evita projetar a armação no vazio da sala.

Produção nova pela ferramenta integrada image_gen: tampo em cores chapadas, vareta e tesoura transparentes. A primeira pintura do tampo foi simplificada em uma edição para remover excesso de grunge e aproximar a direção 2D mangá. Fontes em `art/workshop-manga-v1/fontes/`, prompts em `art/workshop-manga-v1/prompts.json`, dimensões e recortes em `art/workshop-manga-v1/manifest.json`. Normalização reproduzível por `tools/normalize-workshop-manga.py`, limitada a recorte e redução.

Papel, dobras, apoios, amarrações, linha em uso e pulso do elo são desenhados nativamente sobre a bancada. A tesoura aparece junto ao cursor durante o recorte, com oscilação visual; ainda não possui lâminas articuladas separadas. Cola, pincéis, carretel e sobras são parte estática do tampo. Não foram criados novos assets do Sr. Assis nem do ambiente de fundo da escolha.

Preservados: cinco etapas, posições lógicas, tolerâncias, dificuldade, avaliação, regras de salvamento e recompensas. A ferramenta de captura usa um modelo isolado em memória; a tela de escolha usa snapshot fictício. Não confirma escolhas, não cria parceiros e não grava slots.

Conferido: importação nativa e capturas 1280×720 das cinco etapas e escolha; checagem estática de referências com zero erros e quatro avisos anteriores do projeto. Sem suíte de testes ou jornada funcional com salvamento. Isso não confirma equilíbrio, interação por controle ou desempenho de todos os tamanhos de tela.

Para abrir bancada isolada jogável: `tools/overworld/open-workshop-manga.ps1`. É uma prévia artística; o resultado não entra na coleção. A campanha usa os mesmos novos assets ao entrar normalmente na Oficina. Alterações locais, sem publicação ou envio ao Git.
