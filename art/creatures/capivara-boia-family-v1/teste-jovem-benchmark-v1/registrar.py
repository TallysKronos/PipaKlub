from pathlib import Path
import json,hashlib,shutil
from PIL import Image,ImageOps,ImageDraw,ImageFont
D=Path(__file__).resolve().parent
data=json.loads((D/'propostas.json').read_text(encoding='utf-8'))
reviews=[
'Quatro membros e três abas de rabiola legíveis. Corpo mais horizontal, propulsão traseira e dobras laterais distinguem a ação. A dobra ventral ainda não demonstra resgate; isso permanece intenção de brief. Cabeça mantém muita semelhança com a criança. Não é prova de mergulho animado.',
'Peito largo, quatro apoios (o distante parcialmente ocluído) e crescente integrado tornam a contenção mais evidente que em A. As pontas altas podem interferir na rotação da cabeça; exigem vista lateral e teste de recolhimento. Três abas visíveis. Recomendação de piloto pela leitura da função.',
'Duas pernas e dois braços, três abas da rabiola. Mudança de apoio é a mais expressiva. Porém os remos parecem apêndices presos aos punhos em vez de antebraços inteiramente reorganizados. Corrigir integração do membro antes de fechar design ou rig.'
]
sheet=Image.new('RGB',(1800,660),'#f7f5ef');draw=ImageDraw.Draw(sheet);font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',23)
for k,s in enumerate(data['proposals']):
 folder=D/s['id'];folder.mkdir(exist_ok=True);shutil.copy2(s['source'],folder/'concept.png')
 (folder/'prompt.txt').write_text(s['prompt'],encoding='utf-8')
 (folder/'brief.md').write_text('# '+s['name']+'\n\nDefinido: criança de água da família capivara. Observado: menta/marfim/petróleo, pés palmados, focinho rombo, quilha e três abas. Proposto: estágio jovem alternativo com ação e arquitetura próprias. Não decidido: nome, rota, receita e habilidades de jogo.\n\n'+s['detail']+'\n\nDireção: 45% criatura / 45% pipa funcional / 10% acabamento 2D mangá. Fonte de princípios: art/benchmarks/digimon-ultimate-mega-2026-11-04/. Nenhuma arte externa fornecida à geração.',encoding='utf-8')
 (folder/'revisao.md').write_text('# Conferência\n\n'+reviews[k]+'\n\nAcabamento limpo com algumas transições suaves: concept 2D, sem grade de pixel art validada. Fundo branco opaco intencional. Não aprovado, não recortado, não animado e não integrado.',encoding='utf-8')
 with Image.open(folder/'concept.png') as im:
  dimensions=list(im.size);mode=im.mode;thumb=ImageOps.contain(im.convert('RGB'),(570,520));sheet.paste(thumb,(k*600+(600-thumb.width)//2,70+(520-thumb.height)//2))
 draw.text((k*600+20,22),s['name'],font=font,fill='#143d46')
 manifest=dict(tool='image_gen.imagegen built-in',source=s['source'],sha256=hashlib.sha256((folder/'concept.png').read_bytes()).hexdigest(),dimensions=dimensions,mode=mode,background='white opaque',reference_role='Capiboia child-manga-v3: own identity reference only',external_generation_inputs=False,decision_status='proposed',production_status='concept',implementation_status='not_integrated')
 (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
sheet.save(D/'comparativo.png')
(D/'README.md').write_text('# Piloto de evolução jovem do Capiboia\n\nTrês alternativas de aplicação do benchmark Ultimate/Mega; não são três rotas canônicas já decididas. Preserva chart existente e Capibaluarte aprovado.\n\n![Comparativo](comparativo.png)\n\n- [A: mergulhador de resgate](a-mergulhador/concept.png): propulsão traseira, corpo horizontal, custo proposto de menor estabilidade parado.\n- [B: contensor de correnteza](b-quebra-corrente/concept.png): peito quebra-mar e base larga; custo proposto de manobra lenta. Recomendado para aprofundar pela clareza funcional.\n- [C: condutor de canais](c-condutor/concept.png): postura semiereta e membros-remo, precisão em troca de velocidade; precisa integrar melhor antebraço e membrana.\n\nCada pasta conserva brief, prompt, revisão e manifesto. Apenas concepts estáticos, sem mudança no jogo. Artes geradas pela ferramenta integrada; só a arte autoral da criança entrou como input.',encoding='utf-8')
print('Salvos: três concepts, comparativo, briefs, prompts, revisões e manifestos.')
# Reaplica a decisão do autor depois de reconstruir os registros do piloto.
hook=D.parents[3]/'documentation/creatures/capivara-boia-chart-v1/aplicar_alternativas_aprovadas.py'
exec(compile(hook.read_text(encoding='utf-8'),str(hook),'exec'),{'__file__':str(hook)})
