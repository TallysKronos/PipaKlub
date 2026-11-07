# Benchmark de design evolutivo

[Abrir a galeria e o estudo completo](index.html) · [Ler ANALISE.md](ANALISE.md).

12 estudos: três de Pokémon, três de Digimon, três de Yo-kai Watch e três de Persona. Inclui diferenças entre evolução, ramificação, Armor, DNA, síntese, despertar e estado narrativo; crítica das oito pranchas do Azulão; 12 princípios e um modelo de brief.

## Evidência

- Fontes oficiais de Pokémon, Digimon, Nintendo e Atlus; entrevista com os designers publicada em tradução por Persona Central e entrevista de Soejima por RPG Site. Fontes secundárias são identificadas no texto.
- `referencias.json`: coleta bruta com URLs e hashes; pode conter arquivos de navegação excluídos da seleção.
- `referencias-selecionadas.json`: somente as ilustrações usadas nos painéis de análise, com origem.
- `inspecao-*.jpg`: painéis de comparação conferidos visualmente; não são novos concepts.
- As imagens de pesquisa pertencem a seus respectivos titulares, sem licença de reutilização no jogo presumida. Não alimentar geração com essas imagens nem copiar soluções reconhecíveis.

## Reprodução

`coletar_referencias.py` lê as páginas públicas; requer rede. Aceita `--only <id>` para atualizar uma fonte. `construir.py` funciona offline com os arquivos locais, verifica imagens/hashes e reconstrói painéis e HTML. Ambos usam Python; a construção usa Pillow já disponível no ambiente.

Conferência: 12 fichas, imagens selecionadas abertas e verificadas, links locais válidos e filtro por franquia exercitado em DOM. Não houve validação visual do HTML renderizado em navegador. Nenhuma alteração de código do jogo ou geração de novos designs nesta etapa.
