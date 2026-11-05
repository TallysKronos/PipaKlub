"""Adapta o publicador local; não usa rede nem gera artes."""
from pathlib import Path
import json,re
D=Path(__file__).resolve().parent
s=(D.parent/'digimon-baby-rookie-2026-11-04/build.py').read_text(encoding='utf-8')
s=s.replace('28','40').replace('len(cases)==40','len(cases)==40')
s=s.replace("stage='rookie' if i['level']=='Rookie' else ('baby2' if 'Ⅱ' in i['level'] else 'baby1')", "stage=i['level'].lower()")
s=s.replace("dict(baby1=6,baby2=8,rookie=14)","dict(ultimate=20,mega=20)")
s=s.replace("{'baby1':'Baby I / In-Training I','baby2':'Baby II / In-Training II','rookie':'Rookie'}", "{'ultimate':'Ultimate','mega':'Mega'}")
s=s.replace("['id','name','level','architecture','image','anatomia','apoio','principio']", "['id','name','level','architecture','image','anatomia','pose','principio']")
s=s.replace("['anatomia','apoio','principio']", "['anatomia','pose','principio']")
s=s.replace("f'**Apoio/ação:** {c[\"apoio\"]}',f'**Expressão:** {c[\"expressao\"]}'", "f'**Matéria:** {c[\"material\"]}',f'**Função:** {c[\"funcao\"]}',f'**Pose:** {c[\"pose\"]}'")
s=s.replace('40 fichas — Baby I, Baby II e Rookie','40 fichas — Ultimate e Mega')
s=s.replace('Baby e Rookie · estudo de construção','Ultimate e Mega · anatomia da especialização')
s=s.replace('Antes de crescer,<br>uma criatura precisa ter vida.','Evoluir é mudar<br>o que o corpo consegue fazer.')
s=s.replace('40 estudos oficiais: 6 Baby I, 8 Baby II e 14 Rookie. Anatomia, matéria, apoio, expressão e mudança de capacidade.', '40 estudos oficiais: 20 Ultimate e 20 Mega. Anatomia, armadura, função, gesto, identidade e transformação.')
s=s.replace('Arquiteturas, não uma fórmula de fofura','Quarenta maneiras de especializar um corpo')
s=s.replace('<option value="baby1">Baby I · 6</option><option value="baby2">Baby II · 8</option><option value="rookie">Rookie · 14</option>', '<option value="ultimate">Ultimate · 20</option><option value="mega">Mega · 20</option>')
s=s.replace('O bebê atual da capivara permanece rejeitado, sem substituição por outro concept nesta etapa.', 'Jovem/adulto é nossa analogia de projeto, não equivalência automática de estágios. Nenhum concept aprovado foi alterado.')
s=s.replace('Aplicar à capivara','Aplicar aos nossos charts').replace('APLICACAO-CAPIVARA.md','APLICACAO-SOULMONSTERS.md').replace('FICHA-DE-CRIACAO.md','MATRIZ-DE-CRIACAO.md').replace('Ficha reutilizável para criação','Matriz e exercícios de criação')
s=s.replace('range(1,6)','range(1,8)').replace('40 artes, cinco folhas comparativas e oito inspeções individuais','40 artes: 33 vistas em seis folhas iniciais e sete individualmente; sete folhas finais normalizadas')
# Inclui as fichas inteiras também em HTML, mantendo o Markdown para edição.
s=s.replace("<footer><p>Arte oficial", "<section class=\"reading\" id=\"fichas\"><h2>Fichas aprofundadas</h2>'''+markdown('FICHAS.md')+'''</section><footer><p>Arte oficial")
s=s.replace('href="FICHAS.md#','href="#')
# Links de cartão devem alcançar âncoras HTML válidas, preservadas pelo renderizador.
s=s.replace("elif l.startswith('#'):", "elif l.startswith('<a id='):\n   flush();out.append(l)\n  elif l.startswith('#'):")
# Evita IDs duplicados entre resumo e ficha aprofundada.
s=s.replace("<article id=\"{c[\"id\"]}\"", "<article id=\"card-{c[\"id\"]}\"")
(D/'build.py').write_text(s,encoding='utf-8')
p=D/'ANALISE.md';t=p.read_text(encoding='utf-8').replace(' Oito referências adicionais de detalhe foram revisitadas antes da redação final.','');p.write_text(t,encoding='utf-8')
# A coleta reproduz exatamente a amostra final, sem os aliases que falharam.
p=D/'coletar.py';t=p.read_text(encoding='utf-8');ids=[c['id'] for c in json.loads((D/'fichas.json').read_text(encoding='utf-8'))];t=re.sub(r"SLUGS=.*?\.split\(\)","SLUGS="+repr(' '.join(ids))+'.split()',t,count=1);p.write_text(t,encoding='utf-8')
