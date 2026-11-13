# Mizer

Mizer is an R package for dynamic multi-species size-spectrum modelling of
fish communities. It tracks the full size distribution of each species and
the plankton resource, computing growth, predation, and mortality from
individual-level physiology.

This card is a routing table, not a reference. It says where the answer lives —
in a task skill, or in the installed mizer's help pages — and deliberately does
not restate the answer, because a summary you can act on without opening the
skill is a summary you will act on while it is out of date.

## Do not write mizer code from memory

Mizer's API has evolved, and outdated calls often still run and return
plausible results. Before calling a mizer function, inspect the version installed
in this project rather than relying on memory or online documentation.

For the full help page, use
`Rscript -e 'help("functionName", package = "mizer", help_type = "text")'`.
Run it from the project directory without --vanilla, so project library
settings such as renv apply.
For a quick signature check, use `args(mizer::functionName)`. The
mizer API index names functions and the task skills describe workflows, but
neither provides argument lists.

If the installed mizer disagrees with this card or any skill, the installed
package wins. Report any discrepancy to the user rather than quietly working
around it.

## Reporting bugs in mizer

If a mizer function behaves differently from what its installed help page led
you to expect, treat it as a bug in mizer rather than quietly working around it:

1. **Do not silently patch or work around the discrepancy.**
2. **Create a minimal reproducible example (reprex)** isolating the unexpected
   behaviour, noting the installed mizer version (`packageVersion("mizer")`).
3. **File an issue on the mizer issue tracker** at
   <https://github.com/sizespectrum/mizer/issues>. If the GitHub CLI (`gh`) is
   available and authenticated, you may offer to run:
   ```bash
   gh issue create --repo sizespectrum/mizer --title "..." --body "..."
   ```
   Otherwise, present the ready-to-paste title, description, and reprex to the
   user with the link.

*(Note: Issues with this agent card, skills, or `mizerAgents` tooling belong on
<https://github.com/sizespectrum/mizerAgents/issues> instead.)*

## Key objects

**`MizerParams`** holds all model parameters; **`MizerSim`** is what `project()`
returns. Never modify slots directly. Every `new…`/`set…`/`match…`/`calibrate…`
function returns a *new* object, so always reassign — `params <- setFishing(params, ...)`.

## Task skills

Step-by-step guides for common mizer tasks are installed as skills in `.claude/skills/`, with an identical copy in `.agents/skills/` for the agents that look there. Your tool lists them by name and description: **read the matching one before starting** such a task rather than working from memory. They are the reference this card is not: workflows, argument tables and the failure modes of each step. If your tool lists no mizer skills, find the right one yourself from the `description` at the top of each `.agents/skills/<name>/SKILL.md`.

Each skill ends by naming its `NOTES.md`, which records what earlier work in this project found and is where new project-specific findings go.

Do not edit `SKILL.md` or this card: both are installed by `mizerAgents::setup_mizer_agent()`. Project notes that belong to no single skill go in `AGENTS.md` / `CLAUDE.md`, outside the `<!-- mizerAgents: ... -->` markers. A lesson that is true of mizer in general rather than of this project belongs upstream, where every project gets it: tell the user, and offer to report it at <https://github.com/sizespectrum/mizerAgents/issues>.

## The user's live R session

This project is configured with an MCP server named `r-mizer` (provided by
the [btw](https://posit-dev.github.io/btw/) package) that connects you to the
R session the user is working in. Use it:

- **Inspect what the user already has.** `btw_tool_env_describe_environment`
  lists the objects in their global environment; do not rebuild a
  `MizerParams` or re-run a simulation that is already sitting there.
- **Read what they are looking at.** `btw_tool_ide_read_current_editor`
  returns the document open in the editor, which is usually the thing a
  vague request refers to. It works only when the user is in RStudio or
  Positron; in any other editor it errors, which tells you nothing about
  the rest of the session. Ask them which file they mean instead.
- **Look functions up through it.** `btw_tool_docs_help_page` returns the
  same help page as the `Rscript` command above, without starting a new R
  process for each lookup.
- **Run mizer code in their session, not in a scratch script.**
  `btw_tool_run_r` evaluates in their global environment, so results
  persist and the user can carry on with them. Plots come back to you as
  images: after calibrating or projecting, plot the result and *look at it*
  before reporting success.
- **That session holds their work.** You are in *their* global
  environment: assigning over an existing object destroys it, and `load()`
  and `rm()` reach everything they have open. There is no undo and nothing
  warns you. Assign to a new name, or say what you are about to overwrite
  first, and do exploratory work in a throwaway environment or a separate
  `Rscript` -- keep the session itself for the steps whose result the user
  wants to keep. Say so whenever you do change a global. Long projections
  block their console, so keep `t_max` modest unless asked otherwise.

If these tools are missing, the user has not connected their session; ask
them to run `mizerAgents::connect_mizer_agent()` in their R console, rather
than working around it.

## Finding the right mizer function

Grep the mizer API index to find which function you need. It lists every
   exported function with a one-line description, grouped by workflow stage
   (creating a model, tuning the steady state, projecting, plotting). Grep
   it for a keyword; do not read the whole file:
   /home/gustav/R/x86_64-pc-linux-gnu-library/4.6/mizer/llms.txt

The index deliberately carries no argument lists. Once you have the name,
inspect the installed mizer as described above.
