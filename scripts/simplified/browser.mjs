/* Local browser integration: mock Auth identity transport, real migrated Postgres RPCs and RLS.
   No hosted keys, no remote writes. UI_CHROMIUM_PATH must point to an installed browser. */
import {db} from './database.mjs';
import http from 'node:http';import {spawn} from 'node:child_process';import assert from 'node:assert/strict';
import {chromium} from '../ui/node_modules/playwright/index.mjs';
const owner='11111111-1111-4111-8111-111111111111';
const user={id:owner,aud:'authenticated',role:'authenticated',email:'owner@example.test',app_metadata:{},user_metadata:{},created_at:'2026-01-01T00:00:00Z'};
await db.query('insert into auth.users(id,email,email_confirmed_at) values($1,$2,now())',[owner,user.email]);
console.log('STAGE auth fixture seeded');
const q=async(s,p=[]) => (await db.query(s,p)).rows;
let serial=Promise.resolve();const failures=[];
const api=http.createServer((req,res)=>{serial=serial.then(async()=>{
 try{let body='';for await(const chunk of req)body+=chunk;const input=body?JSON.parse(body):{};const url=new URL(req.url,'http://local');
 let result;if(url.pathname==='/auth/v1/user')result=user;
 else{
 const signed=(req.headers.authorization??'').includes('.test');
 await db.exec('reset role');await q("select set_config('request.jwt.claim.sub',$1,false),set_config('request.headers',$2,false)",[signed?owner:'',JSON.stringify(req.headers)]);await db.exec('set role '+(signed?'authenticated':'anon'));
 const schema=req.headers['accept-profile']??req.headers['content-profile'];assert.equal(schema,'academy','Data API uses academy schema');
 const name=url.pathname.split('/').pop();assert.match(name,/^[a-z_]+$/);
 if(url.pathname.startsWith('/rest/v1/rpc/')){
 const args=Object.keys(input);for(const a of args)assert.match(a,/^p_[a-z_]+$/);
 const call=args.map((a,i)=>`${a} => $${i+1}`).join(',');result=(await q(`select academy.${name}(${call}) result`,Object.values(input).map(v=>typeof v==='object'?JSON.stringify(v):v)))[0].result;
 }else{
 const predicates=[],values=[];for(const[key,value]of url.searchParams){if(['select','order','limit','offset'].includes(key)||key.includes('.'))continue;assert.match(key,/^[a-z_]+$/);const dot=value.indexOf('.'),op=value.slice(0,dot),v=value.slice(dot+1);if(op==='eq'){values.push(v);predicates.push(`${key}=$${values.length}`);}else if(op==='is')predicates.push(`${key} is ${v==='null'?'null':v==='true'?'true':'false'}`);else if(op==='in'){values.push('{'+v.slice(1,-1)+'}');predicates.push(`${key}=any($${values.length})`);}}
 result=await q(`select * from academy.${name}${predicates.length?' where '+predicates.join(' and '):''}`,values);res.setHeader('Content-Range',`0-${Math.max(0,result.length-1)}/${result.length}`);if(req.headers.accept?.includes('vnd.pgrst.object'))result=result[0]??null;
 }
 }
 if(url.pathname.includes('public_academic_directory'))console.log('DIRECTORY',Object.keys(result??{}),result?.classes?.length,req.headers['x-academy-public-branch']);if(url.pathname.includes('list_public_programme_offerings'))console.log('CATALOGUE',Array.isArray(result));
 res.writeHead(200,{'Content-Type':'application/json'});res.end(req.method==='HEAD'?'':JSON.stringify(result));
 }catch(e){failures.push(e.message);console.error('API',e.message);res.writeHead(400,{'Content-Type':'application/json'});res.end(JSON.stringify({message:e.message,code:e.code??'LOCAL_TEST'}));}
});});await new Promise(r=>api.listen(54321,'127.0.0.1',r));
console.log('STAGE API listening');
const app=spawn(process.execPath,['node_modules/next/dist/bin/next','start','-p','3100','--hostname','127.0.0.1'],{stdio:['ignore','pipe','pipe'],env:{...process.env,NEXT_PUBLIC_SUPABASE_URL:'http://127.0.0.1:54321',NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:'local-smoke-key'}});let appLog='';app.stdout.on('data',b=>appLog+=b);app.stderr.on('data',b=>{appLog+=b;console.error('NEXT',b.toString().slice(0,500))});
let browser;
try{
 for(let i=0;i<60;i++){try{const r=await fetch('http://127.0.0.1:3100/auth/sign-in',{signal:AbortSignal.timeout(1500)});if(r.ok)break;}catch{}await new Promise(r=>setTimeout(r,300));}
 console.log('STAGE launching browser',appLog.slice(-600));
 browser=await chromium.launch({executablePath:process.env.UI_CHROMIUM_PATH,args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const context=await browser.newContext({viewport:{width:1440,height:1000}});const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));const base='http://127.0.0.1:3100';
 const token=`eyJhbGciOiJIUzI1NiJ9.${Buffer.from(JSON.stringify({sub:owner,exp:Math.floor(Date.now()/1000)+3600,aud:'authenticated',role:'authenticated'})).toString('base64url')}.test`;
 const cookie='base64-'+Buffer.from(JSON.stringify({access_token:token,refresh_token:'mock-refresh',expires_at:Math.floor(Date.now()/1000)+3600,expires_in:3600,token_type:'bearer',user})).toString('base64url');await context.addCookies([{name:'sb-127-auth-token',value:cookie,url:base}]);
 console.log('STAGE opening branch selector');
 await page.goto(base+'/dashboard');await page.getByRole('heading',{name:'Branches',exact:true}).waitFor();
 await page.getByLabel('Institution name',{exact:true}).filter({visible:true}).fill('Browser Academy');await page.getByLabel('Branch name',{exact:true}).filter({visible:true}).fill('Central');await page.getByLabel('Unique branch URL slug').filter({visible:true}).fill('browser-central');await page.getByRole('button',{name:'Create branch and start'}).click();
 await page.locator('#erp-main').getByRole('heading',{name:'Digital Campus',exact:true}).waitFor();assert.equal(await page.locator('a[href^="/dashboard/finance"]').count(),0);console.log('PASS branch opening and Sohoj ERP dashboard with no finance navigation');
 await page.goto(base+'/dashboard/crm/manage');await page.getByRole('button',{name:'Programmes',exact:true}).click();await page.getByText('Junior Scholarship Programme',{exact:true}).first().waitFor();await page.getByText('SSC Preparation Programme',{exact:true}).first().waitFor();await page.getByText('HSC Preparation Programme',{exact:true}).first().waitFor();await page.getByText('Job Preparation Programme',{exact:true}).first().waitFor();console.log('PASS starter programmes displayed in original directory UI');
 await page.goto(base+'/branches');await page.getByLabel('Branch name',{exact:true}).filter({visible:true}).fill('North');await page.getByLabel('Unique branch URL slug').filter({visible:true}).fill('browser-north');await page.getByRole('button',{name:'Create branch and start'}).click();await page.locator('#erp-main').getByRole('heading',{name:'Digital Campus',exact:true}).waitFor();await page.getByRole('link',{name:'North ↗',exact:true}).waitFor();
 await page.goto(base+'/branches');await page.locator('form').filter({visible:true}).filter({has:page.getByRole('heading',{name:'Central',exact:true})}).getByRole('button',{name:'Select branch'}).click();await page.getByRole('link',{name:'Central ↗',exact:true}).waitFor();console.log('PASS sibling branch opening and verified branch switching');
 await page.goto(base+'/?branch=browser-central');await page.getByRole('button',{name:'বাংলা',exact:true}).filter({visible:true}).first().click();await page.locator('html[lang="bn-BD"]').waitFor();await page.reload();assert.equal(await page.locator('html').getAttribute('lang'),'bn-BD');console.log('PASS original public language toggle persists');
 await page.goto(base+'/interest?branch=browser-central');// Programmes are checkbox choices in the original form.
 await page.locator('#interest-class').waitFor();assert.equal(await page.locator('select[name=classId] option').count(),7);assert.equal(await page.locator('input[name=subjectIds]').count(),11);console.log('PASS original public interest form receives branch directory data');
 await page.screenshot({path:'/tmp/simplified-interest.png',fullPage:true});assert.deepEqual(errors,[]);assert.deepEqual(failures,[]);console.log('PASS browser integration with real SQL commands and no runtime errors');
}catch(e){console.error(appLog.slice(-2500));throw e;}finally{await browser?.close();app.kill('SIGTERM');await new Promise(r=>api.close(r));await db.close();}
