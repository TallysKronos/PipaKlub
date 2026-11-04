# Sincronização Soulgen · 02/11/2026

Origem: `origin/codex/soulgen-redesigns`, commit `6af7ecb7`. Base local preservada: `e12fc79e`, com o reencontro ramificado de Heleana e Retalho.

Foram copiados os arquivos alterados de `art/soulgen/` desde a base comum, incluindo concepts, decisões, projetos aprovados, peças, expressões, prévias e testes. Os quatorze presets foram acrescentados ao Studio sem remover os presets existentes, com abertura também pelo parâmetro `?preset=`.

Inclui Trovareta, Rabiolava, Glacerol, Tufanocorte, Retalho original e mascarada, Platyx, Rai, Riscaz, Pipa-Dragão e forma desatada, Azulfazo normal e possuído, Mormaço e estudos do Grande Carretel.

A branch remota inteira foi buscada e permanece disponível. O histórico de interface experimental não foi mesclado, seguindo `art/soulgen/campaign-redesigns-v1/PROXIMOS-PASSOS.md`. Código Godot e a Bíblia local não foram substituídos. Esta sincronização não integra os rigs às batalhas nem resolve divergências de nomes/roteiro entre branches.

O projeto aprovado de Retalho original tem finais de linha LF preservados por `.gitattributes`, necessários ao SHA256 registrado pelo autor.

Validação: 28 testes dos novos rigs passaram. Os testes de servidor do Studio requerem permissão de acesso ao localhost. Os testes de pintura e interface de sprites dependem de bibliotecas adicionais de DOM/canvas e não foram validados nesta sincronização.


Resultado adicional: os 14 presets e todas as imagens referenciadas passaram na verificação HTTP local (`campaign-presets.test.mjs`). Na suíte ampla do Studio, 148 testes passaram e 12 falharam em asserções que procuram listas literais antigas no código de `studio.mjs`; essa suíte não está totalmente verde. Pintura e interface de sprites também não foram executadas com suas dependências DOM/canvas instaladas. Não foi feita auditoria visual das animações no navegador nesta sincronização.
