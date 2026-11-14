# Validação da organização por grupos

Atualizado em 10 de novembro de 2026.

O atlas reúne 134 famílias e 420 fichas únicas em 33 grupos. As 507 associações permitem que uma criatura apareça em mais de um grupo sem duplicar sua identidade. As 17 reservas visuais ficam separadas das criaturas catalogadas.

## Reprodução

Na raiz do repositório:

```powershell
python documentation/creatures/familias/gerar_catalogo.py
python documentation/creatures/familias/gerar_grupos.py
node --test documentation/creatures/familias/grupos.test.mjs
```

O segundo gerador confere cobertura, seletores de integrantes, identidades únicas e referências locais. O resultado fica em `validacao-grupos.json`. Execute os geradores nessa ordem: o segundo acrescenta os grupos ao catálogo.

Os dez testes executam a lógica do atlas em Node, com um DOM simulado. Conferem famílias mescladas, associações sobrepostas, nomes compartilhados, busca sem acento, filtros de maturidade, aprovação do Conde v2, navegação pela linhagem de Rabbito, entrelaços, rotas adultas dos Demons do Folclore e campos ainda não decididos na planilha de povoamento. A busca também pesquisa o texto narrativo e pode encontrar um termo dentro de outra palavra.

## Limites

O controle automatizado do navegador estava desativado nesta sessão. Estes resultados não representam inspeção visual da página em navegador, auditoria de todos os desenhos ou teste de gameplay.

A classificação editorial ajuda a planejar o universo. Ela não confirma facções, locais de encontro, raridade ou acesso dos jogadores. A planilha deixa essas decisões em branco para preenchimento pelo autor. Ver a definição e as fontes de cada conjunto em `GRUPOS.md`.
