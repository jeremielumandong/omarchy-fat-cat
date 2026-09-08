const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.join(__dirname,'..');
test('release manifest agrees with service and contains safe native entry points',()=>{
 const m=JSON.parse(fs.readFileSync(path.join(root,'manifest.json'),'utf8'));
 assert.equal(m.schemaVersion,1);assert.equal(m.id,'arkane.fat-cat');assert.equal(m.license,'MIT');
 assert.deepEqual(m.kinds,['service','bar-widget']);
 assert.ok(fs.readFileSync(path.join(root,'Service.qml'),'utf8').includes(`readonly property string version: "${m.version}"`));
 for(const file of Object.values(m.entryPoints)) {assert.ok(!path.isAbsolute(file)&&!file.split('/').includes('..'));assert.ok(fs.statSync(path.join(root,file)).isFile());}
 for(const file of ['README.md','LICENSE','RELEASE.md','assets/GENERATION.md'])assert.ok(fs.statSync(path.join(root,file)).isFile());
});
test('distribution contains no symlinks',()=>{
 function visit(dir){for(const name of fs.readdirSync(dir)){if(name==='.git')continue;const p=path.join(dir,name),s=fs.lstatSync(p);assert.ok(!s.isSymbolicLink(),p);if(s.isDirectory())visit(p);}}
 visit(root);
});
