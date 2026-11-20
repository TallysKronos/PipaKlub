# Benchmark Ultimate e Mega

Estudo de 04/11/2026: **40 casos, 20 Ultimate e 20 Mega**, selecionados pela diversidade de construção. Não é um catálogo exaustivo de todos os Digimon.

Abra [index.html](index.html) para ler o estudo, filtrar arquiteturas e comparar duas construções. Funciona com imagens locais e sem bibliotecas externas.

- [ANALISE.md](ANALISE.md): 25 seções, anatomia, proporção, matéria, armaduras, elmos, armas, gesto, função narrativa e 16 princípios.
- [FICHAS.md](FICHAS.md): 40 análises individuais com fontes próximas das afirmações.
- [MATRIZ-DE-CRIACAO.md](MATRIZ-DE-CRIACAO.md): eixos, briefs, exercícios e conferência.
- [APLICACAO-SOULMONSTERS.md](APLICACAO-SOULMONSTERS.md): diagnóstico das nossas famílias, preservando aprovações existentes.
- [fontes.json](fontes.json): origem, data, hashes, fatos parafraseados e interpretações separadas.
- [validacao.json](validacao.json): verificações locais e limites.

## Origem e cuidado com variantes

Perfis e artes: Digimon Encyclopedia, Digimon Web/BANDAI. As imagens pertencem aos respectivos titulares e estão aqui como evidência de pesquisa, sem licença presumida de reutilização como assets. Não são referências de entrada para geração de Soulmonsters.

Os níveis são os nomes **ingleses do catálogo oficial**. Jovem/adulto é nossa analogia de projeto, não uma equivalência automática. Perfis relacionados não constituem prova de uma rota evolutiva universal.

MetalGreymon é a variante Vaccine (`metalgreymon-v`), Rapidmon é o verde Ultimate, MegaKabuterimon (Red) é Ultimate e MarineAngemon é Mega. Os aliases `lilimon`, `ofanimon` e `pinochimon` foram confirmados nos perfis oficiais. Tentativas que não retornaram arte correspondente não viraram casos. `tentativas-alias.json` conserva o registro dessas tentativas; pode haver uma imagem alternativa não usada na pasta de referências.

## Evidência e reprodução

As 40 artes foram vistas: 33 em seis folhas iniciais, sete em inspeções individuais. As sete folhas finais reorganizam a amostra com espaço normalizado, sem representar escala física. Não foram medidos esqueletos ou ciclos de animação, e não se afirma conhecer a intenção dos designers.

`coletar.py` consulta a amostra oficial finita e baixa as imagens. A coleta pode conter transcrições temporárias para leitura; `build.py` remove os perfis integrais da coleção publicada. `completar.py` registra a recuperação histórica de aliases. `preparar.py` documenta a adaptação inicial do publicador do estudo anterior; não é necessário executá-lo novamente.

Para reconstruir a galeria a partir dos dados locais, execute `python build.py` nesta pasta, com Pillow instalado. A reconstrução confere os hashes, escreve as fichas, fontes, coleção sanitizada e sete folhas de contato. O estudo continua editorial: os fatos e as leituras precisam de revisão humana quando a amostra mudar.

Nenhum design aprovado, rig, regra canônica ou código do jogo foi alterado. Não houve commit, push ou merge nesta entrega.
