import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = re.sub(
        r'builder:\s*\(context,\s*snapshot\)\s*\{',
        r"builder: (context, snapshot) {\n            if (snapshot.hasError) return Center(child: Text('Erro DB: ${snapshot.error}', style: const TextStyle(color: Colors.red)));\n            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());",
        content
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

for root, _, files in os.walk('C:/Users/LuísFernandodaConcei/.gemini/antigravity/scratch/Heros_App-forkluis/lib/screens'):
    for file in files:
        if file.endswith('_screen.dart'):
            process_file(os.path.join(root, file))
