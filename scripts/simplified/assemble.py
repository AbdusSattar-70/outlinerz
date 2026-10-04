"""Reproduce the pinned Sohoj baseline in a separate schema (never rewrite public)."""
from pathlib import Path
import re,sys,subprocess
source=Path(sys.argv[1] if len(sys.argv)>1 else '../sohoj-reference/supabase/migrations')
pinned='00f11f2358516bc7362e1984836f09584085b4e7'
actual=subprocess.check_output(['git','-C',str(source.parent.parent),'rev-parse','HEAD'],text=True).strip()
if actual!=pinned: raise SystemExit('Check out pinned Sohoj source '+pinned+' before assembling the baseline.')
parts=[]
for f in sorted(source.glob('*.sql')):
 s=f.read_text()
 s=re.sub(r'\bpublic\.', 'academy.',s)
 s=re.sub(r'(schema\s+)public\b',r'\1academy',s,flags=re.I)
 s=re.sub(r"(search_path\s*(?:TO|=)\s*)'?public'?",r"\1'academy'",s,flags=re.I)
 # Existing public auth hooks remain intact; this application bootstraps profiles explicitly.
 s=re.sub(r'create trigger\b[^;]*\bon auth\.users\b[^;]*;', '',s,flags=re.I|re.S)
 s=re.sub(r'drop trigger\b[^;]*\bon auth\.users\b[^;]*;', '',s,flags=re.I|re.S)
 # No admission or offering action should require fee setup.
 s=re.sub(r" if target_table='programme_offerings' and enabled and not exists\([^\n]+\n",'',s)
 s=re.sub(r"code\s*=\s*'SOHOJ'\s+and\s+",'',s,flags=re.I)
 s=re.sub(r"where\s+code\s*=\s*'SOHOJ'",'where is_active',s,flags=re.I)
 s=re.sub(r" if target_table='staff' then update academy\.profiles[^\n]+\n",'',s)
 s=s.replace('join academy.fee_plan_versions f on f.id=a.fee_plan_version_id','left join academy.fee_plan_versions f on f.id=a.fee_plan_version_id')
 s=re.sub(r"where\s+code\s*=\s*'MAIN'\s+and\s+is_active",'where id=academy_private.current_branch_id() and is_active',s,flags=re.I)
 parts.append('-- Upstream '+f.name+'\n'+s)
Path('supabase/migrations/05_simplified_academy_base.sql').write_text('-- Pinned Sohoj source 00f11f2358516bc7362e1984836f09584085b4e7.\n-- Temporary legacy finance objects are removed by migration 06. Neither migration modifies public.\ncreate schema academy;\nset search_path=academy,extensions,public;\n'+'\n'.join(parts)+'\nreset search_path;\n')
