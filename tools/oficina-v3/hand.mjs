// Original 2D glove. The reference informs only the open / grip gestures.
export function drawCraftHand(g,grip=0){
 const k=Math.max(0,Math.min(1,grip)),ease=k*k*(3-2*k);
 g.save();g.lineCap='round';g.lineJoin='round';g.strokeStyle='#214b4b';g.lineWidth=2.2;
 // Four fingers curl toward the palm, with their knuckles still readable.
 const fingers=[[-13,23],[-4,33],[5,29],[13,20]];
 for(const [x,length] of fingers){const top=-length*(1-ease)-4*ease;
  g.beginPath();g.moveTo(x-4,9);g.lineTo(x-4,top+4);g.quadraticCurveTo(x-4,top-3,x+1,top-3);g.quadraticCurveTo(x+5,top-3,x+5,top+4);g.lineTo(x+5,12);g.closePath();g.fillStyle='#fff2cd';g.fill();g.stroke();
 }
 // Palm covers finger roots, keeping the silhouette joined throughout the curl.
 g.beginPath();g.moveTo(-17,1);g.quadraticCurveTo(-20,13,-11,24);g.quadraticCurveTo(0,30,14,22);g.quadraticCurveTo(20,11,17,0);g.fillStyle='#fff2cd';g.fill();g.stroke();
 // Thumb moves from an open side reach to a fold across the grip.
 g.beginPath();g.moveTo(-12,19);g.quadraticCurveTo(-23+ease*8,16-ease*8,-27+ease*24,4+ease*2);g.quadraticCurveTo(-28+ease*25,-3+ease*5,-23+ease*24,-2+ease*3);g.lineTo(-13+ease*18,10-ease*5);g.quadraticCurveTo(-6,10,-9,18);g.fillStyle='#f3ddb1';g.fill();g.stroke();
 g.strokeStyle='#d1b987';g.lineWidth=1.2;g.beginPath();g.moveTo(-5,18);g.quadraticCurveTo(1,21,8,16);g.stroke();
 // Teal cuff and gold seam tie the cursor to the workshop's palette.
 g.fillStyle='#438d82';g.strokeStyle='#214b4b';g.lineWidth=2.2;g.beginPath();g.roundRect(-12,24,27,9,3);g.fill();g.stroke();g.strokeStyle='#e2ba68';g.lineWidth=1.3;g.beginPath();g.moveTo(-8,28);g.lineTo(11,28);g.stroke();
 g.restore();
}
