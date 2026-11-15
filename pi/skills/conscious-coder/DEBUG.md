# Debug Loop

The feedback loop is the skill. Do not form hypotheses without one.

1. **Build a loop.** It must fail on the user's exact symptom, run the same each time, run fast, and run without a human.
2. **Make the repro small.** Remove input and steps until the bug stays.
3. **List 3–5 hypotheses.** Rank them. Each must be falsifiable. Show them to the user before you test.
4. **Test one variable at a time.** Tag debug logs `[DEBUG-xxxx]`. Remove them before you finish.
5. **Write the regression test before the fix**, at a correct seam. It must fail without the fix (Prove-It). If no correct seam exists, report that as a finding.
6. **Fix the cause**, not the symptom. Find all callers. Fix the shared path once.
