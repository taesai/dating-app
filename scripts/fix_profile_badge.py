#!/usr/bin/env python3
import re

# Lire le fichier
with open('../lib/features/pages/dating_profile_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Ajout de l'import
if "'../../core/widgets/subscription_badge.dart'" not in content:
    content = content.replace(
        "import 'manage_videos_page.dart';",
        "import 'manage_videos_page.dart';\nimport '../../core/widgets/subscription_badge.dart';"
    )

# Remplacement de la ligne avec le nom
pattern = r"(\s+)\] else \.\.\.\[\n(\s+)Text\(\n(\s+)'\\$\{_currentUser!\.name\}, \\$\{_currentUser!\.age\}',\n(\s+)style: const TextStyle\(fontSize: 32, fontWeight: FontWeight\.bold\),\n(\s+)\),"

replacement = r"""\1] else ...[
\2Row(
\2  mainAxisAlignment: MainAxisAlignment.center,
\2  children: [
\2    Text(
\2      '${_currentUser!.name}, ${_currentUser!.age}',
\2      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
\2    ),
\2    const SizedBox(width: 12),
\2    SubscriptionBadge(plan: _currentUser!.effectivePlan),
\2  ],
\2),"""

content = re.sub(pattern, replacement, content)

# Écrire le fichier
with open('../lib/features/pages/dating_profile_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fichier modifié avec succès")
