#!/usr/bin/env python3
"""Give each Flutter web release a distinct JS entrypoint URL."""
import json
import os
from pathlib import Path

build = Path("build/web")
version = os.environ["GITHUB_SHA"][:12]
bootstrap = build / "flutter_bootstrap.js"
source = bootstrap.read_text(encoding="utf-8")
if '"main.dart.js"' not in source:
    raise RuntimeError("Flutter bootstrap format changed: main.dart.js reference not found")
source = source.replace('"main.dart.js"', f'"main.dart.js?v={version}"')
bootstrap.write_text(source, encoding="utf-8")
(build / "version.json").write_text(json.dumps({"version": version}) + "\n", encoding="utf-8")
print(f"Versioned Flutter entrypoint: main.dart.js?v={version}")
