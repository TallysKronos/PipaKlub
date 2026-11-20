import { readFileSync,writeFileSync } from "node:fs";
import { pixelateImage,PixelationMode,CellColorPicker,OutlinePrepass,PixelationMethod } from "@xprite/pixelate";
const source=JSON.parse(readFileSync(new URL("./poses.json",import.meta.url)));
const candidates=[
 ["two-stage",{blockPicker:true,colorPicker:CellColorPicker.TwoStage}],
 ["pixeloe",{prepass:OutlinePrepass.Pixeloe, colorPicker:CellColorPicker.Contrast,blockPicker:true}],
 ["structure",{method:PixelationMethod.Structure,outlineStrength:35}],
];
for(const [label,settings] of candidates){
 const sheet={width:224,height:112,data:new Uint8ClampedArray(224*112*4)};
 for(let i=0;i<2;i++){
  const m=source[i];
  const image={width:m.width,height:m.height,data:new Uint8ClampedArray(readFileSync(new URL("./pose-"+i+".rgba",import.meta.url)))};
  const converted=pixelateImage(image,{mode:PixelationMode.Convert,targetSize:{width:m.targetWidth,height:m.targetHeight},...settings});
  const x0=i*112+56-Math.floor(converted.width/2), y0=100-converted.height;
  for(let y=0;y<converted.height;y++) for(let x=0;x<converted.width;x++){
   sheet.data.set(converted.data.subarray((y*converted.width+x)*4,(y*converted.width+x+1)*4),((y+y0)*224+x+x0)*4);
  }
 }
 const output=pixelateImage(sheet,{mode:PixelationMode.Convert, targetSize:{width:224,height:112},paletteSnap:{colors:20}});
 writeFileSync(new URL("./"+label+".rgba",import.meta.url),output.data);
 console.log(label,output.width,output.height);
}
