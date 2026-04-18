---
name: humanizer
version: 3.0.0
description: |
  Use when writing or editing anything on behalf of a human: TDD docs, notes,
  emails, posts, or any prose where the output should sound like a person wrote
  it, not an AI.
license: MIT
compatibility: claude-code opencode
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Humanizer: Remove AI writing patterns

Edit text to remove AI-generated patterns and make it sound human. Based on Wikipedia's "Signs of AI writing" guide.

## Voice rule

Write using **we/our/us** instead of you/your/you're. Apply this to all rewrites.

## Task

1. Scan for patterns below
2. Rewrite problem sections — replace AI-isms with natural alternatives
3. Preserve meaning and match intended tone
4. Inject personality — don't just remove bad patterns, add actual voice
5. Final anti-AI pass: ask "What makes this obviously AI generated?" Answer briefly, then revise

## Voice calibration (optional)

If a writing sample is provided, read it first. Note sentence length, word choice level, punctuation habits, and transition style. Match those in the rewrite. Without a sample, use the default voice guidance below.

Provide sample inline: `"Humanize this. Here's my writing for voice matching: [sample]"` or by file path.

## Personality and soul

Sterile, voiceless writing is just as obvious as AI slop. Signs of soulless writing:

- Uniform sentence length and structure
- No opinions, no uncertainty, no mixed feelings
- No first-person when appropriate
- Reads like a press release

How to add voice:

- **Have opinions.** React to facts, don't just report them.
- **Vary rhythm.** Short punchy sentences. Then longer ones that take their time.
- **Acknowledge complexity.** "Impressive but unsettling" beats "impressive."
- **Use "we" when it fits.** First person is honest, not unprofessional.
- **Let mess in.** Perfect structure feels algorithmic.

---

## Content patterns

### 1. Significance inflation

**Watch:** stands/serves as, testament/reminder, vital/pivotal/key role, underscores/highlights importance, evolving landscape, indelible mark, deeply rooted

Cut the grand framing. State the fact directly.

> ~~marking a pivotal moment in the evolution of regional statistics~~ → established to collect regional statistics independently

### 2. Notability emphasis

**Watch:** independent coverage, local/national media outlets, active social media presence

Replace with specific, sourced claims.

> ~~cited in The New York Times, BBC, Financial Times~~ → In a 2024 NYT interview, she argued...

### 3. Superficial -ing phrases

**Watch:** highlighting/underscoring/emphasizing, reflecting/symbolizing, cultivating/fostering, showcasing

These tack fake depth onto sentences. Cut or rewrite as a real clause.

> ~~reflecting the community's deep connection to the land~~ → The architect cited local bluebonnets and the Gulf coast.

### 4. Promotional language

**Watch:** boasts, vibrant, rich (figurative), profound, nestled, in the heart of, groundbreaking, renowned, breathtaking, stunning

Neutral tone. Specific facts.

> ~~Nestled within the breathtaking region...~~ → Alamata Raya Kobo is a town in Gonder, Ethiopia.

### 5. Vague attributions

**Watch:** Industry reports, Observers have cited, Experts argue, Some critics argue

Name the source or cut it.

> ~~Experts believe it plays a crucial role~~ → supports several endemic fish species, per a 2019 CAS survey

### 6. Formulaic challenges sections

**Watch:** Despite its... faces challenges..., Despite these challenges, Future Outlook

Replace with specific facts about the actual situation.

> ~~Despite challenges, continues to thrive~~ → Traffic congestion increased after three IT parks opened in 2015.

---

## Language and grammar patterns

### 7. AI vocabulary overuse

**High-frequency words:** actually, additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adj), landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore (verb), valuable, vibrant

These co-occur and flag AI origin. Replace with plain alternatives.

### 8. Copula avoidance

**Watch:** serves as, stands as, marks, represents, boasts, features, offers

Use is/are/has instead.

> ~~Gallery 825 serves as LAAA's exhibition space~~ → Gallery 825 is LAAA's exhibition space

### 9. Negative parallelisms and tailing negations

**Watch:** Not only...but..., It's not just about..., it's..., tailing fragments like "no guessing"

Rewrite as a direct positive statement.

> ~~It's not just about autocomplete; it's about creativity~~ → The heavy beat adds to the aggressive tone.

### 10. Rule of three overuse

LLMs force ideas into threes. Use as many points as needed, no more.

> ~~innovation, inspiration, and industry insights~~ → talks and panels, with time for networking

### 11. Synonym cycling

**Watch:** protagonist / main character / central figure / hero all in one paragraph

Repetition-penalty causes excessive synonym substitution. Use one term.

### 12. False ranges

**Watch:** from X to Y where X and Y aren't on a meaningful scale

> ~~from the singularity of the Big Bang to the grand cosmic web~~ → covers the Big Bang, star formation, and dark matter theories

### 13. Passive voice and subjectless fragments

**Watch:** No config needed, Results are preserved automatically

Name the actor. Use active voice when clearer.

> ~~No configuration file needed~~ → We don't need a configuration file.

---

## Style patterns

### 14. Em dash overuse

LLMs overuse — to mimic punchy writing. Replace with commas, periods, or parentheses.

### 15. Boldface overuse

AI emphasizes phrases mechanically. Remove bold unless genuinely needed.

### 16. Inline-header lists

**Watch:** `- **Header:** description` lists

Rewrite as prose or a simple list without bolded labels.

### 17. Title case headings

AI capitalizes all main words. Use sentence case.

> ~~## Strategic Negotiations And Global Partnerships~~ → ## Strategic negotiations and global partnerships

### 18. Emojis

AI decorates headings and bullets with emojis. Remove them.

### 19. Curly quotation marks

ChatGPT uses "curly" quotes. Use "straight" quotes.

---

## Communication patterns

### 20. Chatbot artifacts

**Watch:** I hope this helps, Of course!, Certainly!, Would you like..., let me know, here is a...

Strip any chatbot-correspondence language from content.

### 21. Knowledge-cutoff disclaimers

**Watch:** as of [date], While specific details are limited, based on available information

Replace with sourced facts or remove.

### 22. Sycophantic tone

**Watch:** Great question!, You're absolutely right!, That's an excellent point

Cut. State the substance directly.

---

## Filler and hedging

### 23. Filler phrases

- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that" → "Because"
- "At this point in time" → "Now"
- "Has the ability to" → "Can"
- "It is important to note that" → cut entirely

### 24. Excessive hedging

> ~~could potentially possibly be argued that... might have some effect~~ → may affect outcomes

### 25. Generic positive conclusions

**Watch:** future looks bright, exciting times lie ahead, journey toward excellence

End with a specific fact instead.

### 26. Hyphenated word pair overuse

**Watch:** cross-functional, data-driven, client-facing, decision-making, high-quality, real-time, end-to-end

Humans hyphenate inconsistently. Drop hyphens on common pairs.

### 27. Persuasive authority tropes

**Watch:** The real question is, at its core, what really matters, fundamentally, the heart of the matter

These announce a restatement as if it's a revelation. Cut the preamble.

### 28. Signposting and announcements

**Watch:** Let's dive in, let's explore, here's what you need to know, without further ado

Don't announce what's coming. Just say it.

### 29. Fragmented headers

A heading followed by one line restating the heading before real content. Cut the restatement.

---

## Process

1. Read input
2. Identify pattern instances
3. Rewrite problem sections
4. Check: natural when read aloud, varied structure, specific details, appropriate tone, we/our/us voice
5. Draft rewrite
6. Ask: "What makes this obviously AI generated?" — answer briefly
7. Final rewrite addressing remaining tells

## Output format

1. Draft rewrite
2. Remaining AI tells (brief bullets)
3. Final rewrite
4. Summary of changes (optional)

---

_Based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup._
