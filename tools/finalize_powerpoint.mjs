// Validate the candidate after restoring native text letter spacing.
// This optional PowerPoint-export check uses the local presentation tooling.
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath,pathToFileURL} from 'node:url';
import fs from 'node:fs/promises';
const require=createRequire(import.meta.url);
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const build=path.resolve(process.argv[2] || path.join(root,'output','export-work'));
const finalPath=path.resolve(process.argv[3] || path.join(build,'deliverable','Student_Dropout_Presentation.pptx'));
await fs.mkdir(path.dirname(finalPath), {recursive:true});
const skill=process.env.PRESENTATIONS_SKILL_DIR;
if(!skill || !process.env.PRESENTATIONS_PYTHON) throw Error('Set PRESENTATIONS_SKILL_DIR and PRESENTATIONS_PYTHON to your local slide validator and its Python interpreter.');
process.env.RUNTIME_NODE_MODULES ??= path.resolve(require.resolve('@oai/artifact-tool'), '../../../..');
const {finalizePresentation}=await import(pathToFileURL(path.join(skill,'container_tools/artifact_tool_utils.mjs')).href);
const {total}=JSON.parse(await fs.readFile(path.join(build,'slides.json'),'utf8'));
const result=await finalizePresentation({workspaceDir:build,candidatePath:path.join(build,'candidate-spaced.pptx'),
  finalPath,pythonExecutable:process.env.PRESENTATIONS_PYTHON,
  integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit'],
  explicitTotalSlideCount:total,requiredNativeTableOwnerSlides:[],requiredNativeChartOwnerSlides:[],
  fontPolicy:{basis:'design',families:['Georgia','Segoe UI','Segoe UI Semibold','Arial']},verifyArtifactToolImport:true,
  receiptPath:path.join(build,'powerpoint-validation.json')});
console.log(JSON.stringify({file:result.finalPath,sha256:result.finalSha256,bytes:result.byteCount,slides:result.packageIntegrity.slide_count,findings:result.presentationLayout.findingCount}));
