# Laboratório v2 · Etapa 1: portão de silhueta

## Entrega para aprovação

| Vista | Maquete no Godot, 2:1 | Contornos sobre o concept |
| --- | --- | --- |
| Fachada | [blockout.png](fachada/blockout.png) | [blockout-sobre-concept.png](fachada/blockout-sobre-concept.png) |
| Interior | [blockout.png](interior/blockout.png) | [blockout-sobre-concept.png](interior/blockout-sobre-concept.png) |

As sobreposições identificam os volumes F1–F9 e I1–I10 na câmera original do concept, a partir dos próprios recortes. A maquete traduz os volumes para a projeção 2:1 do Godot. As câmeras são diferentes; a sobreposição não é uma comparação de pixels ou de acabamento.

## Régua e lote

- Base: `claude/unificacao`, cf1706a6, atualizada em 14/11/2026.
- Lote de `lote/LOTE.md`: u 0,5..14, v −10..−1, 13,5 × 9 células, terreno +48 px.
- Entrada alinhada a (7,25; −1); 1 célula livre na frente do acesso.
- Célula: 64 × 32 px. Kael com textura original, sem escala adicional, referência de 70 px.
- Três degraus de 8 px e patamar de 24 px; porta de 92 px.
- Fachada: duas coberturas curvas desniveladas, torre alta, pórtico recuado, acesso, pátio com cabine e instrumentos distintos no telhado.
- Interior: primeiro o aparelho I1 com suporte de arcos, depois I2 e a planta por zonas. Altura do aparelho aproximadamente 151 px a partir do piso; centro com 200 px de pé-direito.

Amostras de cor da ficha são materiais do concept. A pintura final usará a régua de acabamento dos personagens conforme o guia, após a aprovação dos volumes.

## Revisão de volumes

| Grupo | Representação nesta etapa |
| --- | --- |
| F1/F2/F3 | Duas abóbadas com borda, torre com losango e pórtico vazado |
| F4 | Escada, rampa, corrimãos, balizadores e faixa frontal livre |
| F5/F6 | Faixas de vidro e painel de transição, ainda sem conteúdo miúdo nas janelas |
| F7 | Pátio com cerca, cabine facetada com mesa/computador, mesa com maleta e marcador do cone |
| F8/F9 | Arco, anemômetro e massas de vegetação |
| I1/I2 | Losango gigante sobre bancada em arcos, janela alta e pé-direito duplo |
| I3/I4 | Recepção, monitor, carrinho, massas de plantas, estante e quadro |
| I5/I6/I7 | Bancada, monitores, banqueta, armário e zona de estoque público |
| I8/I9/I10 | Mesa de maleta aberta/sensor, vidro/capacho e duas abóbadas em corte |

Caixas cinza representam equipamentos, plantas e pequenos props. Flores, caixilhos secundários, alambrado, cabo do sensor e conteúdo das janelas serão desenhados no quadro-chave; este não é o checklist de arte final da etapa 2.

## Reprodução e verificação

Gerador versionado: `godot/tools/laboratorio_v2_blockout.gd`. Executar a partir da raiz do checkout:

```powershell
godot --path godot --script tools/laboratorio_v2_blockout.gd --rendering-method gl_compatibility
```

O script lê diretamente o PNG original de Kael e os recortes do concept, desenha os volumes no Godot e salva as quatro capturas. Conferência visual das quatro imagens concluída: imagens preenchidas, Kael visível em ambas as maquetes, torre e coberturas separadas, peça central legível e contornos identificados sobre os recortes. O gerador terminou com código 0. O ambiente restrito emitiu avisos de gravação do cache do Godot; as capturas foram gravadas e abertas normalmente.

A cena de produção e os dados de gameplay não são alterados por esta maquete. Integração, colisões e teste de percurso jogável pertencem à etapa 4 do pipeline.

## Parada

**Aguardando aprovação da silhueta da fachada e da planta/corte do interior.** Depois desse portão: extensão da paleta e loja-piloto, com seu próprio portão. Regiões somente após ambos aprovados. Quadro-chave e kit do laboratório permanecem sujeitos aos portões específicos do pipeline.
