#!/usr/bin/env bash
set -euo pipefail

# Local Agentia quality gates (macOS / Linux).
# Agentia runs this from the repo root during `agentia cicd work test` (local by default)
# and `agentia cicd work submit` (unless --skip-local-tests). Exit non-zero to stop the submit;
# the output is uploaded to the user story as the local commit log.

echo "## Agentia Preflight & Triage"
agentia preflight run

# Stock Agentia checks. They need the code-analyzer plugin, Apex test classes and
# node_modules, so they run only when AGENTIA_FULL_GATES=1.
[ "${AGENTIA_FULL_GATES:-}" = "1" ] || exit 0

echo "## Running Code Analyzer"
sf code-analyzer run

echo "## Running apex tests (if --apex-test-classes= was specified)"
agentia cicd work test apex -t "${AGENTIA_APEX_TEST_CLASSES:-}" ${AGENTIA_APEX_RERUN_FAILED:-}

echo "## Running LWC tests"
npx sfdx-lwc-jest -- --passWithNoTests
