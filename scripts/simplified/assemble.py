"""Rebuild the one fresh-database migration from pinned source and reviewed adaptations."""
from pathlib import Path
parts=sorted(Path('scripts/simplified/source-sql').glob('*.sql'))
Path('supabase/migrations/01_simplified_baseline.sql').write_text('-- Fresh database only: Sohoj academic ERP in public, isolated branches, demo opt-in.\n-- Financial stores and permissions are removed before this transaction commits.\n'+'\n'.join(p.read_text() for p in parts))
