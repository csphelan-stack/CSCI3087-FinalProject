# Intentional CI failure version

This archive deliberately contains a one-line bug in `tools/gm_check.py`. The trailing-comma cleanup now removes commas before `}` but fails to remove commas before `]`.

## Expected result
Run `python -m pytest -q tests` from the project root. The tests that parse GameMaker JSON with trailing commas should fail with `json.decoder.JSONDecodeError`. This is the intended controlled failure for the CI assignment.

## Fix after capturing logs
Restore the cleanup expression to:

```python
cleaned = re.sub(r",(\s*[}\]])", r"\1", text)
```

Then rerun tests and push the fix. Do not leave this intentional bug on the main branch.
