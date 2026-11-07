import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = 'D:/data science/tmp/student-dropout-build/preview';
await fs.mkdir(output, {recursive:true});
const origin = 'http://127.0.0.1:9486';
let response;
for(let i=0;i<60;i++) {
  try { response = await fetch(origin+'/json/new?about:blank',{method:'PUT'}); break; }
  catch { await new Promise(r=>setTimeout(r,150)); }
}
if(!response?.ok) throw new Error('Preview browser did not start');
const target = await response.json();
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve,reject)=>{ws.addEventListener('open',resolve,{once:true});ws.addEventListener('error',reject,{once:true});});
let sequence=0;
const pending=new Map();
const failures=[];
const requested=[];
ws.addEventListener('message', e=>{
  const msg=JSON.parse(e.data);
  if(msg.id && pending.has(msg.id)) {
    const {resolve,reject,timer}=pending.get(msg.id);pending.delete(msg.id);clearTimeout(timer);
    msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
  }
  if(msg.method==='Runtime.exceptionThrown') failures.push(msg.params.exceptionDetails);
  if(msg.method==='Network.requestWillBeSent') requested.push(msg.params.request.url);
});
function call(method,params={}) {
  const id=++sequence;
  return new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>{pending.delete(id);reject(new Error('Timeout: '+method));},15000);
    pending.set(id,{resolve,reject,timer}); ws.send(JSON.stringify({id,method,params}));
  });
}
async function evaluate(expression) {
  const result=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
  if(result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}
try {
  await call('Page.enable'); await call('Runtime.enable'); await call('Network.enable');
  await call('Network.setBlockedURLs',{urls:['http://*','https://*']});
  await call('Emulation.setDeviceMetricsOverride',{width:1600,height:900,deviceScaleFactor:1,mobile:false});
  await call('Page.navigate',{url:'file:///D:/data%20science/student-dropout-final/presentation.html'});
  let ready=false;
  for(let i=0;i<80;i++) {
    await new Promise(r=>setTimeout(r,150));
    ready=await evaluate('typeof slideshow !== "undefined" && !!document.querySelector(".remark-visible")');
    if(ready) break;
  }
  if(!ready) throw new Error('Slideshow did not initialise offline');
  const total=await evaluate('slideshow.getSlideCount()');
  const metadata=[];
  for(let n=1;n<=total;n++) {
    await evaluate(`slideshow.gotoSlide(${n}); true`);
    await new Promise(r=>setTimeout(r,130));
    await evaluate('document.fonts.ready.then(()=>true)');
    const layout=await evaluate(`(()=>{
      const c=document.querySelector('.remark-visible .remark-slide-content');
      const b=c.getBoundingClientRect();
      const overflow=[...c.querySelectorAll('h1,h2,p,table,img,ul,.source,.takeaway')].map(x=>({
        tag:x.tagName, text:(x.innerText||x.alt||'').slice(0,100),r:x.getBoundingClientRect()
      })).filter(x=>x.r.bottom>b.bottom-13 || x.r.right>b.right-8 || x.r.left<b.left-2).map(x=>({tag:x.tag,text:x.text,bottom:x.r.bottom,right:x.r.right}));
      return {title:c.querySelector('h1')?.innerText,text:c.innerText,scrollHeight:c.scrollHeight,clientHeight:c.clientHeight,
        scrollWidth:c.scrollWidth,clientWidth:c.clientWidth,overflow};
    })()`);
    const screenshot=await call('Page.captureScreenshot',{format:'png',fromSurface:true});
    const file=`${output}/slide-${String(n).padStart(2,'0')}.png`;
    await fs.writeFile(file,Buffer.from(screenshot.data,'base64'));
    metadata.push({slide:n,file,...layout});
  }
  await fs.writeFile(output+'/slides.json',JSON.stringify({total,slides:metadata,failures,externalRequests:requested.filter(x=>/^https?:/.test(x))},null,2));
  if(process.argv.includes('--pdf')) {
    const dimensions=await evaluate(`(()=>{
      const h=document.querySelector('.remark-visible .remark-slide-content').clientHeight;
      const w=h*16/9;
      const style=document.createElement('style');
      style.textContent='@page{size:'+w+'px '+h+'px;margin:0;} @media print{'+
        'html,body{margin:0!important;padding:0!important;width:'+w+'px!important;}'+
        '.remark-slides-area{position:static!important;width:'+w+'px!important;height:auto!important;}'+
        '.remark-slides-area>.remark-slide-container{display:block!important;position:relative!important;width:'+w+'px!important;height:'+h+'px!important;page-break-after:always!important;break-after:page!important;}'+
        '.remark-slides-area>.remark-slide-container:last-child{page-break-after:auto!important;break-after:auto!important;}'+
        '.remark-slide-scaler{left:0!important;top:0!important;transform:scale(1)!important;transform-origin:0 0!important;box-shadow:none!important;}'+
        '.remark-slide-content{-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important;}'+
        '.remark-notes-area,.remark-preview-area,.remark-toolbar{display:none!important;}}';
      document.head.appendChild(style); return {width:w,height:h};
    })()`);
    const pdf=await call('Page.printToPDF',{printBackground:true,preferCSSPageSize:true,
      paperWidth:dimensions.width/96,paperHeight:dimensions.height/96,
      marginTop:0,marginBottom:0,marginLeft:0,marginRight:0,displayHeaderFooter:false});
    const pdfPath=root+'/output/pdf/Student_Dropout_Presentation.pdf';
    await fs.writeFile(pdfPath,Buffer.from(pdf.data,'base64'));
    console.log(JSON.stringify({pdf:pdfPath,logicalDimensions:dimensions}));
  }
  console.log(JSON.stringify({slides:total,exceptions:failures.length,externalRequests:requested.filter(x=>/^https?:/.test(x)),
    overflowSlides:metadata.filter(x=>x.overflow.length || x.scrollHeight>x.clientHeight+2).map(x=>({slide:x.slide,title:x.title,overflow:x.overflow,scrollHeight:x.scrollHeight,clientHeight:x.clientHeight}))},null,2));
} finally {
  try { await call('Browser.close'); } catch {}
  ws.close();
}
