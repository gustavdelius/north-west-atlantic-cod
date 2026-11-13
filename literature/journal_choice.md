# Journal choice for the eastern Scotian Shelf cod / forage-fish mizer paper

Prepared 2026-11-13. Every factual statement carries a source key, such as [S1]. The
keys resolve to URLs in the **Sources** list at the end. All sources were accessed on
**2026-11-13**. Anything I could not reach or confirm is marked **NOT CONFIRMED**.

---

## 0. Strategic note added after the literature search (read first)

The closest prior work is **Adekoya, Tittensor, Boyce, Fulton & Blanchard (2026)**,
"Re-examining top-down forcing on the Eastern Scotian Shelf fish community using a
multispecies size spectrum model", *ICES J. Mar. Sci.* 83(10): fsag195,
doi:10.1093/icesjms/fsag195. It was accepted 28 Aug 2026 and published 6 Oct 2026; it is
open access. It is a 19-species **mizer** model of the eastern Scotian Shelf (1978–2024),
and it compares rising grey-seal predation with a no-seal-increase counterfactual. Its
abstract reports that the extra seal effect on cod weakens as forage-fish predation on
small cod increases, which it says is "consistent with cultivation–depensation dynamics".
By its own text it does **not** test alternative stable states, hysteresis or more
fishing on forage fish (see `notes.md`).

Consequences for the choice of journal:
- It does not change the recommendation, but the paper must **explicitly position itself
  against Adekoya et al. (2026)**. The new content is (i) bistability and hysteresis,
  (ii) the forage-fishing intervention, and (iii) the mechanism analysis. Expect its
  authors (Blanchard, Tittensor, Boyce, Fulton) among the reviewers at any journal.
- ICES JMS has just published that model, so a follow-up there would sit naturally next
  to it. ICES JMS might also judge the new paper less novel. CJFAS remains the venue where
  the Scotian Shelf cod debate took place (Bundy & Fanning 2005; Swain & Mohn 2012), and
  where a Discussion/Reply exchange with DFO authors is most likely.
- I could not re-open the CJFAS author-guidelines page myself; cdnsciencepub.com
  returned HTTP 403 to my fetcher. The CJFAS figures below come from the delegated read
  of that page (sources [S1]–[S5]) and should be re-checked before submission.

## 1. Recommendation

**Stay with CJFAS and submit as a *Research article*.** None of the alternatives is a
clearly better fit, and two of them are worse on scope.

**Scope fit.** CJFAS's scope statement names "Modelling, simulation, or forecasting that
informs management of populations, habitats, and ecosystems" as a core topic. It also
lists "Population dynamics and demographics that support assessment and conservation".
The journal says it publishes research articles that are "theoretical or empirical" [S2].
A multispecies size-spectrum model that explains non-recovery and tests a fishing
intervention falls squarely in scope.

**Audience.** The papers this manuscript directly builds on or argues with are all in
CJFAS:
- Walters & Kitchell (2001), the cultivation/depensation hypothesis, CJFAS 58: 39–50 [S20a].
- Swain & Sinclair (2000), pelagic fishes and the cod recruitment dilemma, CJFAS 57: 1321–1325 [S20b].
- Bundy & Fanning (2005), trophic explanations for non-recovery of eastern Scotian Shelf cod, CJFAS 62: 1474–1489 [S20c].
- Swain & Mohn (2012), forage fish and the recovery of eastern Scotian Shelf cod, CJFAS 69: 997–1001 [S20d].

Publishing in CJFAS puts the paper in the same conversation, and in front of the editors
and reviewers who know that literature. CJFAS is affiliated with the Society of Canadian
Aquatic Sciences [S2].

**Practicalities favour CJFAS.**
- **Length.** The typical limit for a Research article is 10,000 words [S1]. A mizer paper
  has to cover model structure, calibration, the role-reversal mechanism and fishing
  scenarios, and that fits without pushing core methods into supplements. ICES JMS
  expects roughly 3,000–7,000 words *including* references, figures and tables [S11].
- **LaTeX.** LaTeX is accepted both at submission [S4] and for production files [S5].
- **Fees.** There are no page charges, and open access is optional [S3].
- **Preprints.** CSP will consider papers that already exist as preprints [S4]. ICES JMS
  stopped considering preprinted manuscripts from 30 March 2026 [S11][S14].
- **Data and code.** CJFAS has a strict policy that includes simulation code, but an
  R/mizer workflow deposited on Zenodo or Dryad meets it easily [S1].

**Points to watch at CJFAS:**
- The abstract is limited to 175 words [S1], which is short for a modelling paper.
- All data and code needed to reproduce the results must go to a DOI-issuing repository by
  acceptance. They must also be available to editors and reviewers *at submission* [S1].
- Fish names follow the AFS *Common and Scientific Names of Fishes*, with capitalised
  common names, as of April 2026 [S1]. So write "Atlantic Cod", not "Atlantic cod".
- Any use of generative-AI tools must be disclosed at submission, including the tool's
  name and model/version. Writing help goes in the Acknowledgements; use in research or
  code goes in Methods [S1].
- The 2025 Impact Factor is 2.5. The median time to first decision (with review) is
  71 days, and the acceptance rate is 48% [S2].

**When to switch.** ICES JMS is the realistic alternative. It makes sense if you want a
fully open-access venue with an ICES/European audience, can cut to about 7,000 words
including references and display items, and have **not** posted (and will not post) a
preprint [S11][S13][S14]. Do not send this paper to Fish and Fisheries: it puts primary
research articles out of scope unless they have "very large spatial, temporal, or
taxonomic scope" [S15].

**Other journals briefly (none is markedly better):**
- **Ecological Applications** "rarely publishes papers focused on the management of a
  single species or particular habitat" unless the paper is of wide relevance [S18].
  It is only worth trying if the paper is reframed around role reversal as a general
  mechanism.
- **Ecology Letters** limits Letters to 5,000 words and 6 figures, tables or boxes, and
  aims at "the most novel research in ecology" [S19]. It does not suit a
  management-oriented case study.
- **Marine Ecology Progress Series** was **NOT ASSESSED**: its site
  (https://www.int-res.com/journals/meps/meps-home/) returned HTTP 429 (too many requests).

---

## 2. Comparison table

| | **CJFAS** (Canadian Science Publishing) | **ICES J. Mar. Sci.** (OUP) | **Fish and Fisheries** (Wiley) |
|---|---|---|---|
| **Scope fit** | Explicit: "Modelling, simulation, or forecasting that informs management of populations, habitats, and ecosystems" [S2]. **Strong fit.** | Marine science, including living resources, with the journal as "a foundation for scientific advice" on management and conservation [S12]. **Good fit.** | Synoptic or synthesis papers. Primary research is out of scope unless of very large spatial, temporal or taxonomic scope [S15]. **Poor fit.** |
| **Article type to use** | Research article [S1] | Original article [S11] | Original article (synoptic studies only) [S15] |
| **Word limit** | Research article: "Typically limited to 10,000 words" [S1]. The page does not say whether references count. | Original article: "Generally 5-12 pages (approximately 3000- 7000 words)", including text, references (target 50–60), figures and tables [S11] | Original article: "Up to 10,000 words", including references. These are suggested lengths, not limits [S15]. |
| **Abstract limit** | 175 words [S1] | 350 words [S11] | 250 words [S15] |
| **Figure/table limits** | None stated for Research articles. Communications are limited to 2 figures and/or tables [S1]. | No numerical limit found, but the page text was truncated, so a limit is **NOT CONFIRMED** absent. Figures sized 85 mm or 170 mm wide [S11]. | None stated [S15] |
| **Reference style** | Harvard, (Author Year), alphabetical, unnumbered. "Include DOIs and hyperlinks whenever possible" [S1]. | Oxford SCIMED, name–date in text. The example reference shows the DOI as `https://doi.org/…`. Use `natbib.bst` with BibTeX [S11]. | Free format at submission: any consistent style [S15]. The final published style is **NOT CONFIRMED**. Wiley converts references in production [S17]. |
| **LaTeX accepted? / template** | Yes: Word, PDF or LaTeX at submission [S4], and DOC/DOCX or LaTeX for production [S5]. No CSP template found on the pages checked. Legacy `nrc` class on CTAN (v2.01a, 2013; two-column `nrc2.cls`) [S7][S8] and an Overleaf "NRC Research Press" template [S9]. | Submit as PDF or Word. TeX source is requested after acceptance. The journal "strongly recommends" its own TeX template (`ices.zip`) [S11]. | Not mentioned in the journal guidelines [S15]. Wiley offers a generic LaTeX template, and a LaTeX main document must be accompanied by a PDF [S17]. |
| **OA / APC** | Subscription (hybrid). Optional OA fee $3,950 for manuscripts submitted after 1 Jan 2026. No page charges. Fees are in CAD for authors in Canada and USD elsewhere [S3]. | Fully OA. APC for Original Articles £2,935 [S13]. A USD figure is **NOT CONFIRMED** (see notes). | Hybrid. Optional OA APC $5,510 / £3,640 / €4,580 [S16]. |
| **Data/code policy** | **Mandatory**: all data and code to reproduce the results, "including code to reproduce statistical results, simulation results, and figures", in a DOI-issuing repository at publication. Must be available to reviewers at submission [S1]. | Data Availability Statement required. Data and code "strongly encourage[d]" where ethically feasible [S11]. | Data "expect[ed]" in a public repository, plus a Data Availability Statement. Scripts archived "whenever possible" [S15]. |
| **Manuscript format** | Double-spaced, single column, page numbers, continuous line numbers [S1][S4] | Format-free, but easy to review, for example "with line numbers, double line spacing" [S11] | Free format. Main text with line numbers [S15]. |
| **Preprints** | Allowed [S4] | **Not considered** for submissions from 30 Mar 2026 [S11][S14] | Allowed on non-commercial servers [S15] |

---

## 3. Per-journal notes

### 3.1 Canadian Journal of Fisheries and Aquatic Sciences (CJFAS)

**Scope.** CJFAS describes itself as "an international journal for fisheries and aquatic
science related to freshwater and marine environments across the world". It publishes
"research articles (theoretical or empirical), perspectives, communications, and
reviews" [S2]. The topic list includes modelling and simulation that informs management
of populations, habitats and ecosystems, and population dynamics for assessment and
conservation [S2]. Peer review is single-anonymous [S2]. Since January 2025 the journal
publishes continuously [S2].

**Article types and lengths** [S1]:
- **Research article:** "Studies of broad scope that are original contributions to science". Typically limited to 10,000 words.
- **Review:** typically limited to 10,000 words. Free access on publication.
- **Perspective:** "Syntheses, critical reviews, and re-evaluations of current concepts and paradigms". Typically limited to 10,000 words. Free access on publication.
- **Communication:** "New concepts, methodology, and topical or controversial subjects". About 2,500 words, at most 12–15 references, and two figures and/or tables in total. The current page uses only the name "Communication"; I found no "Rapid Communication" type on it.
- **Discussion and Reply:** about 2,000 words. This is the comment format [S1][S4].
- **Methods:** 5,000 words including references, tables and figures.

A web-search snippet of this page gave the Perspective limit as 2,000 words, but the live
page says 10,000 [S1]. Treat the live page as authoritative.

**Abstract and order.** The abstract may not exceed 175 words for any article type [S1].
It must be a single paragraph without citations [S1]. A Research article runs in this
order: title page, abstract, keywords, Introduction, Materials and methods, Results,
Discussion, acknowledgements, references [S1]. A graphical abstract is optional, at most
40 mm high by 85 mm wide [S1].

**Format.** The manuscript must be in English or French, double-spaced, single column,
with page numbers and continuous line numbers, on letter or A4 pages [S1]. Equations are
numbered in parentheses flush with the left margin [S1]. Complex equations should be
supplied "in an editable format by using LaTeX or a math editor (MathType)" [S1]. Units
are SI [S1].

**Figures and tables.**
- No count limit is stated for Research articles [S1].
- Tables should be supplied in an editable format, "i.e., Word … or Excel" [S1]. At
  production, however, the publication-process page lists DOC/DOCX and LaTeX as
  acceptable for "Editable text, tables, and equations" [S5]. If tables are kept in
  LaTeX, confirm with the editorial office at acceptance.
- Figures need at least 300 dpi [S5][S6] and a minimum font size of 7 pt [S6]. Do not
  rely on colour alone, and avoid red/green and rainbow palettes [S6]. The preferred
  production format is PDF; EPS and TIFF are also accepted [S5].

**Supplementary material.** Supplementary files hold extra tables, figures, detailed
calculations and data sets that are "not essential for understanding or evaluating the
manuscript" [S1]. They are numbered S1, S2, … and cited in a footnote. They are "not
edited or converted" and appear exactly as submitted [S1]. Appendices are a separate
option, numbered A1, A2, … [S1].

**References.** The journal uses Harvard style with (Author Year) citations, an
alphabetical and unnumbered list, and specific ordering rules for papers by the same
first author. "Include DOIs and hyperlinks whenever possible" [S1]. The *CSE Manual*
(8th ed.) is the recommended general guide for biological terms [S1]. Datasets must be
cited in the reference list [S1].

**LaTeX.**
- A manuscript "supplied in Word, PDF, or LaTex" is accepted at submission [S4], and
  LaTeX is accepted for production files [S5].
- **No CSP-provided LaTeX template or class is linked** from the author-guidelines,
  submission-process or publication-process pages [S1][S4][S5]. A web search found none
  either.
- The legacy NRC Research Press class `nrc` is on CTAN: version 2.01a, LPPL licence,
  included in TeX Live and MiKTeX. CTAN says "only nrc2.cls (for two-column layout)
  should be used" [S7]. Its author note, written for CSP, dates from 2012–2013 [S8].
- Overleaf has a "Template for National Research Council (NRC) Research Press Journals"
  built on `nrc2`. It showed "Last Updated: 7 years ago" when accessed [S9].
- *Practical consequence (my inference):* `nrc2` produces a two-column typeset layout,
  while CJFAS requires a single-column, double-spaced, line-numbered submission [S1]. A
  plain `article` class with `setspace`, `lineno` and author–year `natbib` is therefore
  the safer choice.
- If the paper is written in Quarto or R Markdown, the official CSL repository has a CJFAS
  style. It is author–date, prints DOIs with a `doi:` prefix, and was last updated
  2014-12-18 [S10]. Check its output against the current Harvard rules [S1].

**Open access and fees.**
- CJFAS is a subscription journal. "Fees apply only if authors choose for the article to
  be published open access", and there are no page charges [S3].
- The OA fee is $3,950 for manuscripts first submitted after 1 January 2026. It does not
  apply to Discussion, Reply, Review and Perspective, which are free access by default [S3].
- Fees are charged in CAD (plus tax) to authors in Canada and in USD elsewhere [S3].
- Discounts and waivers [S3]:
  - 25% off if the corresponding author's institution subscribes through CRKN.
  - Fee waived if the institution subscribes through the Federal Science Libraries
    Network (FSLN). FSLN includes Fisheries and Oceans Canada, so this applies for
    submissions after 1 Jan 2025.
  - Several Read & Publish agreements with named universities.
  - Research4Life need-based waivers [S3].

**Data and code.**
- "It is a condition for publication with CJFAS that authors make publicly available all
  data and code needed to reproduce those results (including code to reproduce
  statistical results, simulation results, and figures) at the time of publication via
  an online data repository" [S1].
- Data and code "must be available to editors and reviewers … at the time of submission"
  [S1].
- The repository must issue a DOI, for example Dryad, Figshare, OSF or Zenodo [S1]. Dryad
  deposits are free for CJFAS authors "through the end of 2026" [S1].
- Third-party data that cannot be shared is an acceptable exemption, but the dataset and
  an access contact must be described [S1].
- "Data not shown" and "data on request" from the authors themselves are not allowed [S1].
- A data availability statement is required [S1].

**Other policies.**
- *AI disclosure:* report the tool and its model/version at submission. Writing help goes
  in the Acknowledgements; use in research, analysis or code goes in Methods [S1].
- *Fish names:* AFS *Common and Scientific Names of Fishes*, with capitalised common
  names, from April 2026 [S1].
- *Author contributions:* a CRediT author-contribution statement is required [S1].
- *Preprints:* allowed under CSP's preprint policy [S4].

### 3.2 ICES Journal of Marine Science (Oxford University Press)

**Scope.**
- The journal covers marine systems and human impacts on them. "Oceanography (e.g.
  productivity-determining processes), marine habitats, living resources, and related
  topics constitute the key elements" [S12].
- It "serves as a foundation for scientific advice across the broad spectrum of
  management and conservation issues" [S12].
- The About page does not mention fisheries or ecosystem modelling explicitly [S12], but
  the "living resources"/advice framing clearly covers this paper.

**Article types** [S11]:
- **Original articles:** about 3,000–7,000 words (5–12 pages), including references (target 50–60), figures and tables.
- **Comment/Reply:** about 2,000 words.
- **Review, Food for Thought, Quo Vadimus, Stories from the front lines:** no length stated.

**Abstract.** At most 350 words [S11].

**Format.** New submissions need not follow journal style, but should be easy to review,
for example "with line numbers, double line spacing" [S11]. Upload as PDF or Word. If the
paper is written in LaTeX, the source files are requested before production [S11].

**LaTeX.** The journal "strongly recommends the use of its TeX template", downloadable
as `ices.zip` from the guidelines page. Submit all .bib, .sty and .bst files, and use
`natbib.bst` with BibTeX [S11]. A web search found no Overleaf template for the journal.

**References.** Oxford SCIMED style, cited as name–date in the text [S11]. The example
reference ends with a `https://doi.org/` link [S11].

**Figures.** Size figures to 85 mm or 170 mm wide, at 300–500 dpi [S11]. No count limit
appeared in the parts of the page I could read, but the page text was truncated, so
**NOT CONFIRMED**.

**Supplementary material.** Supplementary material is "preferred to Appendices" but must
not contain material crucial to understanding the paper. Submit it as separate files [S11].

**Open access and APC.**
- The journal is fully OA under CC BY [S12][S13].
- The APC for Original Articles and un-commissioned Reviews is **£2,935** [S13].
- Waivers are available for low- and middle-income countries, and otherwise case by case;
  Read & Publish agreements may cover the APC [S11][S13].
- The guidelines page has an interactive charge calculator. Its static text shows "3625
  USD" against a "Book review charge" and a 20% "Society membership discount" option
  [S11]. I could not tie a USD amount to Original Articles, so the **USD APC is NOT
  CONFIRMED**. The £2,935 figure comes from a separate page whose last-update date I
  could not see [S13].

**Data and code.** A Data Availability Statement is required. The journal "strongly
encourages authors to make all data and software code" available where ethically
feasible [S11]. This is weaker than CJFAS's mandatory policy.

**Preprints (important).**
- From 30 March 2026 the journal "will not consider for publication manuscripts that
  have been posted on preprint platforms". Posting a preprint during review is
  prohibited [S11].
- A previously preprinted manuscript that has been "substantially revised" may be
  considered case by case [S11].
- The rationale is set out in Browman's editorial "ICES Journal of Marine Science's
  policy on preprints" (April 2026, vol. 83, issue 4) [S14].
- **If you intend to post a preprint, this rules ICES JMS out.**

### 3.3 Fish and Fisheries (Wiley)

**Scope.**
- The journal publishes "major synoptic papers, syntheses, reviews, meta-analyses, and
  policy and methods papers" [S15].
- "Out of scope are primary research articles except where these are of broad interest
  and of very large spatial, temporal, or taxonomic scope" [S15].
- A paper "must have a broad geographic and/or taxonomic scope and provide points of
  generic value" [S15].
- A single-ecosystem model of the eastern Scotian Shelf is therefore likely to be
  desk-rejected. The exception would be a paper reframed as a cross-ecosystem synthesis
  of predator–prey role reversal. The journal invites pre-submission scope queries to the
  Editor-in-Chief [S15].

**Article types** [S15]. These are suggested lengths including references, not hard limits:
- **Original article:** up to 10,000 words.
- **Ghoti:** up to 4,500 words.
- **Policy Perspective:** 4,000–6,000 words.
- **Methods and Practices:** 4,000–8,000 words.

**Abstract and format.** The abstract is at most 250 words, with six keywords [S15]. The
main text needs line numbers, and an Original article needs a table of contents [S15].
No figure or table limit is stated [S15].

**References.** Free-format submission: references "may be submitted in any style or
format, as long as it is consistent throughout" [S15]. The guidelines do not state the
final house style (**NOT CONFIRMED**). Wiley says typesetters convert references to each
journal's style [S17].

**LaTeX.** The journal guidelines do not mention LaTeX [S15]. Wiley's generic page says
that many Wiley journals accept LaTeX at submission, while others want a PDF first and
the source later [S17]. It offers a LaTeX template (`WileyDesign.zip`) and asks for
BibTeX references after acceptance. A LaTeX main document must be uploaded together with
a PDF [S17].

**Open access and APC.** Hybrid journal. The optional OA APC is $5,510 / £3,640 /
€4,580, plus tax, under CC BY, CC BY-NC or CC BY-NC-ND. A Wiley Open Access Account may
cover it [S16].

**Data and code.** "Fish and Fisheries expects that data supporting the results in the
paper will be archived in an appropriate public repository". A data availability
statement is required, and scripts should be archived "whenever possible" [S15].

**Other policies.** Preprints are allowed on non-commercial servers [S15]. Any use of AI
tools must be described in Methods or Acknowledgements [S15].

---

## 4. Sources (all accessed 2026-11-13)

- **[S1]** CJFAS Author Guidelines, which combine the general CSP guidelines and the CJFAS-specific section: https://cdnsciencepub.com/journal/cjfas/authors
- **[S2]** CJFAS About (scope, metrics, peer review, affiliations): https://cdnsciencepub.com/journal/cjfas/about
- **[S3]** CJFAS Publication Fees: https://cdnsciencepub.com/journal/cjfas/publication-fees
- **[S4]** CSP Submission Process (file formats including LaTeX, double spacing, line numbers, preprints, Discussion/Reply): https://cdnsciencepub.com/authors-and-reviewers/submission-process
- **[S5]** CSP Publication Process (production file formats including LaTeX, figure formats): https://cdnsciencepub.com/authors-and-reviewers/publication-process
- **[S6]** CSP How to prepare figures: https://cdnsciencepub.com/authors-and-reviewers/preparing-figures
- **[S7]** CTAN package `nrc`: https://ctan.org/pkg/nrc
- **[S8]** CTAN `nrc` author note (2012/2013, written for CSP): https://tug.ctan.org/macros/latex/contrib/nrc/00-2013-feb-authors.txt
- **[S9]** Overleaf, "Template for National Research Council (NRC) Research Press Journals": https://www.overleaf.com/latex/templates/template-for-national-research-council-nrc-research-press-journals/qkzyphzsdrvp
- **[S10]** CSL style file for CJFAS (official CSL repository): https://raw.githubusercontent.com/citation-style-language/styles/master/canadian-journal-of-fisheries-and-aquatic-sciences.csl
- **[S11]** ICES JMS General Instructions: https://academic.oup.com/icesjms/pages/General_Instructions. Read via a text extractor; the page text was truncated, so some sections were only partly visible.
- **[S12]** ICES JMS About: https://academic.oup.com/icesjms/pages/About
- **[S13]** ICES JMS Open Access: https://academic.oup.com/icesjms/pages/open-access
- **[S14]** Browman, H.I. (2026), "ICES Journal of Marine Science's policy on preprints", *ICES J. Mar. Sci.* 83(4): fsag052: https://academic.oup.com/icesjms/article/83/4/fsag052/8651474
- **[S15]** Fish and Fisheries Author Guidelines (updated May 2025): https://onlinelibrary.wiley.com/page/journal/14672979/homepage/forauthors.html
- **[S16]** Fish and Fisheries Article Publication Charges: https://onlinelibrary.wiley.com/page/journal/14672979/homepage/fundedaccess.html
- **[S17]** Wiley, "Wiley's PDF design LaTeX authoring template": https://authors.wiley.com/author-resources/Journal-Authors/Prepare/latex-template.html
- **[S18]** Ecological Applications Aims and Scope: https://esajournals.onlinelibrary.wiley.com/hub/journal/19395582/aims-and-scope/read-full-aims-and-scope
- **[S19]** Ecology Letters Author Guidelines: https://onlinelibrary.wiley.com/page/journal/14610248/homepage/forauthors.html
- **[S20]** Key CJFAS papers. Journal, volume and pages were verified via Crossref metadata (https://api.crossref.org/works).
  - **[S20a]** Walters & Kitchell 2001: https://doi.org/10.1139/f00-160
  - **[S20b]** Swain & Sinclair 2000: https://doi.org/10.1139/f00-104
  - **[S20c]** Bundy & Fanning 2005: https://doi.org/10.1139/f05-086
  - **[S20d]** Swain & Mohn 2012: https://doi.org/10.1139/f2012-045

**Could not be reached or confirmed:**
- MEPS home page (https://www.int-res.com/journals/meps/meps-home/) returned HTTP 429.
- The ICES JMS USD APC for Original Articles and the existence of any ICES figure/table
  count limit could not be confirmed, because the guidelines page text was truncated.
- The final reference house style for Fish and Fisheries is not stated in its guidelines.
- No official CSP/CJFAS LaTeX template was found on CSP's site; the only templates found
  are the legacy third-party ones in [S7]–[S9].
