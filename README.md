This was an experiment testing how good Claude Fable 5.2 is at completing a research project from start to end, given only a very vague prompt.

# The prompt

Create a mizer model that explains the phenomenon that the North-West Atlantic cod population did not recover in spite of a fishing moratorium. Use that model to show how increased fishing on other species would lead to a recovery. Write a paper about this for a journal of your choice. Also create an interactive website explaining this to fisheries policy makers. Delegate work to Opus 5.5 subagents in order to preserve the limited Fable 5.2 tokens.

# Result

The paper and the website are both finished, and both report what the models actually found: role reversal does not explain the failed moratorium in this model, and forage fishing is not a supported recovery lever.

## Deliverables

- **Paper**: [paper/manuscript.pdf](paper/manuscript.pdf) (42 pages) and [paper/supplement.pdf](paper/supplement.pdf) (24 pages), written for the Canadian Journal of Fisheries and Aquatic Sciences. Title: "A weak, conditional trap: a size-spectrum test of predator–prey role reversal as the cause of non-recovery of Atlantic Cod on the eastern Scotian Shelf". Abstract 169 words, main text about 7,300, 61 references, seven figures, four tables.
- **Website**: published privately at https://claude.ai/artifact/4C4sT92EXPKXB6QdnfKea8, and in the repo as [website/index.html](website/index.html). Others cannot open the link until you share it from the page's Share menu.
- **Models and results**: three model versions with scripts, saved parameters and results; [results/SUMMARY.md](results/SUMMARY.md) is the full account.

## What the paper concludes

- With the documented fishing history, modelled cod regains half its 1980–85 spawning biomass two years after the closure, and forage fish rise 1.4-fold against 7.9-fold observed.
- A cod-free alternative stable state exists only under an untested assumption (forage fish causing 5.9% of early-life cod deaths), and no hindcast reaches it.
- Elevated adult natural mortality reproduces the decline; while it stays high, forage fishing cannot help.
- Forage fishing restores cod only from the alternative state; from the modelled collapsed state it delays recovery by 2–4 years.

## What I checked, and what I did not

- **Paper**: I read the title page, abstract and management section, looked at three figure pages, and confirmed there are no unresolved citations or references in either PDF. I did not read all 42 pages or re-derive the numbers. The paper agent traced every quantitative claim to a results file in [paper/number_check.md](paper/number_check.md) and found eight places where the summary document disagreed with the data; it used the data in each case.
- **Website**: I read the full text and looked at desktop and phone screenshots. I did not operate the controls myself.
- **Models**: I checked the bistability and forage-fishing figures and key result files for the third model.

## Before submission you still need to

- Fill in the author block, affiliation, acknowledgements, funding and competing-interest statements; all are placeholders.
- Review and edit the generative-AI statement, which says the models, analysis and text were produced by AI agents under your direction.
- Deposit code and data with a DOI, and re-extract the survey series from official DFO data. The series used comes from the public repository of Adekoya et al. (2026), which has no licence.
- Re-check the journal's current author guidelines; the journal site blocked the automated check.
- Decide whether a development version of mizer (3.4.0.9003) is acceptable for a published analysis.

## Loose ends

- **Nothing is committed** beyond your own "First attempt" commit.
- **Four possible mizer bugs** are written up with reprexes in [notes/mizer-issues.md](notes/mizer-issues.md); none has been filed.
- **Stray download**: `/home/gustav/Downloads/Fs97-6-2520-eng.pdf` (15 MB) is still there.
- **Weak point a referee will press**: the model cannot generate the observed forage boom, so it cannot fully test a mechanism that depends on one. The paper says this in its limitations.

`★ Insight ─────────────────────────────────────`
- **A negative result needed three models to be credible:** the first could not test the idea at all, the second was too loosely calibrated to trust, and only the third, tightly calibrated with the assumption made explicit, supports the statement "even with a favourable model, documented fishing does not trap cod".
- **The summary document was not the source of truth:** eight of its figures differed from the underlying data files. Having the paper agent check each number against the files, not the summary, caught these before they reached the manuscript.
`─────────────────────────────────────────────────`

You can find the entire conversation in `conversation.md`
