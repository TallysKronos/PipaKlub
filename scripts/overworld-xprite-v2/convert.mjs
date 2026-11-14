import { readFileSync,writeFileSync,existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import { pixelateImage,PixelationMode,CellColorPicker } from "../../tmp/xprite-azulfazo/node_modules/@xprite/pixelate/dist/index.js";

const root=fileURLToPath(new URL("../../",import.meta.url));
const scratch=resolve(root,"tmp/overworld-xprite-v2");
const rows=JSON.parse(readFileSync(resolve(scratch,"batch.json"),"utf8"));
for(const [index,row] of rows.entries()){
    if(row.method==="native-drawing") continue;
    const output=resolve(scratch,row.id+"-xprite.rgba");
    if(existsSync(output)){console.log("cached",row.id);continue;}
    const sheet={width:224,height:112,data:new Uint8ClampedArray(224*112*4)};
    for(let i=0;i<2;i++){
        const pose=row.poses[i];
        const image={
            width:pose.width,height:pose.height,
            data:new Uint8ClampedArray(readFileSync(resolve(scratch,row.id+"-"+i+".rgba")))
        };
        const converted=pixelateImage(image,{
            mode:PixelationMode.Convert,
            blockPicker:true,colorPicker:CellColorPicker.TwoStage,
            targetSize:{width:pose.targetWidth,height:pose.targetHeight}
        });
        const left=i*112+56-Math.floor(converted.width/2);
        const top=100-converted.height;
        for(let y=0;y<converted.height;y++){
            const first=y*converted.width*4;
            sheet.data.set(converted.data.subarray(first,first+converted.width*4),((y+top)*224+left)*4);
        }
    }
    const final=pixelateImage(sheet,{
        mode:PixelationMode.Convert,targetSize:{width:224,height:112},
        paletteSnap:{colors:20}
    });
    writeFileSync(output,final.data);
    console.log(index+1,row.id,row.targetHeight);
}
