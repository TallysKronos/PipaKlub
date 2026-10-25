// Presentation follows the authoritative countdown; it never starts combat.
export function guardianPresentation(state,rival,maxLine=250){
 const active=!!state?.boss&&state.players?.length===2&&!!rival;
 const remaining=active&&state.phase==='countdown'?Math.max(0,state.phaseUntil-state.last):0;
 const intro=active&&state.phase==='countdown'&&remaining>=3200;
 const intent=state?.phase==='countdown'?'arrival':state?.phase==='intermission'?'quiet':rival?.signatureWindup>0?(rival.signatureWindup<=.45?'impact':'signature'):rival?.bossTelegraph>0?(rival.bossTelegraph>=.4?'strike':'charge'):rival?.bossRecovery>0?'opening':rival?.bossPhase===2?'rage':'watch';
 const messages={arrival:'O guardião desperta…',quiet:'O vento se aquieta.',signature:'Ruptura dos Canos · observe o círculo',impact:'Impacto! Guarda (G) ou esquiva',charge:'Protegido · prepare a esquiva',strike:'Investida armada · esquive quando o círculo fechar',opening:'Armação aberta · contra-ataque!',rage:'Fase 2 · defenda e busque a abertura',watch:'Protegido · aguarde uma abertura'};
 const maximum=Math.max(1,Number(maxLine)||250),health=Math.max(0,Math.min(maximum,Number(rival?.hp)||0));
 return {active,intro,stage:!intro?'hidden':remaining>6150?'arrive':remaining<3800?'leave':'hold',intent,message:messages[intent],maximum,health,percent:health/maximum*100,phase:rival?.bossPhase===2?2:1};
}
