import http from 'node:http';
import { readFile } from 'node:fs/promises';
const page = new URL('./preview.html', import.meta.url);
http.createServer(async (req,res) => {
  if (!['/', '/preview.html'].includes(req.url)) { res.writeHead(404).end(); return; }
  res.writeHead(200, {'content-type':'text/html; charset=utf-8'});
  res.end(await readFile(page));
}).listen(5235, '127.0.0.1', () => console.log('Soulgen review: http://127.0.0.1:5235/preview.html'));
