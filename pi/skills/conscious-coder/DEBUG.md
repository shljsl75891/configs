# Debug Loop

The feedback loop is the skill. Do not form hypotheses without one.

## 1. Build a loop

It must fail on the user's exact symptom, run the same each time, run fast, and run without a human. Try in order: a failing test at the nearest seam, a script that calls the code, a replay of captured input, a bisect over commits or inputs.

- Flaky bug: run it many times, fix the seed and the clock, and raise the rate until it fails reliably.
- Slow loop: cache setup, narrow the scope, and skip unrelated steps.
- Performance bug: measure first. Loop on a number (time, memory, query count), not on pass or fail.
- Show the user that the loop ran and failed on the symptom. If you cannot build a loop, say so, list what you tried, and ask the user. Do not guess-fix.

## 2. Make the repro small

Remove one piece of input or one step at a time. Keep the bug. Stop when each remaining piece is needed.

## 3. List hypotheses

List 3–5. Rank them. Write each as a prediction: "If X is the cause, then changing Y gives Z." Show them to the user before you test.

## 4. Test one variable at a time

Tag debug logs `[DEBUG-xxxx]`. Redact secrets and personal data in logs and in anything you paste.

## 5. Regression test first

Write the test at a correct seam before the fix. It must fail without the fix (Prove-It). If no correct seam exists, report that as a finding.

## 6. Fix the cause

Fix the cause, not the symptom. Find all callers. Fix the shared path once.

## 7. Verify and clean up

- Re-run the original loop from step 1. It must pass.
- Run the regression test. Revert the fix once to confirm it fails, then restore the fix.
- Grep for `[DEBUG-` and remove every tag. Remove temporary scripts.
- Diff against the pristine state. Only the fix and the test may remain.
- State the confirmed hypothesis in the commit message.
