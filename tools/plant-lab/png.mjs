import {deflateSync} from 'node:zlib';
import {crc32} from './zip.mjs';
function chunk(type,data){const name=Buffer.from(type),out=Buffer.alloc(data.length+12);out.writeUInt32BE(data.length);name.copy(out,4);data.copy(out,8);out.writeUInt32BE(crc32(Buffer.concat([name,data])),data.length+8);return out;}
export function png({width,height,data}){const header=Buffer.alloc(13);header.writeUInt32BE(width);header.writeUInt32BE(height,4);header[8]=8;header[9]=6;const bytes=Buffer.from(data.buffer,data.byteOffset,data.byteLength),scan=Buffer.alloc(height*(width*4+1));for(let y=0;y<height;y++)bytes.copy(scan,y*(width*4+1)+1,y*width*4,(y+1)*width*4);return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(scan)),chunk('IEND',Buffer.alloc(0))]);}

