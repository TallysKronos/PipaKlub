# Alvacordo — referência de ataque via ComfyUI H3

Sprite de batalha aprovado usado como referência única, sem alterar o master. Referência576×576 com fundo magenta, ampliada3× no Aseprite. Uma direção3/4 para esquerda; direita pode ser espelhada depois.

## Movimento solicitado

0–0,5s: pose pronta.0,5–1,2s: antecipação, joelhos e cotovelos recolhem.1,2–2,2s: corte diagonal com arco do braço próximo.2,2–2,8s: contragolpe curto com o outro arco.2,8–3,5s: seguimento de cauda/rabiola.3,5–4,7s: recuperação.Último trecho: pose inicial. Câmera fixa, sem efeitos cobrindo o corpo, sem giros ou deslocamento do personagem pelo quadro. Âncoras da imagem no primeiro e último frame.

## Geração

Job f7a0ee9c-bdbe-416b-b015-c354c9a84f34 no ComfyUI local127.0.0.1:8188. H3 ref2va int8 convrot, encoder qwen3vl32b nvfp4 awq,16steps, seed2026110501,512×512,124frames a24fps (~5,17s). Fluxo de Kael já existente adaptado; modelo e nodes conferidos no servidor. Workflow validado: zero erros/avisos, sem nodes parceiros ou cobrança de API. Memória dos modelos foi liberada antes de enviar; fila estava vazia. CPU/GPU offload segue a configuração existente do ComfyUI.

workflows/attack-local.json é reproduzível; prompt.txt preserva a instrução exata. status.json registra somente este job. collect_poses.py consulta sua conclusão, baixa apenas seu vídeo, extrai14poses PNG integrais e faz poses/contact-sheet.png com tempos. PNGs e vídeo são referências brutas geradas; não são sprites limpos nem animação aprovada. Não há recorte/resize individual das poses nem importação automática no jogo/Soulgen.

O coletor tem limite3horas, não cancela jobs e não toca outros trabalhos do ComfyUI. Se o prazo expirar, execute novamente depois. O FFmpeg existente é reaproveitado da pasta temporária do checkout pipa-club-pip88 quando não existir neste checkout. A extração pode terminar depois da resposta no chat; aprovação e limpeza artística ficam pendentes até inspecionar o resultado.
