# Writing

These rules always apply.
When you write or edit long Markdown, put each full sentence on its own line.

## Punctuation

Never use an em dash (`—`, U+2014) or an en dash (`–`, U+2013).
Use a plain ASCII hyphen (`-`) or rewrite the sentence.

Bad: `Use HTTPS — then restart Nginx.`
Good: `Use HTTPS. Then restart Nginx.`
Good: `Use HTTPS - then restart Nginx.`

## Git commits

When you write a commit message, never add a `Co-authored-by` trailer for the agent.
Never put the agent name, the model name, or Cursor in the commit body as an author.
Follow the existing repository commit style.
Do not invent a co-author line.

## Long Markdown

When you write or edit long Markdown files, put each full sentence on its own line.
This applies to READMEs, runbooks, `LABS.md`, service notes, and other `*.md` files.
Do not wrap lines by character width.
Keep list items, headings, links, and fenced code blocks intact.
Short files with a few sentences can stay compact.

## ASD-STE100

Write in ASD-STE100 Issue 8 style.
Do not copy the specification.
Use this practical subset.

Use simple words.
Give each word one meaning.
Prefer `start` over `begin` or `initiate`.
Use American English spelling.
Use approved technical names for homelab terms such as TrueNAS, Nginx, and SOPS.
Do not use those names as verbs.
Keep noun clusters to three words or fewer.

Write short sentences.
Use a maximum of 20 words for procedures.
Use a maximum of 25 words for descriptions.
Do not omit articles, subjects, or `that`.
Do not use contractions.

Use the active voice.
Use the imperative for procedures: `Install the package.`
Put one instruction in each sentence.
Put the condition before the command: `If the service is down, restart it.`

Write one topic per paragraph.
Write a maximum of six sentences in each paragraph.
Use a vertical list for complex information.

Use these verb forms: infinitive, imperative, simple present, simple past, and simple future.
Use `-ing` only as a technical noun or as a modifier.
Notes give information only.
Notes do not give commands.
