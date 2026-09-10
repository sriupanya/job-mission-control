const fs=require('fs');const assert=require('node:assert/strict');
const {JSDOM}=require(process.env.STUDIO_JSDOM||'jsdom');
const dom=new JSDOM(fs.readFileSync('index.html','utf8'),{url:'https://studio.example/',runScripts:'outside-only'});
const w=dom.window;w.SUPABASE_URL='https://test.example';w.SUPABASE_PUBLISHABLE_KEY='test';w.HTMLElement.prototype.scrollIntoView=function(){};w.HTMLElement.prototype.scrollTo=function(){};w.HTMLDialogElement.prototype.showModal=function(){this.open=true};w.HTMLDialogElement.prototype.close=function(){this.open=false};w.matchMedia=()=>({matches:false});w.createClient=()=>({auth:{getSession:async()=>({data:{session:null}}),onAuthStateChange(){}}});w.assert=assert;
let code=fs.readFileSync('app.js','utf8').replace(/^import.*$/mg,'');
code=code.replace(/^const tokenParams=.*$/mg,'').replace(/^sb.auth.onAuthStateChange.*$/mg,'');
const cases=`
state.data={jobs:[{id:'j1',company:'Test Company',title:'Applied AI Lead',status:'Review',fit_score:8,apply_url:'javascript:alert(1)',job_req:'TEST1'},{id:'j2',company:'Other',title:'AI Product',status:'Hiring Manager',fit_score:9}],contacts:[],companies:[],outreach:[],application_updates:[],personal_projects:[],project_job_links:[],contact_job_links:[],daily_actions:[{id:'a1',action_date:'2026-09-09',action_type:'Apply',job_id:'j1',rank:1,title:'Review role',score:80}],scoring_rules:{version:1}};
studio.user={id:'test'};studio.events=[];
for(const tab of tabs){state.tab=tab;render();assert.ok(el('content').textContent.length>10,tab+' renders');}
state.tab='Jobs';render();assert.equal(el('content').querySelector('a').getAttribute('href'),'#','Unsafe URL rejected');
assert.ok(el('content').querySelector('[data-job]'),'Role detail control');openJob('j1');assert.equal(el('detail').open,true);assert.ok(el('stageSelect'),'Stage editor renders');
state.tab='Interview Studio';render();assert.ok(el('scriptEditor').value.includes('['),'Visitor starts with templates');
studio.events=[{points:25,metadata:{key:actionKey(state.data.daily_actions[0])}}];assert.equal(isDone(state.data.daily_actions[0]),true);assert.equal(xp(),25);
const duplicate={...state.data.daily_actions[0],id:'different-id'};assert.equal(uniqueActions([...state.data.daily_actions,duplicate]).length,1);
assert.ok(appliedSet.has('Hiring Manager'));assert.ok(appliedSet.has('Final Interview'));
state.query='no-such-script';renderContent();assert.ok(el('content').textContent.includes('No matching scripts'));
console.log('PASS: 11 views, role details/stage editor, safe links, template isolation, XP, stable action deduplication, pipeline stages, script search.');
`;
try{w.eval(code+'\n'+cases)}catch(e){console.error(e);process.exitCode=1}finally{w.close()}
