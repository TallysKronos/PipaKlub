// Artwork slicing now lives in build-tree-kit.py. No procedural tree drawing.
import {spawnSync} from 'node:child_process';
const r=spawnSync(process.env.PIXEL_PYTHON||'python',['tools/plant-lab/build-tree-kit.py'],{stdio:'inherit'});process.exit(r.status??1);
