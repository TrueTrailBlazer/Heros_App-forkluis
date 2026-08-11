import os, re, glob

errors = []
files = glob.glob('lib/**/*.dart', recursive=True)
for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        content = fh.read()
    opens = content.count('{')
    closes = content.count('}')
    if opens != closes:
        errors.append(f'{f}: unmatched braces (open={opens}, close={closes})')
    
    for match in re.finditer(r"import '(\.\./[^']+)'", content):
        imp = match.group(1)
        resolved = os.path.normpath(os.path.join(os.path.dirname(f), imp))
        if not os.path.exists(resolved):
            errors.append(f'{f}: missing import -> {resolved}')

if errors:
    for e in errors:
        print(e)
else:
    print('All files OK - no syntax or import errors found')
