# Interior v2 no jogo

A cena `professor-home` usa os 22 recortes e pivôs do quadro-chave. Na janela de referência (1280 × 720), o ateliê e Kael são renderizados em 1× com filtro nearest. Os móveis usam a ordenação por pegada da cena, e os batentes do estoque passam à frente de quem cruza a soleira.

As coordenadas persistidas da sala continuam no espaço original. A projeção 2:1 e as colisões acompanham a nova planta, e posições antigas ocupadas por móveis são ajustadas para o piso livre mais próximo na abertura da cena. A oficina e seus pontos de retorno foram alinhados à mesa da maleta. A entrada e o retorno à Vila mantêm as posições da campanha.

- [Interior no jogo](depois.png), [atrás da bancada de pesquisa](atrás-da-bancada.png), [bancada de criação](bancada-de-criacao.png) e [soleira do estoque](estoque.png).
- [Concept, quadro-chave e captura da cena](../comparativo.png).

## Conferência

| Verificação | Resultado |
| --- | --- |
| Circulação, colisões, pontos de interação e profundidade | 86 verificações passaram. 4.130 posições amostradas alcançáveis, sem bolsões isolados. |
| Entrada por E e retorno à Vila pelo frontend | 11 verificações passaram. |
| E na mesa da maleta | Abriu a oficina pelo fluxo da campanha em um slot isolado. |
| Locomoção da Vila e dos interiores | 11 verificações passaram. |
| Fluxo de cuidado | 35 verificações passaram. |
| Arquivo de expedições e retomada de save | 17 verificações passaram. |
| Recompensas pendentes e campanha | 110 e 207 verificações passaram. |

As capturas usam o frontend real e um slot isolado. Os avisos de encerramento de algumas suítes ocorreram após as verificações de campanha.

Para reproduzir as capturas e a conferência de proximidade no frontend:

```powershell
godot --path godot --script tools/laboratorio_v2_interior_integracao.gd --rendering-method gl_compatibility
```
