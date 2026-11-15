"""Run current local tests and record source stability; never edits application code."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

root=Path(__file__).resolve().parents[2]
out=root/'docs/audit'

def hashes():
    return {p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for folder in ['lib','test'] for p in sorted((root/folder).rglob('*.dart'))}

before=hashes()
command=[r'C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe',
         r'C:\src\flutter\bin\cache\flutter_tools.snapshot',
         'test','--no-pub','--reporter','expanded','test','docs/audit/workflow_probes_test.dart']
env=dict(os.environ); env.pop('CAPTURE',None)
with (out/'latest-local-validation.log').open('wb') as log:
    run=subprocess.run(command,cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
after=hashes()
text=(out/'latest-local-validation.log').read_text(encoding='utf-8',errors='replace')
last=next((line for line in reversed(text.splitlines()) if 'All tests passed!' in line or 'Some tests failed' in line),'No final test result')
status={'command':command,'exit_code':run.returncode,'final_result':last,
    'changed_sources_during_run':[p for p in before.keys()|after.keys() if before.get(p)!=after.get(p)],
    'source_hashes_at_start':before,'source_hashes_at_end':after,
    'warning':'Characterisation probes reproduce known defects. Passing them is not evidence that the intended features work. Screenshot scenarios are skipped in this run.'}
(out/'local-validation-source-status.json').write_text(json.dumps(status,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in status.items() if not k.startswith('source_hashes')},indent=2))
