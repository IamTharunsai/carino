"""Validate audit artifacts and refresh honest execution-status summaries."""
import collections
import csv
import hashlib
import json
from pathlib import Path
import re
import shutil

root=Path(__file__).resolve().parents[2]
out=root/'docs/audit'

def readlog(p):
    b=p.read_bytes()
    return b.decode('utf-16' if b.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8',errors='replace')

def rows(name):
    with (out/name).open(encoding='utf-8-sig',newline='') as f:
        result=list(csv.DictReader(f))
    assert result and all(None not in r for r in result),name
    return result

summary=json.loads((out/'coverage-summary.json').read_text(encoding='utf-8'))
controls=rows('CONTROL-CENSUS.csv'); nav=rows('NAVIGATION-AND-RETURN-CENSUS.csv')
ledger=rows('ALL-DIRECTIONS-LEDGER.csv'); files=rows('SOURCE-SNAPSHOT.csv')
assert len(controls)==summary['callback_bindings']
assert len(nav)==summary['navigation_modal_external_calls']
assert len(ledger)==14*len(controls)==summary['generated_direction_checks']
assert len(files)==summary['dart_files']==len(list((root/'lib').rglob('*.dart')))
assert len({r['control_id'] for r in controls})==len(controls)
assert all(r['result']=='NOT RUN' for r in ledger)
assert len(rows('DEEP-FINDINGS.csv'))==26
drift=[f['source'] for f in files if hashlib.sha256((root/f['source']).read_bytes()).hexdigest()!=f['sha256']]

baseline=readlog(out/'baseline-12-probes.log')
probe=readlog(root/'build/deep-workflow-probes-17.log')
shutil.copyfile(root/'build/deep-workflow-probes-17.log',out/'17-probes.log')
validation=json.loads((out/'local-validation-source-status.json').read_text(encoding='utf-8'))
screens=list((root/'build/screens').glob('*.png'))
assert len(screens)==68,len(screens)
capture_rows=[]
for p in sorted(screens):
    b=p.read_bytes()
    capture_rows.append({'file':p.relative_to(root).as_posix(),
        'sha256':hashlib.sha256(b).hexdigest(),
        'width':int.from_bytes(b[16:20],'big'),'height':int.from_bytes(b[20:24],'big'),
        'review':'Generated; only representative renders manually inspected'})
with (out/'CAPTURE-MANIFEST.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(capture_rows[0]));w.writeheader();w.writerows(capture_rows)

sweep_text=readlog(out/'button-sweep.log') if (out/'button-sweep.log').exists() else ''
sweep_result=next((l for l in reversed(sweep_text.splitlines()) if 'All tests passed!' in l or 'Some tests failed.' in l),'PENDING OR NO FINAL RESULT')
sweep={'final_result':sweep_result,
    'warning':'Single-tap observation sweep; does not complete workflows or recursively test revealed controls.'}
if 'All tests passed!' in sweep_result or 'Some tests failed.' in sweep_result:
    p=root/'build/audit/buttons.csv'
    if p.exists():
        shutil.copyfile(p,out/'BUTTON-SWEEP-OBSERVATIONS.csv')
        with p.open(encoding='utf-8-sig',newline='') as f: data=list(csv.DictReader(f))
        sweep['observations']=len(data)
        sweep['outcomes']=dict(collections.Counter(r['outcome'] for r in data))
        triage=[]
        for row in data:
            if row['outcome'].startswith('DEAD') or row['outcome']=='ERROR':
                benign={'Feed','All','Nearby','Everyone','Any','Reset','None','Public','Friends','Dark','Midnight',
                        'Monogamy','Chat first','This week','Matches','Discovery','This or That','Solo reset',
                        'Bowling','Sat · 10:00','Any time','English','Calm','5 / day','Monthly','Single'}
                note='Untriaged signal; inspect source and reproduce before treating as defect'
                if row['button'] in benign:
                    note='Likely same-state selection/default reset; no visible change can be expected'
                elif row['screen']=='Age check':
                    note='Harness tapped selected wheel text; must scroll picker to test a changed DOB'
                elif row['button'] in {'App lock','Use a passkey (Face / fingerprint)'}:
                    note='Native authentication not faithfully exercised by this sweep; inspect error/fallback on device'
                elif row['button']=='Log out':
                    note='Isolated Settings fixture lacks RootFlow routing; verify sign-out in authenticated full app'
                triage.append({**row,'review':note})
        if triage:
            with (out/'BUTTON-SWEEP-FLAG-TRIAGE.csv').open('w',encoding='utf-8-sig',newline='') as f:
                w=csv.DictWriter(f,fieldnames=list(triage[0]));w.writeheader();w.writerows(triage)

status={'baseline_12_probes':'All tests passed!' in baseline,
    'targeted_17_probes_final':next((l for l in reversed(probe.splitlines()) if 'All tests passed!' in l or 'Some tests failed.' in l),'No final result'),
    'probe_meaning':'11 defect reproductions, one publishing comparison, five Back/cancel/lock checks; passing is not product completion',
    'full_local_suite':validation['final_result'],'full_local_exit_code':validation['exit_code'],
    'sources_changed_during_full_local_suite':validation['changed_sources_during_run'],
    'sources_changed_after_full_local_suite':[s for s,h in validation['source_hashes_at_end'].items()
        if not (root/s).exists() or hashlib.sha256((root/s).read_bytes()).hexdigest()!=h],
    'capture_cases_completed':68,'capture_combined_initial_command':'Nonzero because initial probe harness failed compilation; all 68 capture cases completed',
    'button_sweep':sweep,'source_files_changed_since_census':drift,
    'parse_errors_in_census':summary['parse_errors'],
    'all_direction_live_end_to_end_certified':False}
(out/'runtime-status.json').write_text(json.dumps(status,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps({'validated':True,**summary,'runtime':status},indent=2,ensure_ascii=False))
