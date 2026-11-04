import {execFileSync} from 'node:child_process';import fs from 'node:fs';
const base=process.argv[2];if(!base)throw Error('ComfyUI URL required.');
const out='art/concepts/montaria-doberman/animation-v1',m=JSON.parse(fs.readFileSync(out+'/manifest.json'));
for(const action of ['walk','run'])for(const shot of m.shots.filter(s=>s.action===action&&!s.promptId)){
 process.stdout.write(execFileSync(process.execPath,['tools/soulgen-studio/run-mount-motion.mjs',base,'submit',shot.id,'--allow-owned-queue'],{encoding:'utf8',stdio:['ignore','pipe','pipe']}));
}
