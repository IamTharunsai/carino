"""Build a source census and an explicitly UNEXECUTED all-directions ledger."""
import collections
import csv
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs' / 'audit'
j = json.loads((OUT / 'source-inventory.json').read_text(encoding='utf-8'))

def write(name, rows):
    with (OUT / name).open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

controls = []
for raw in j['controls']:
    if raw['callback'] in {'onSurface', 'onPrimary'}:
        continue  # Theme colour roles, not event callbacks.
    row = dict(raw)
    row['control_id'] = f'C{len(controls)+1:04}'
    row['source_finding'] = 'See file-level action map and detailed reports; not a per-branch pass'
    row['branch_review'] = 'Callback expression recorded exactly; referenced methods and generated variants need caller context'
    row['all_direction_result'] = 'UNVERIFIED'
    controls.append(row)
write('CONTROL-CENSUS.csv', controls)

navigation = []
for i, raw in enumerate(j['navigation'], 1):
    row = {'navigation_id': f'N{i:04}', **raw}
    row['required_return_check'] = (
        'Return to exact caller; preserve allowed draft/state; do not bypass a gate; '
        'handle null/cancel result; reconcile any completed mutation')
    row['system_back_and_gesture'] = 'UNVERIFIED at this caller'
    row['dismiss_and_reopen'] = 'UNVERIFIED at this caller'
    navigation.append(row)
write('NAVIGATION-AND-RETURN-CENSUS.csv', navigation)

directions = [
    ('FORWARD', 'Execute enabled action and verify the intended destination AND durable outcome'),
    ('APP_BACK', 'Use visible Back/Close; verify exact previous context and retained draft policy'),
    ('SYSTEM_BACK', 'Use system Back/back gesture; compare with visible Back and check gate enforcement'),
    ('DISMISS_CANCEL', 'Cancel or dismiss modal by button/outside tap/drag; verify no unintended mutation'),
    ('REOPEN', 'Reopen the same item; verify saved state and correct next action'),
    ('RAPID_REPEAT', 'Repeat action or overlap gestures; verify one operation and no double spend'),
    ('FAIL_RETRY', 'Fail request or validation then retry; preserve work and show accurate outcome'),
    ('OFFLINE_RECONNECT', 'Disconnect before/during action then reconnect; reconcile without duplicates'),
    ('KILL_RESTART', 'Terminate before/during/after action; verify durable accepted/pending/failed state'),
    ('ACCOUNT_CHANGE', 'Sign out/expire session/switch account; do not leak state or bypass gates'),
    ('RECIPIENT_STATE', 'If shared: verify recipient outcome; if unavailable/blocked/deleted: safe reconciliation'),
    ('PERMISSION', 'If capability-dependent: deny/revoke/grant permission and verify fallback'),
    ('ACCESSIBILITY', 'Exercise with screen reader/large text/reduced motion; verify discoverability and feedback'),
    ('ALTERNATE_ENTRY', 'Open through each caller/tab/deep link; preserve intended person/resource and return'),
]
ledger=[]
for row in controls:
    for direction, requirement in directions:
        ledger.append({'scenario_id':f"{row['control_id']}-{direction}",
            'control_id':row['control_id'], 'source':row['source'], 'line':row['line'],
            'owner':row['owner'], 'callback':row['callback'],
            'direction':direction,'required_check':requirement,
            'applicability':'REQUIRES PER-SITE REVIEW; N/A needs a reason',
            'result':'NOT RUN', 'evidence':'No complete per-site execution evidence recorded'})
write('ALL-DIRECTIONS-LEDGER.csv', ledger)

files=[]
for f in j['files']:
    source=f['source']; b=(ROOT/source).read_bytes()
    files.append({**{k:v for k,v in f.items() if k!='parse_errors'},
        'parse_error_count':len(f.get('parse_errors',[])),
        'unchanged_since_ast_scan':hashlib.sha256(b).hexdigest()==f['sha256'],
        'callback_bindings':sum(c['source']==source for c in controls),
        'navigation_calls':sum(c['source']==source for c in navigation),
        'inputs_and_back_surfaces':sum(c['source']==source for c in j['inputs_and_back_surfaces']),
        'census_status':'SCANNED', 'all_direction_runtime_status':'NOT CERTIFIED'})
write('SOURCE-SNAPSHOT.csv',files)

surfaces=[]
for c in j['classes']:
    if c['extends'] not in {'StatefulWidget','StatelessWidget','InheritedWidget'}: continue
    surfaces.append({**c,'callback_file_count':sum(r['source']==c['source'] for r in controls),
        'entry':'See named constructors and caller expressions in navigation census',
        'forward':'See callback census; not certified complete',
        'reverse':'Visible Back / system Back / dismiss / caller null handling require separate checks',
        'restart':'Widget-local state is not proof of durable continuity',
        'live_recipient':'No complete two-device live execution recorded',
        'status':'SOURCE INVENTORIED; ALL-DIRECTION EXECUTION OPEN'})
write('SURFACE-CENSUS.csv',surfaces)
if j.get('events_and_lifecycle'):
    write('EVENT-AND-LIFECYCLE-CENSUS.csv',[
        {'event_id':f'E{i:04}',**row} for i,row in enumerate(j['events_and_lifecycle'],1)])

boundary=[]
for folder in ['ios','android','backend']:
    for p in sorted((ROOT/folder).rglob('*')):
        if not p.is_file() or any(x in p.parts for x in ['build','.gradle','Pods','node_modules','.symlinks','ephemeral']): continue
        if p.suffix not in {'.swift','.kt','.xml','.plist','.entitlements','.ts','.sql','.toml','.gradle','.kts','.xcconfig','.pbxproj'}: continue
        boundary.append({'source':p.relative_to(ROOT).as_posix(),
            'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
            'status':'INVENTORIED; see boundary dependency review; not a complete native/backend execution audit'})
write('NATIVE-AND-BACKEND-SNAPSHOT.csv',boundary)

summary={'dart_files':len(files),'callback_bindings':len(controls),
    'excluded_theme_colour_fields':len(j['controls'])-len(controls),
    'navigation_modal_external_calls':len(navigation),
    'widget_classes':len(surfaces),'inputs_and_back_surfaces':len(j['inputs_and_back_surfaces']),
    'generated_direction_checks':len(ledger),
    'event_and_lifecycle_sites':len(j.get('events_and_lifecycle',[])),
    'native_and_backend_source_files_inventoried':len(boundary),
    'parse_errors':sum(f['parse_error_count'] for f in files),
    'files_changed_since_ast_scan':sum(not f['unchanged_since_ast_scan'] for f in files),
    'all_direction_end_to_end_certified':False,
    'warning':'Generated checks are a coverage debt ledger, not executed tests. Loop-created controls are templates, not every runtime item.'}
(OUT/'coverage-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
report=OUT/'DEEP-WORKFLOW-AUDIT.md'
if report.exists():
    sections=re.split(r'^### (D\d+) — (P\d) — (.+)\n',report.read_text(encoding='utf-8'),flags=re.M)
    backlog=[]
    for pos in range(1,len(sections),4):
        ident,priority,title,body=sections[pos:pos+4]
        body=body.split('\n## ')[0].strip()
        backlog.append({'ID':ident,'Priority':priority,'Issue':title,
            'Detailed_evidence_and_acceptance':body,
            'Execution_classification':'See explicit Source / Reproduced baseline / Verify statement and runtime logs',
            'Status':'OPEN OR RECONCILIATION REQUIRED; no automatic closure from source edits'})
    write('DEEP-FINDINGS.csv',backlog)
print(json.dumps(summary,indent=2))
