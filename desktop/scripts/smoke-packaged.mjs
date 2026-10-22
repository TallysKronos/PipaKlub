import {spawn} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const repo=fileURLToPath(new URL('../../',import.meta.url)),executable=path.join(repo,'dist','steam','PipaKlub-win32-x64','PipaKlub.exe'),offline=process.argv.includes('--offline');
const child=spawn(executable,['--smoke-test',...(offline?['--offline']:[])],{cwd:path.dirname(executable),windowsHide:true,stdio:['ignore','pipe','pipe']});
let output='';child.stdout.on('data',b=>output+=b);child.stderr.on('data',b=>process.stderr.write(b));
const timeout=setTimeout(()=>{child.kill();console.error('Packaged smoke timed out.');process.exitCode=1;},45000);
child.on('error',error=>{clearTimeout(timeout);console.error(error.message);process.exitCode=1;});
child.on('exit',code=>{clearTimeout(timeout);const line=output.split(/\r?\n/).find(l=>l.startsWith('{"desktopSmoke"'));let report;try{report=JSON.parse(line);}catch{}
 if(code!==0||!report?.desktopSmoke||report.offline!==offline){console.error(output||'Packaged smoke produced no report.');process.exitCode=1;}else console.log('Packaged PipaKlub.exe:',JSON.stringify(report));
});
