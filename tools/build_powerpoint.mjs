// Rebuild the existing visual evidence as editable PowerPoint paths/text/tables.
// No statistical results are calculated here; the R/PDF source remains authoritative.
import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
process.on('uncaughtException',error=>{console.error(error.message);process.exit(1);});
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const build=process.argv[2] ?? path.join(root,'..','tmp','student-dropout-pptx-build');
const runtime='C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies';
const {Presentation,PresentationFile}=await import(pathToFileURL(path.join(runtime,'node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs')).href);
const data=JSON.parse(await fs.readFile(path.join(build,'source-layout.json'),'utf8'));
const presentation=Presentation.create({slideSize:{width:1280,height:720}});
const spacing=[];
let counter=0;
for(const page of data.slides){
  const slide=presentation.slides.add(); slide.background.fill='#080A0F';
  for(const item of [...page.elements.filter(e=>e.type!=='table'),...page.elements.filter(e=>e.type==='table')]){
    const name=`source-${page.number}-${++counter}`;
    if(item.type==='image'){
      slide.images.add({blob:Buffer.from(item.data,'base64'),contentType:'image/png',alt:'Original source artwork',
        position:{left:item.x,top:item.y,width:item.w,height:item.h},fit:'contain'});
    }else if(item.type==='path'){
      const points=item.commands.flatMap(c=>c.moveTo?[c.moveTo]:c.lineTo?[c.lineTo]:c.cubicBezTo?[
        {x:c.cubicBezTo.x1,y:c.cubicBezTo.y1},{x:c.cubicBezTo.x2,y:c.cubicBezTo.y2},{x:c.cubicBezTo.x,y:c.cubicBezTo.y}]:[]);
      if(!points.length)continue;
      const x=Math.min(...points.map(p=>p.x)),y=Math.min(...points.map(p=>p.y));
      const w=Math.max(.05,Math.max(...points.map(p=>p.x))-x),h=Math.max(.05,Math.max(...points.map(p=>p.y))-y);
      const commands=item.commands.map(c=>{
        if(c.moveTo)return {moveTo:{x:c.moveTo.x-x,y:c.moveTo.y-y}};
        if(c.lineTo)return {lineTo:{x:c.lineTo.x-x,y:c.lineTo.y-y}};
        if(c.cubicBezTo){const b=c.cubicBezTo;return {cubicBezTo:{x1:b.x1-x,y1:b.y1-y,x2:b.x2-x,y2:b.y2-y,x:b.x-x,y:b.y-y}};}
        return c;
      });
      // A source full-canvas solid foundation is already provided by the slide.
      if((page.number===1||page.number===8)&&x<1&&y<1&&w>1278&&h>718&&item.fill!=='none')continue;
      slide.shapes.add({name,geometry:'custom',position:{left:x,top:y,width:w,height:h},fill:item.fill,
        line:{fill:item.stroke,width:item.width,style:item.style},customPaths:[{width:w,height:h,commands}]});
    }else if(item.type==='text'){
      const shape=slide.shapes.add({name,geometry:'textbox',position:{left:item.x,top:item.y,width:item.w,height:item.h,rotation:item.rotation},fill:'none',line:{fill:'none',width:0,style:'solid'}});
      shape.text=item.text;
      shape.text.style={fontSize:item.size,typeface:item.family,bold:item.bold,italic:item.italic,color:item.colour,
        alignment:'left',verticalAlignment:'top',autoFit:'none',wrap:'none',insets:0};
      if(page.number===1&&item.text==='warnings.')shape.text.fill={type:'gradient',gradientKind:'linear',angleDeg:0,
        stops:[{offset:0,color:'#D4C5FF'},{offset:50000,color:'#B5A2FF'},{offset:100000,color:'#55DFCA'}]};
      const link=(page.links??[]).find(l=>item.x<l.x+l.w&&item.x+item.w>l.x&&item.y<l.y+l.h&&item.y+item.h>l.y);
      if(link)shape.hyperlink={uri:link.uri,isExternal:true};
      spacing.push({slide:page.number,name,spacing:item.spacing});
    }else if(item.type==='table'){
      const values=item.values.map(row=>row.map(v=>v??''));
      const table=slide.tables.add({rows:values.length,columns:values[0].length,left:item.x,top:item.y,
        width:item.w,height:item.h,columnWidths:item.widths,values});
      table.styleOptions={headerRow:false,bandedRows:false};
      table.borders.assign({style:'solid',fill:'#303645',width:.65});
      for(let r=0;r<values.length;r++){
        table.rows[r].height=item.heights[r];
        for(let c=0;c<values[0].length;c++){
          const cell=table.getCell(r,c);
          cell.fill=r===0?'#151a25':page.number===6&&r===values.length-1?'#152724':r%2===0?'#11151e':'#080a0f';
          cell.text.style={typeface:'Segoe UI',fontSize:r===0?13.75:21.1,bold:r===0,color:r===0?'#AEBAD0':'#F5F6FA',
            alignment:'left',verticalAlignment:'middle',wrap:'square',autoFit:'none'};
          table.cells.block({row:r,column:c,rowCount:1,columnCount:1}).assign({margins:{left:11.6,right:10,top:6,bottom:6}});
        }
      }
    }
  }
  slide.speakerNotes.text=page.notes;
  console.log(`Slide ${page.number}: ${page.elements.length} source elements`);
}
await fs.writeFile(path.join(build,'text-spacing.json'),JSON.stringify(spacing));
await (await PresentationFile.exportPptx(presentation)).save(path.join(build,'candidate.pptx'));
await fs.writeFile(path.join(build,'authoring-summary.json'),JSON.stringify({slides:18,nativeTables:5,editableDataGraphics:true,source:data.source_pdf},null,2));
console.log('PowerPoint candidate exported.');
