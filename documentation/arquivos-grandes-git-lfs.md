# Arquivos grandes no Git LFS

Os oito PDFs e ZIPs maiores da entrega de 2026-10-22 são versionados pelo Git LFS. Os caminhos exatos estão em `.gitattributes`; os PNGs e o código seguem o versionamento comum. A fonte e os pacotes completos continuam disponíveis nos caminhos originais.

Ao preparar uma cópia do projeto em outra máquina, instale Git LFS e execute:

```sh
git lfs install
git pull
git lfs pull
git lfs ls-files
```

Um PDF/ZIP de poucas linhas contendo `version https://git-lfs.github.com/spec/v1` é apenas o ponteiro; `git lfs pull` baixa seu conteúdo. Não substitua o arquivo pelo texto desse ponteiro em uma entrega externa.

As pastas `tmp/`, `.local/`, `node_modules/`, `desktop/build/` e `dist/` são locais ou geradas e não fazem parte do código publicado. Elas não substituem as entregas finais em `art/`, `assets/`, `documentation/` e `output/`.

A preparação Windows/Steam está em `desktop/`, com instruções próprias. O pacote executável gerado em `dist/steam/` continua sendo um artefato de distribuição local; os scripts e fontes necessários para reproduzi-lo estão no Git.

Publicar estas entregas no Git não instala migrações do Supabase nem confirma implantação no Render. Os sprites do Eremor são uma entrega de arte e prévia; a integração ao catálogo/combate continua descrita na documentação do pack.
