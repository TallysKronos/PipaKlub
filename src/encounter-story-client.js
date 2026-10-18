function rivalStoryPortrait(speaker){
 const rival=ART_CONFIG.designs?.rivals?.[speaker];if(!rival)return '';
 return '<img class="rival-story-art" src="'+escapeHTML(rival.url)+'" alt="" decoding="async" onerror="this.hidden=true">';
}
// Narrative follows the authoritative encounter result; it never grants progress or rewards.
function trailStoryMarkup(id,outcome='before',{confirmed=false,firstClear=false}={}){
 const story=trails.story(id);if(!story||outcome!=='before'&&!confirmed)return '';
 const quotes=story[outcome]||[],celebrate=id==='morro-5'&&outcome==='won'&&firstClear;
 return '<section class="encounter-story story-'+outcome+(celebrate?' neighborhood-finale':'')+'">'+(celebrate?'<div class="finale-kite" aria-hidden="true">◇</div><div class="eyebrow">Bairro concluído</div><h3>O Morro do Sol conhece seu nome</h3>':'')+quotes.map(([speaker,line])=>'<blockquote>'+rivalStoryPortrait(speaker)+'<div class="rival-speech"><b>'+escapeHTML(speaker)+'</b><p>“'+escapeHTML(line)+'”</p></div></blockquote>').join('')+(outcome==='before'?'<p class="rival-technique"><b>Jeito de voar</b> · '+escapeHTML(story.tactic)+'</p>':outcome==='won'?'<p class="next-place-hint">'+escapeHTML(story.nextHint)+'</p>':'')+'</section>';
}
function updateTrailStoryOutcome(id,result,status){
 const root=$('trailStoryOutcome');if(!root||status!=='saved'||!result)return;
 const key=id+'|'+result.won+'|'+result.firstClear;if(root.dataset.storyKey===key)return;root.dataset.storyKey=key;
 root.innerHTML=trailStoryMarkup(id,result.won?'won':'lost',{confirmed:true,firstClear:!!result.firstClear});
 if(id==='morro-5'&&result.won&&result.firstClear){if($('dialogTitle'))$('dialogTitle').textContent='Bons ventos, novo caminho!';if(typeof sfx==='function')sfx('cut');}
}
