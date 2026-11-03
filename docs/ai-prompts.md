# AI prompt log

One entry per prompt that produced tests, rules or pipeline code we kept or rejected.
This is the evidence for "how we guided AI past happy-path tests" in the testing defense,
so record the misses and the follow-ups, not only the final prompt.

## Template

### YYYY-MM-DD: <what was asked for>

- **Who:** <name>
- **Model and version:** <e.g. the model name shown in the tool>
- **Prompt:** <paste it, including the boundaries and invariants you listed>
- **What came back:** <tests or code produced, in one or two lines>
- **What was missing or wrong:** <e.g. only happy-path cases; a test asserted the wrong value>
- **Follow-up prompt:** <what you asked next, e.g. "this planted bug survived; write the test that catches it">
- **Kept / rejected and why:** <which tests were merged, which were dropped>
- **Verified by:** <ran locally / planted-bug check / reviewer>

## Entries
