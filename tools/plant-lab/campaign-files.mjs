import {createHash, randomUUID} from 'node:crypto';
import fs from 'node:fs/promises';
import {moveCampaignDecoration, paintCampaignFloor} from './isometric.mjs';

export const revisionOf = raw => createHash('sha256').update(raw).digest('hex');
const fail = (status, message) => Object.assign(new Error(message), {status});
const saving = new Set();

export async function saveCampaignMap(file, {revision, edits} = {}) {
  if (!Array.isArray(edits) || !edits.length || edits.length > 10000) {
    throw fail(400, 'Envie de 1 a 10.000 alterações.');
  }
  if (saving.has(file)) throw fail(409, 'Já existe um salvamento para este mapa. Tente novamente.');
  saving.add(file);
  const temporary = file + '.' + randomUUID() + '.tmp';
  try {
    const raw = await fs.readFile(file, 'utf8');
    if (revisionOf(raw) !== revision) throw fail(409, 'O mapa mudou no disco. Exporte sua cópia antes de reabrir.');
    const map = JSON.parse(raw);
    if (map.schema !== 'overworld-godot-1') throw fail(404, 'Mapa fora do catálogo isométrico.');
    for (const edit of edits) {
      const accepted = edit?.type === 'floor' && Number.isInteger(edit.index)
        ? paintCampaignFloor(map, edit.index, edit.material)
        : edit?.type === 'decoration' && moveCampaignDecoration(map, edit.id, edit.u, edit.v);
      if (!accepted) throw fail(422, 'Uma alteração está fora dos limites de edição da campanha.');
    }
    const separator = raw.includes('\r\n') ? '\r\n' : '\n';
    const indent = raw.match(/\r?\n([ \t]+)"/)?.[1];
    const next = JSON.stringify(map, null, indent).replaceAll('\n', separator)
      + (raw.endsWith('\n') ? separator : '');
    await fs.writeFile(temporary, next, {flag: 'wx'});
    if (revisionOf(await fs.readFile(file, 'utf8')) !== revision) {
      throw fail(409, 'O mapa mudou no disco. Exporte sua cópia antes de reabrir.');
    }
    await fs.rename(temporary, file);
    return {revision: revisionOf(next)};
  } finally {
    try { await fs.rm(temporary, {force: true}); }
    finally { saving.delete(file); }
  }
}
