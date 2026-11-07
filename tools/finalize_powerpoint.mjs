import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
process.on('uncaughtException',error=>{console.error(error.message);process.exit(1);});
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const workspaceDir=path.dirname(root);
const build=path.join(workspaceDir,'tmp/student-dropout-pptx-build');
const skill='C:/Users/Administrator/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations';
process.env.RUNTIME_NODE_MODULES ??= 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const {finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')).href);
const result=await finalizePresentation({workspaceDir,candidatePath:path.join(build,'candidate-spaced.pptx'),
  finalPath:process.argv[2] ?? path.join(root,'output/powerpoint/Student_Dropout_Presentation.pptx'),
  pythonExecutable:'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',
  integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit',
    ...[6,10,11,15,16].flatMap(n=>['--require-native-table-slide',String(n)])],
  explicitTotalSlideCount:18,requiredNativeTableOwnerSlides:[6,10,11,15,16],requiredNativeChartOwnerSlides:[],
  fontPolicy:{basis:'design',families:['Segoe UI','Segoe UI Semibold','Arial']},verifyArtifactToolImport:true,
  receiptPath:path.join(build,path.basename(process.argv[2]??'Student_Dropout_Presentation.pptx')+'.validation.json')});
console.log(JSON.stringify({finalPath:result.finalPath,sha256:result.finalSha256,bytes:result.byteCount,slides:result.packageIntegrity.slide_count,findings:result.presentationLayout.findingCount}));
