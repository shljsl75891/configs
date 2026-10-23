# Humanizer reference

Tags: **[1]** act on one hit. **[weak]** act only when 2+ other tells sit nearby.

## Word tiers

**Tier 1, replace every hit:** delve, utilize, leverage (verb), facilitate, elucidate, embark, endeavor, encompass, multifaceted, tapestry, testament, paradigm, synergy, holistic, catalyze, juxtapose, realm, landscape (metaphor), myriad, plethora, ever-evolving, crucial, additionally, garner, interplay, intricate, pivotal, showcase, underscore, vibrant, fostering.

**Tier 2, rewrite at 3+ per paragraph:** robust→strong, comprehensive→complete, seamless→smooth, cutting-edge/innovative→new, streamline→simplify, empower→let/help, foster/cultivate→build, enhance→improve, elevate→raise, optimize→tune, resonate→connect with, harness→use, navigate (metaphor)→handle, cornerstone→basis, serves as/stands as/boasts/features→is/has.

**Filler, delete:** it's worth noting that, it's important to note that, importantly, notably, interestingly. in order to→to. due to the fact that→because.

## Patterns

- **[1] Puffery:** "pivotal moment", "testament to", "evolving landscape". State what happened or what is planned.
- **[1] Vague attribution:** "experts believe", "studies show". Name the source or cut the claim.
- **[1] Name-dropping:** sources listed with no context. Pick one, say what it said.
- **[1] Formulaic challenge:** "Despite challenges, X continues to thrive". Give the specific fact.
- **[1] Negative parallelism:** "Not just X, but Y", "Not X. Not Y. Just Z." State the point directly.
- **[1] Preamble:** "let's dive in", "the real question is", "here's the kicker". Say the point.
- **[1] Fake-profound kicker:** "That last part matters more than it sounds." Delete it. A rewrite makes another kicker.
- **[1] Self-reference:** narrating the method, "this doc explains...", a first sentence that repeats its heading. Start with the content.
- **[1] Replacement slop:** swapping a vague phrase for a quieter adjective. Swap in a fact, or cut.
- **[1] False agency:** "the data tells us", "the decision emerges". Name the actor.
- **[1] Figurative verbs:** inanimate subject plus "lives in", "rides", "surfaces", "fires", "holds". Use "is in", "runs on", "appears", "runs".
- **[1] Abstract metaphor nouns:** substrate, vector, north star, flywheel, scaffolding. Use the plain word.
- **[1] Rhetorical-question hook:** open with the claim.
- **[weak] Rule of three:** use the count the content has.
- **[weak] Superficial -ing phrases:** "highlighting", "reflecting", "showcasing". Cut, or make a real clause.
- **[weak] Synonym cycling:** pick one term and repeat it.
- **[weak] False ranges:** "from X to Y" with no real scale. List the topics.
- **[weak] Summary closer:** end on the last real point.
- **[weak] False balance:** if Y is better, say so.
- **[weak] Hedge stacking:** one hedge on an uncertain claim, none on a sure one.
- **[weak] Hyphen-pair overuse:** cross-functional, data-driven, real-time. Drop hyphens on common pairs.
- **[weak] Inline-header lists:** bold label, colon, description. Write prose or a plain list.
- **[weak] Fragmented header:** a line under a heading that restates it. Cut the line.

## Style

- Join clauses with a period or comma. Use a colon only before a list or example.
- Bold only terms the reader must find by scanning.
- Headings in sentence case. No emojis in headings or bullets. Straight quotes.
- Name the mechanism or a number. If no fact exists, cut the line.
- Name the actor: "The compiler validates queries." Use passive only when the actor is unknown.
- Use a stronger verb or a number in place of an adverb: "is fast", "takes 40 ms".
- One idea per sentence. Split any sentence that needs a second read.
- Let sections differ in length. Real topics are lumpy.
- Keep terse text readable: keep articles and full verbs, no arrows for prose.

## Voice by text type

**Docs and READMEs.** Use Simplified Technical English: short sentences, active voice, plain words. Address the reader as "you". Put the point first. Link to deeper docs. Leave out what types and `package.json` already say.

**Posts, emails, chat, comments.** Use "we/our/us". Add voice:
- Take a position a reader could disagree with.
- React to facts, do not only report them.
- Mix short sentences with one that builds.
- Allow one colloquial word per piece.
- Cluster hedges around uncertain claims only.
- Leave contradictions unresolved.
- Vary paragraph density. Do not run claim, elaborate, example, wrap-up on every paragraph.
- Start with a linking word on few paragraphs. Chain the rest with none.
- Sometimes bury the point mid-paragraph or end on it.

## Substance tests

- **Name-swap.** If the sentence fits another product or person, it is filler. Add the specific or cut it.
- **Reshuffle.** If paragraphs can swap order, the piece is a list. Order them as an argument or make it a list.
- **Deletion.** If removing a sentence loses only rhythm, remove it.

## Commit and PR text

Format comes from the `commit-checklist` skill. Prose rules here:
- Cut "This commit adds...", trailing "...ensuring consistency", file-list bullets, test-count scoreboards.
- State the why in the body. The diff shows the what.
- The PR description says what changed, why, and how to check it.
