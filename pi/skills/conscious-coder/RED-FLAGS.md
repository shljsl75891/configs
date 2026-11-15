# Red Flags

## Excuses and answers

- "I will add tests later." → Later never comes. Write the test now (RED→GREEN).
- "It is too simple to test." → Simple code breaks too. A one-line test costs less than a bug.
- "I tested it by hand." → A manual check does not stay. Write the test.
- "I will write all tests first." → Horizontal slices test shape, not behavior. One test, one impl.
- "The test passes, so the bug is fixed." → Check that the test fails without the fix.
- "I will fix the symptom here." → Find the cause and all callers. Fix the shared path once.
- "I will do the next slice, then run tests." → Run tests now. Never stack slices on unknown state.

## Warning signs

- A test never failed (no RED).
- A test mocks your own module.
- The diff has code that no task or test needs.
- A fix has no test that guards it.
- More than one task is in progress.
