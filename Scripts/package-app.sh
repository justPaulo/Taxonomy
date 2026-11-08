#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT/dist/Animal Taxonomy.app"

swift build --package-path "$ROOT" -c release
swift "$ROOT/Scripts/package-app.swift" "$ROOT/.build/release/SciClassification" "$APP_PATH"

printf 'Created %s\n' "$APP_PATH"
