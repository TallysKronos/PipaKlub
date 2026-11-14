# Entrega de uma família

## Pastas e estados

Usar a raiz real do checkout atual, sem caminhos absolutos de outra máquina gravados como dependência. Convenção sugerida:

```text
documentation/creatures/<familia>-chart-v<n>/
  CHART.md       história, relações, incógnitas e decisões
  chart.json     nós e ligações documentais
  fontes.json    pesquisa com URLs e distinção fato/interpretação
  index.html     leitura visual navegável do chart, quando solicitada
art/creatures/<familia>/
  DECISOES.md
  <forma>/concept-v<n>/
    brief.md
    concept.png
    prompt.txt
    revisao.md
    manifest.json
```

Adaptar às pastas existentes em vez de duplicar a identidade em outro ID. Salvar miniaturas, alternativas, paletas ou ações quando realmente produzidas; não criar arquivos vazios nem declarar vistas ausentes. Não sobrescrever designs ou JSONs de rig editados pelo autor.

Em cada manifesto de arte registrar ferramenta, fonte do PNG, hash, dimensões reais, alpha, prompt e papel das referências próprias. Prompts de correção pertencem ao histórico. Não deixar um asset referenciado apenas em pasta temporária ou de imagens geradas fora do repo.

Estados separados:

- **Decisão de design:** proposto / aprovado pelo autor / rejeitado / substituído.
- **Produção visual:** brief / concept / vistas / recortes / rig / animações.
- **Implementação:** não integrado / integrado e testado.

“Aprovado” após ver um concept não certifica pixel art técnico, recorte, animação, montaria ou balanceamento. Registrar a frase do autor e seu escopo; aprovar cinco não aprova uma sexta forma inédita. Informações antigas continuam como histórico, mas o índice deve apontar claramente o resultado atual.

## Contrato documental mínimo

Não existe contagem fixa de formas. Para um novo chart, este formato alimenta o helper genérico:

```json
{
  "family_id": "familia-existente",
  "scope": "Concept e documentação; sem integração",
  "nodes": [
    {
      "id": "forma-base",
      "name": "Nome existente",
      "kind": "stage",
      "stage": 2,
      "identity": "Sinais observados e fonte local",
      "story": "Personalidade e relação com a história existente",
      "decision_status": "approved",
      "approval_note": "Identidade existente; citar decisão ou registro real",
      "production_status": "concept"
    },
    {
      "id": "forma-proposta",
      "name": "Nome proposto",
      "kind": "stage",
      "stage": 3,
      "identity": "Anatomia de destino e sinais familiares preservados",
      "story": "O que amadurece e o que muda no comportamento",
      "decision_status": "proposed",
      "production_status": "brief"
    }
  ],
  "edges": [
    {
      "from": "forma-base",
      "to": "forma-proposta",
      "kind": "reweaving",
      "reason": "Como a história da base conduz à nova construção",
      "decision_status": "proposed"
    }
  ]
}
```

`stage` pode ser `null` quando a correspondência não estiver decidida; identificar a incógnita no texto. Campos extras úteis: `maturity`, `role`, `action`, `tradeoff`, `inheritance`, `target_anatomy`, `item`, `unknowns`, `art`, `brief`, `sources`, `approval_note`. Não transformar exemplos de texto em decisões reais.

Tipos de nó: `stage`, `configuration`, `state`. Tipos de ligação: `reweaving`, `configuration`, `interweaving`, `possession`, `return`. Uma união pode ter duas entradas para o mesmo resultado e deve declarar os parceiros; compatibilidade é proposta até decisão. Um estado não precisa ter grau de maturidade. A ligação especial por material pode declarar `stage_delta` se houver estágio definido: manter separada a decisão de adaptar da decisão de amadurecer.

Quando `art` ou `brief` estiver preenchido, usar caminho relativo ao diretório do `chart.json`. Não copiar IDs de criatura de outra família. Novas fontes: lista de objetos com URL, título, entidade responsável, acesso, fato observado, interpretação e uso proposto. Nome, rota e receita de item têm aprovação própria, independentemente da arte.

## Apresentação do chart

Mostrar base, ligações e destinos com miniaturas reais quando disponíveis, ou rótulo honesto de brief quando não houver arte. Diferenciar visualmente estágio, configuração e estado sem depender somente da cor. Em cada ficha, mostrar sua história curta, identidade herdada, mudança, ação, limitação proposta, referência e aprovação. Não usar só barras de ATK/SPD/INT para explicar design.

Um HTML offline é conveniente; aproveitar o piloto existente sem reaproveitar seu estado de save simulado, nomes, regras rígidas ou contagem fixa. Fonte e imagem devem ser navegáveis por teclado, possuir texto alternativo e margens legíveis. Validar links e fluxo; checagem de DOM não equivale a inspeção visual em navegador. Não contornar bloqueios de acesso de ferramentas.

Executar o helper a partir da raiz:

```text
python .agents/skills/soulmonsters-charts/scripts/validar_chart.py documentation/creatures/<familia>-chart-v<n>/chart.json
```

Ele valida estrutura e arquivos, não aprova lore ou design. Se a família antiga usa outro esquema, preservar o contrato ou adaptar conscientemente; não reescrever um chart existente só para satisfazer o helper.

## Pedidos que o agente deve resolver

- “Faça o chart do Mata Verde”: localizar identidade, abrir arte, pesquisar referências pertinentes e propor narrativa e formas próprias; não copiar as oito formas do Azulão.
- “Use um item para virar equino”: cabeça e focinho equinos, pipa na anatomia toda, continuidade seletiva; não manter bico por hábito.
- “A versão sombria fica na árvore?”: verificar história e tratar possessão como estado quando aplicável; não desbloquear recompensa saudável automaticamente.
- “Gostei só do corpo”: registrar aprovação parcial, editar o rosto e preservar o resto; não produzir outra família por conta própria.
- “Gere todos os designs”: executar a produção autorizada com um piloto primeiro e conferência entre formas; não entregar apenas uma lista de ideias nem inventar aprovações.
- “Suba para o Soulgen”: é etapa adicional; localizar contratos reais, preservar JSONs do autor e validar recortes/animação antes de afirmar integração.
