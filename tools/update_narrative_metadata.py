from pathlib import Path
from lxml import html
import json,re
ROOT=Path(__file__).resolve().parents[1]
doc=html.fromstring((ROOT/'speaker-notes.html').read_text(encoding='utf-8-sig'))
blocks=doc.xpath('.//div[contains(concat(" ",normalize-space(@class)," ")," spoken ")]')
assert len(blocks)==8
count=lambda s:len(re.findall(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*",s))
rows=[dict(slide=int(b.get('data-slide')),speaker=b.get('data-speaker'),words=count(b.text_content())) for b in blocks]
words=sum(r['words'] for r in rows)
assert 550<=words<=700,words
for r in rows:r.update(seconds_at_100wpm=r['words']*.6,seconds_at_120wpm=r['words']*.5)
timing={'method':'Current spoken blocks include the main transitions; optional alternatives and pauses excluded; no human rehearsal performed',
 'slides':rows,'total_words':words,'seconds_at_100wpm':words*.6,'seconds_at_120wpm':words*.5}
(ROOT/'results/script-timing.json').write_text(json.dumps(timing,indent=2),encoding='utf-8')
purposes=[
 ('Research question','From enrolment information to prediction and the distribution of errors.','Define what a dropout record means.'),
 ('Define the outcome','4,424 records; the normal course endpoint; Enrolled retained; transfers included.','Inspect the available entry information.'),
 ('Training-only EDA','Age and grade distributions overlap; sample sizes remain visible.','Overlap motivates a model and an independent test.'),
 ('Fit, choose, test','Three entry predictors; timing exclusions; course methods and AI-supported supplementary learning.','A probability needs a warning threshold.'),
 ('Validation decision','0.31 finds 200/284 validation dropouts; a fixed illustrative 70% target.','Check sensitivity, precision and costs on unseen test records.'),
 ('Overall test performance','Sensitivity 65.6%, precision 45.7%, accuracy 64.0%, denominators, baseline, +107 finds and +177 false warnings.','98 records are still missed: overall averages do not show which groups bear errors.'),
 ('Group audit','64/144 female and 34/141 male dropouts missed; five rates cover all three fairness criteria.','Observed error differences inform requirements before real use.'),
 ('Conclusion','Human review, label meaning, support capacity and later-cohort validation; no intervention-effect claim.','Close; use references and backups for questions.')]
lines=['# Slide logic and speaking plan','',
f'The current main talk is {words} words: about {words/100:.2f} minutes at 100 words/minute, before pauses. Its main links are already included; do not add the alternative handovers again. Human rehearsal is still required.','',
'| Slide | Core information | Why the next slide follows | Speaker | Words; seconds at 100 wpm |',
'|---|---|---|---|---|']
for r,(title,evidence,transition) in zip(rows,purposes):
 lines.append(f"| {r['slide']}. {title} | {evidence} | {transition} | {r['speaker']} | {r['words']}; {r['seconds_at_100wpm']:.0f} |")
lines+=['','## Learning and evidence boundaries','',
'We applied course methods to the data summaries, plots, bootstrap and fairness comparisons. For unfamiliar methods, we asked ChatGPT for explanations, checked documentation, then rewrote and ran the main R analysis. ChatGPT also assisted initial code and text drafts, source checks and slide formatting. Our reasons for key choices are in learning-process.md; course evidence is in course-map.md.','',
'Slides 9-18 remain sources and backups. Slide 17 explains course versus supplementary methods in first person. The supplied brief suggests approximately seven minutes of speaking; eight main slides and four speaking parts are our organisational choices, not invented course rules.']
(ROOT/'docs/slide-outline.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
readme=ROOT/'README.md'
text=readme.read_text(encoding='utf-8')
text=re.sub(r'The \d+-word spoken script is approximately [^.]+ minutes [^.]+ seconds at 100 words/minute, before handovers and pauses\.',
  f'The {words}-word spoken script takes about {words/100:.2f} minutes at 100 words/minute, before pauses. Main transitions are included.',text)
text=text.replace('The main script remains 635 words.',f'The main script now has {words} words, including transitions.')
readme.write_text(text,encoding='utf-8')
print(json.dumps({'spoken_words':words,'minutes_at_100wpm':words/100,'slides':rows},ensure_ascii=False))
