const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
function alphaPixels(file) {
  const b = fs.readFileSync(file);
  assert.equal(b.subarray(1,4).toString(),'PNG');
  let w,h,raw=[];
  for(let o=8;o<b.length;) {
    const n=b.readUInt32BE(o), type=b.toString('ascii',o+4,o+8), data=b.subarray(o+8,o+8+n);
    if(type==='IHDR') {w=data.readUInt32BE(0);h=data.readUInt32BE(4);assert.equal(data[8],8);assert.equal(data[9],6,'sprite must have real RGBA transparency');assert.equal(data[12],0);}
    if(type==='IDAT') raw.push(data);
    o+=n+12;
  }
  assert.equal(w%4,0);assert.equal(h%6,0);assert.equal(w/4,h/6,'sprite cells must be square');
  const bytes=zlib.inflateSync(Buffer.concat(raw)), stride=w*4, pixels=Buffer.alloc(h*stride);
  function paeth(a,b,c){const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;}
  for(let y=0;y<h;y++) {
    const filter=bytes[y*(stride+1)];assert.ok(filter<=4);
    for(let x=0;x<stride;x++) {
      const i=y*stride+x,a=x>=4?pixels[i-4]:0,c=y&&x>=4?pixels[i-stride-4]:0,up=y?pixels[i-stride]:0;
      const add=[0,a,up,Math.floor((a+up)/2),paeth(a,up,c)][filter];pixels[i]=(bytes[y*(stride+1)+1+x]+add)&255;
    }
  }
  return {w,h,at:(x,y)=>pixels[(y*w+x)*4+3]};
}
for(const coat of ['orange','gray','calico','tuxedo']) test(`${coat} atlas has 24 usable transparent frames`,()=>{
  const p=alphaPixels(path.join(__dirname,'../assets',`cat-${coat}.png`)), size=p.w/4;
  for(let row=0;row<6;row++) for(let col=0;col<4;col++) {
    let opaque=0,transparent=0;
    for(let y=0;y<size;y++) for(let x=0;x<size;x++) {const a=p.at(col*size+x,row*size+y);if(a>200)opaque++;if(a<10)transparent++;}
    assert.ok(opaque>size*size*.1,`empty frame ${col},${row}`);
    assert.ok(transparent>size*size*.15,`painted background ${col},${row}`);
    assert.ok(p.at(col*size,row*size)<10,`opaque corner ${col},${row}`);
  }
});
