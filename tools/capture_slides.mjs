/** Render the course HTML locally and record the precise positions of the R plots. */
import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const build = path.resolve(process.argv[2] || path.join(root, 'output', 'export-work'));
const source = path.resolve(process.argv[3] || path.join(root, 'presentation.html'));
const require = createRequire(import.meta.url);
const {chromium} = require('playwright');
const browserPath = process.env.CHROME_PATH;
const browser = await chromium.launch({ headless: true, ...(browserPath ? {executablePath: browserPath} : {}) });
try {
  await fs.mkdir(build, {recursive: true});
  const page = await browser.newPage({viewport: {width: 1280, height: 720}, deviceScaleFactor: 1});
  const exceptions = [];
  const external = [];
  page.on('pageerror', error => exceptions.push(error.message));
  await page.route(/^https?:/, route => {
    external.push(route.request().url());
    return route.abort();
  });
  await page.goto(pathToFileURL(source).href);
  await page.waitForFunction(() => window.slideshow && document.querySelector('.remark-visible .remark-slide-content'));
  await page.evaluate(() => document.fonts.ready);
  const total = await page.evaluate(() => slideshow.getSlideCount());
  const slides = [];
  for (let index = 1; index <= total; index++) {
    await page.evaluate(n => slideshow.gotoSlide(n), index);
    await page.waitForFunction(n => [...document.querySelectorAll('.remark-slides-area > .remark-slide-container')][n-1]?.classList.contains('remark-visible'), index);
    await page.evaluate(async () => {
      await Promise.all([...document.querySelectorAll('.remark-visible img')].map(img => img.decode()));
      await document.fonts.ready;
    });
    const layout = await page.evaluate(() => {
      const el = document.querySelector('.remark-visible .remark-slide-content');
      const box = el.getBoundingClientRect();
      const relative = node => {
        const r = node.getBoundingClientRect();
        return {x:(r.left-box.left)/box.width, y:(r.top-box.top)/box.height, w:r.width/box.width, h:r.height/box.height};
      };
      const alerts = [...el.querySelectorAll('h1,h2,p,figure,img,a,td,th')].filter(node => {
        const b = relative(node);
        return b.w && b.h && (b.x < -.005 || b.y < -.005 || b.x+b.w > 1.005 || b.y+b.h > 1.005);
      }).map(node => node.tagName+' '+(node.textContent||node.alt||'').slice(0,100));
      return {
        title: el.querySelector('h1,h2')?.textContent.trim() || el.innerText.split('\n')[0],
        text: el.innerText,
        width: el.offsetWidth, height: el.offsetHeight, alerts,
        images: [...el.querySelectorAll('img')].map(img=>({alt:img.alt, asset:img.dataset.asset || img.dataset.figure || img.closest('[data-asset]')?.dataset.asset || '', ...relative(img)}))
      };
    });
    slides.push(layout);
    await page.screenshot({path:path.join(build,'screen-'+String(index).padStart(2,'0')+'.png'),animations:'disabled'});
  }
  const {width:w,height:h}=slides[0];
  await page.addStyleTag({content:
    '@page{size:'+w+'px '+h+'px;margin:0;} @media print{'+
    'html,body{margin:0!important;padding:0!important;width:'+w+'px!important;}'+
    '.remark-slides-area{position:static!important;width:'+w+'px!important;height:auto!important;}'+
    '.remark-slides-area>.remark-slide-container{display:block!important;position:relative!important;width:'+w+'px!important;height:'+h+'px!important;page-break-after:always!important;break-after:page!important;}'+
    '.remark-slides-area>.remark-slide-container:last-child{page-break-after:auto!important;break-after:auto!important;}'+
    '.remark-slide-scaler{position:relative!important;left:0!important;top:0!important;transform:scale(1)!important;transform-origin:0 0!important;box-shadow:none!important;}'+
    '.remark-slide-content{-webkit-print-color-adjust:exact!important;print-color-adjust:exact!important;}'+
    '.remark-notes-area,.remark-preview-area,.remark-toolbar{display:none!important;}}'
  });
  await page.pdf({path:path.join(build,'browser.pdf'),printBackground:true,preferCSSPageSize:true,displayHeaderFooter:false,margin:{top:0,bottom:0,left:0,right:0}});
  await fs.writeFile(path.join(build,'slides.json'),JSON.stringify({total,slides,exceptions,external},null,2));
  if (exceptions.length || external.length || slides.some(s => s.alerts.length)) {
    throw new Error('Offline read or layout check failed. See slides.json.');
  }
  console.log('Rendered '+total+' slides without external requests or out-of-frame elements.');
} finally {
  await browser.close();
}
