# Fios do Princípio — one-shot de Tyler

Roteiro proposto a partir do rascunho do autor, expandido para 48 páginas narrativas em oito capítulos de seis páginas. O PDF contém uma página de roteiro por página futura de quadrinho, não arte final.

- `ROTEIRO.md`: versão editável completa, com roteiro, direção dos personagens, revisão de estilo, continuidade e plano de produção visual.
- `referencia-8-capitulos.png`: rascunho original preservado como referência narrativa.
- `render_roteiro.py`: gera o PDF de 48 páginas usando Python e ReportLab.
- PDF: `output/pdf/PipaKlub-Tyler-Fios-do-Principio-Roteiro-48-paginas-v1.pdf`, a partir da raiz do repositório.

Os nomes Rai e Platyx vêm do rascunho e permanecem provisórios; Grampo e o título são propostas. A versão registra a correção de estilo: menos ornamentos e facetas, formas mais simples e próximas ao desenho de aventura do projeto. Flautrevo conserva a identidade já existente. Não foram geradas novas imagens, não houve integração no jogo ou publicação.

## Gerar a edição de leitura

Na raiz do repositório, em um ambiente Python com ReportLab e as fontes Arial do Windows:

```powershell
python art/oneshot/tyler-fios-do-principio-v1/render_roteiro.py
```
