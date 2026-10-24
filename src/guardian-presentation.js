// Presentation follows the authoritative countdown; it never starts combat.
export function guardianPresentation(state,rival,maxLine=190){
 const active=!!state?.boss&&state.players?.length===2&&!!rival;
 const remaining=active&&state.phase==='countdown'?Math.max(0,state.phaseUntil-state.last):0;
 const intro=active&&state.phase==='countdown'&&remaining>=3200;
 const intent=state?.phase==='countdown'?'arrival':state?.phase==='intermission'?'quiet':rival?.bossTelegraph>0?'charge':rival?.bossRecovery>0?'opening':rival?.bossPhase===2?'rage':'watch';
 const messages={arrival:'O guardião desperta…',quiet:'O vento se aquieta.',charge:'Golpe iminente · prepare a esquiva',opening:'Armação aberta · contra-ataque!',rage:'Fase 2 · o vento se intensificou',watch:'Fase 1 · observe a vela'};
 const maximum=Math.max(1,Number(maxLine)||190),health=Math.max(0,Math.min(maximum,Number(rival?.hp)||0));
 return {active,intro,stage:!intro?'hidden':remaining>6150?'arrive':remaining<3800?'leave':'hold',intent,message:messages[intent],maximum,health,percent:health/maximum*100,phase:rival?.bossPhase===2?2:1};
}
