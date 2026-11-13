# Empirical targets for the eastern Scotian Shelf (4VsW) model

Compiled 2026-11-13. Every number below carries its source, as a `references.bib` key, and
a page, table or figure pointer.

**Confidence tags.**
- **[R]** read in the source, by me or by the delegated agent that opened the PDF.
- **[D]** derived by me from a source dataset; the method is stated.
- **[2h]** second-hand; do not use without checking.

**Data files in `literature/data/`.** Each starts with a `#` provenance line.

| file | content | source |
|---|---|---|
| `cod_4VsW_landings_1958_2002.csv` | annual landings (total, 4Vs, 4W) and TAC, 1958–2002 | Fanning et al. 2003, Table 1 [R] |
| `cod_4VsW_assessment.csv` | survey-based (q-corrected) SSB and age-5+ biomass, 1970–2002; RV Z by age group, 1970–2001 | Fanning et al. 2003, Tables 13–14 [R] |
| `grey_seal_sable_pups.csv` | grey seal pup production (Sable, coastal NS, Gulf, Scotian Shelf), 1962–2021 | Hammill et al. 2023, Table 4 [R] |
| `ess_rv_biomass_not_qadj_derived.csv` | summer RV survey stratified biomass by species, ESS strata 443–466, 1970–2018, not catchability-corrected | derived [D] from a compilation in the Adekoya et al. 2026 code repository (see header) |
| `ess_rv_biomass_qadj_derived.csv` | as above, q-adjusted, 1970–2022 | derived [D], same repository |

The two derived files are a convenience for getting started. Before calibrating for the
paper, re-extract the series from the official DFO "Maritimes Summer Research Vessel
Surveys" dataset on open.canada.ca (Ricard et al. 2010 describe the access route), or ask
DFO Maritimes or the Adekoya et al. authors for the q-adjusted series. The repository has
no licence file.

---

## 1. System definition

| quantity | value | source |
|---|---|---|
| Region | NAFO Division 4W plus subdivision 4Vs; ESS survey strata 443–466 | `adekoya2026reexamining` (methods) [R]; `dfo2010greyseals` |
| Area of the ESS (4VsW) | **≈110,000 km²** | `dfo2010greyseals` p. 7 [R] |
| Area implied by the Ecopath model (4VsW to 500 m) | ≈102,500 km² (from 14,559 t = 0.142 t km⁻²) | `bundy2004mass` p. 11 [D] |
| Bottom temperature in the late 1980s–early 1990s | coldest in about 50 years on the eastern shelf | `zwanenburg2000effects` abstract [R] |

For comparison, the southern Gulf of St Lawrence is about 75,000 km²
(`swain2015spatial`, abstract [R]).

---

## 2. Atlantic cod, 4VsW

### 2a. Timeline

| event | date | source |
|---|---|---|
| Peak landings | **80,428 t in 1968** | `fanning2003assessment` Table 1 [R] |
| Landings 1958–74 | 40–80 kt/yr; 10,390 t in 1977; 50–57 kt/yr in 1981–86 | same [R] |
| Decadal mean landings | 61.9 kt (1958–69), 40.2 kt (1970s), 49.3 kt (1980s), 12.7 kt (1990–97) | `dfo2003ssr4vsw` (Proceedings 2003/021 p. 72) [R] |
| F relative to Fmax | F above Fmax in 1988–92 | `mohn1994assessment` abstract [R] |
| Landings in the early 1990s | 34,403 t (1990), 33,068 t (1991), 29,892 t (1992), 3,294 t (1993) | `fanning2003assessment` Table 1 [R] |
| **Moratorium** | directed fishery closed **1 September 1993**; restricted bycatch since | `mohn1994assessment` p. 2; `fanning2003assessment` p. 1 [R] |
| Landings after the closure | 355 t (1994) falling to 83 t (2002) | `fanning2003assessment` Table 1 [R] |
| COSEWIC status | Laurentian South DU (includes 4VsW) **Endangered**, April 2010; 90% decline | `cosewic2010cod` p. iii [R] |
| Latest full assessment | the 2011 RPA; nothing later was found | `mohn2012laurentian`, `dfo2011rpa` [R] |

For comparison:
- Northern cod (2J3KL) moratorium: July 1992 (`olsen2004maturation` abstract [R]).
- Southern Gulf (4TVn) closure date: **not verified** here.

### 2b. Biomass

| quantity | value | source |
|---|---|---|
| Survey-based (q-corrected) SSB | peak **171.6 kt (1984)**; **4.7 kt (2002)**, a 97% decline | `fanning2003assessment` Table 13, p. 22 [R]; annual series in CSV |
| VPA SSB minimum | ≈7.5 kt in 2003 (abstract); p. 6 says 6.3 kt in 2001, inconsistent | `mohn2012laurentian` p. v, p. 6 [R] |
| VPA SSB in 2009 | 64 kt (temporary rise; strong 2004 year class) | `mohn2012laurentian` p. v [R]; `swain2012forage` abstract [R] |
| Long-term mean SSB (VPA) | 75 kt | `mohn2012laurentian` p. v [R] |
| B_MSY (productive period to 1990) | 135 kt (123 kt at the 2010 framework meeting) | `mohn2012laurentian` pp. 6–7 [R] |
| Limit reference point | **50 kt** SSB (0.4 B_MSY), adopted 2012. The 2010 framework had proposed 33 kt. SSB below the LRP since 1992 except 2009 | `dfo2011rpa` p. 3; `dfo2011framework` p. 29 [R] |
| RV survey biomass index (summer, not q-adjusted) | 36,809 t (2020, one 5.8 t tow); none in 2022; 8,212 t (2023); 4,691 t (2024) | `dfo2024rvtrends` Table 1; `dfo2025rvtrends` Table 1 p. 8 [R] |
| Current status indicator | 3-year geometric mean 11,234 t, between 40% and 80% of the long-term geometric mean | `dfo2025rvtrends` p. 8 [R] |
| Survey ratio, 1995–2004 mean ÷ 1980–89 mean | **0.10** (not q-adj.), 0.13 (q-adj.) | [D] from `ess_rv_biomass_*_derived.csv` |
| Area occupied (summer survey) | ≈75,000 km² (1970s–early 80s) falling to ≈33,000 km² (2002) | `mohn2012laurentian` pp. 3–4 [R] |
| Mean individual weight, targeted demersals, ESS | −51% since the 1970s | `zwanenburg2000effects` abstract [R] |

### 2c. Fishing mortality

| quantity | value | source |
|---|---|---|
| F 1988–92 | above Fmax | `mohn1994assessment` [R] |
| Seal predation versus fishing before the closure | seal predation mortality was 10–20% of F | `mohn1996grey` abstract [R] |
| F after 1993 (ages 5–15) | mean 0.035; recently ≈0.01 | `mohn2012laurentian` p. v [R] |
| Exploitation rate since 1994 | below 2% | `cosewic2010cod` p. 100 [R] |

### 2d. Natural mortality: before versus after

| period | M (instantaneous unless stated) | source |
|---|---|---|
| Assumed historically (VPA before 1970) | 0.2 | `mohn2012laurentian` p. 2 [R] |
| "Normal" adult cod | 15–20%/yr | `dfo2011rpa` p. 6 [R] |
| Laurentian South DU adults, last ≈20 yr (to 2011) | 45–50%/yr, ≈0.6–0.7 instantaneous | `dfo2011rpa` p. 6 [R]; conversion [D] |
| ESS after the closure (survey Z ≈ M) | ≈1.0 older ages, ≈0.5 younger ages | `fanning2003assessment` p. 5 [R]; Table 14 in CSV |
| ESS VPA M, ages 5+ | peak ≈1.1 (1990s–early 2000s); mean 0.8 (1990–2004); ≈0.6 (last 5 yr); 0.36 at end of series | `mohn2012laurentian` pp. v, 5, 12 [R] |
| ESS, ages 3–8, 2004–08 | Z = 0.845 (SE 0.151), 57%/yr | `cosewic2010cod` Table A2 p. 99 [R] |
| ESS after the closure, partitioned | seals 0.21 + other unknown 0.62 | `trzcinski2006continued` abstract [R] |
| ESS 2009, partitioned | seal M 0.013–0.166 of total Z ≈ 0.75 | `trzcinski2011estimating` abstract [R] |
| ESS 2009, by size (DFO seal SAR) | cod <35 cm 0.2–0.8; cod >35 cm 0.2–0.7 | `dfo2010greyseals` p. 14 [R] |
| M needed for recovery | ≈0.3 | `mohn2012laurentian` p. 7 [R] |

Southern Gulf, for comparison:
- M ≈ 0.4 by the late 1990s (`sinclair2001natural` [R]).
- Ages 5–8: 0.18 at the start of the series, 0.43 (2000), 0.81 (2018). Ages 9+: 0.93
  peak (2010) (`swain2019assessment` p. 14 [R]).
- Adults above 0.8 in 2023 (`dfo2024sgsl` [R]).

### 2e. Recruitment
- ESS cod recruitment rate is **unrelated to forage-fish biomass**; the strong 2004 year
  class drove the late-2000s increase (`swain2012forage` abstract [R]).
- Fu et al. 2001: low recruitment after the closure contributed to non-recovery
  (`fu2001why` abstract [R]).
- A recruitment series by year was **not transcribed**. VPA numbers at age for 1970–93
  are in `mohn1994assessment` tables, available but not transcribed.

---

## 3. Forage fish and other species: before versus after the collapse

| quantity | value | source |
|---|---|---|
| ESS forage-fish complex peak | **≈900% above** pre-collapse levels (×10); then declined after exhausting zooplankton | `frank2011transient` abstract [R] |
| Ratio of pelagic to demersal feeders (Ecopath) | **0.3 (1980–85) → 3.0 (1995–2000)** | `bundy2005structure` abstract [R]; periods [2h] |
| Biomass at trophic levels 3–4 | increased significantly; total system biomass similar | `bundy2005structure` abstract [R] |
| Forage-fish recruitment scaling needed in the ESS mizer model | rmax ≈8× steady-state value | `adekoya2026reexamining` methods [R] |
| Capelin | reappeared on the ESS from the late 1980s (cold anomalies); reproduced (1993 year class) | `frank1996recent` abstract [R] |
| Shrimp and snow crab | increased with the cod collapse | `bundy2005can` abstract [R]; `frank2005trophic` [2h] |

**Derived survey ratios [D].** These come from `ess_rv_biomass_not_qadj_derived.csv`. The
ratios are identical in the q-adjusted file because q is constant by species. Values are
period means of annual stratified biomass, divided by the 1980–89 mean.

| species | 1970–79 | 1995–2004 | 2005–12 | 2013–18 |
|---|---|---|---|---|
| Atlantic cod | 0.53 | **0.10** | 0.20 | 0.09 |
| Haddock | 0.41 | 0.61 | 0.72 | 0.37 |
| Silver hake | 0.31 | 0.60 | 0.73 | 0.77 |
| American plaice | 1.24 | 0.45 | 0.41 | 0.17 |
| Atlantic herring | 0.44 | **6.55** | 3.21 | 5.43 |
| Northern sand lance | 5.93 | **40.5** | 28.9 | 19.3 |
| Capelin | 0.11 | **31.1** | 5.2 | 0.47 |
| Mackerel | 0.24 | 0.21 | 0.19 | 0.33 |
| Herring + sand lance + capelin + mackerel | 0.49 | **4.99** | 2.63 | 3.79 |

**Caveats on the survey ratios.**
- The summer bottom trawl samples pelagic, schooling fish (herring, mackerel) and buried
  sand lance poorly, so year-to-year values are noisy. Use period ratios only.
- Mackerel is migratory and essentially unsampled; the survey shows **no** mackerel
  increase. The forage-fish signal on the ESS is herring, sand lance and capelin.
- The late periods mix q-adjusted data (to 2022) and non-adjusted data (to 2018); the
  table uses the non-adjusted series.
- The 1980s sand lance and capelin baselines are tiny: mean sand lance survey biomass was
  6× lower in the 1980s than in the 1970s. Their ×30–40 ratios are therefore unstable.
  Against the 1970s, sand lance in 1995–2004 is ×6.8.
- The 1995–2004 peak followed by a decline in 2005–12 is consistent with
  `frank2011transient`.

---

## 4. Grey seals

| quantity | value | source |
|---|---|---|
| Sable Island pup production | ≈400 (1963); 25,400 (1997; 95% CI 23,500–26,900); 41,500 (2004; SE 4,381); 62,054 (2010); 87,495 (2016, revised); **76,600 (2021)**, the first decline in about 60 yr | CSV; `bowen2003sustained`; `bowen2007reduced`; `hammill2023grey` Table 4; `dfo2022greyseal` p. 2 [R] |
| Pup production growth | 12.8%/yr for four decades to 1997; r = 0.070 by 2004; ≈4%/yr 1997–2016; maximum 14%/yr | `bowen2003sustained`; `bowen2007reduced`; `hammill2023grey` p. 1; `denheyer2024pup` p. 1 [R] |
| Total NW Atlantic population | ≈10,000–13,000 (1960); 330,000–410,000 (2010; Sable herd 260,000–320,000); 424,300 (2016; revised 339,400); **366,400 (2021; 95% CI 317,800–409,400)**, of which 310,700 on the Scotian Shelf | `dfo2010greyseals` pp. 3, 8; `hammill2017grey`; `dfo2022greyseal` p. 2; `hammill2023grey` [R] |
| Seals in the 4VsW model area | ≈5,000 (1970) → 64,000 (1994); total consumption 10,000 → 121,000 t/yr | `mohn1996grey` abstract [R] |
| Sable herd when cod was productive versus 2011 | <50,000 versus ≈300,000 | `mohn2012laurentian` p. 13 [R] |
| Cod in grey-seal diet (ESS) | <5% (1993–2000, QFASA); 2–7% | `trzcinski2006continued` [R]; `dfo2010greyseals` p. 4 [R] |
| Grey-seal diet near Sable (1991–93, faeces) | **sand lance 69.2%**, cod 15.5%, flatfish 10.7% of wet weight | `bowen1994offshore` abstract [R] |
| Cod eaten by seals in 4VsW | 3,000–11,000 t/yr (2010 SAR); 6,300–15,400 t in 1994 | `dfo2010greyseals` p. 5; `mohn1996grey` [R] |
| Seal share of total cod mortality (ESS) | <17% in most models | `dfo2010greyseals` p. 5 [R] |
| Size of cod eaten (southern Gulf / Cabot Strait) | mean 28 cm (Cape Breton coast), 39 cm (Cabot Strait) | `hammill2014feeding` abstract [R] |

---

## 5. Diet evidence relevant to the mechanism

| link | evidence | source |
|---|---|---|
| Cod becomes piscivorous | mainly fish from ≈50 cm; on the Nova Scotia banks the main fish prey is **sand lance** | `kohler1969comparisons` abstract [R] |
| Sand lance in cod diet | sand lance is an important cod prey on the banks | `scott1968morphometrics` abstract [R] |
| Cod eating herring (southern Gulf) | herring share of prey mass, cod 46–60 cm: 1.3% (1959–80) → 19.6% (1987–2000); cod 61–75 cm: 9.4% → 54.2% | `hanson2002diet` abstract [R] |
| Forage fish eating cod eggs (North Sea) | herring ate an estimated 0.04–0.19% of cod eggs (0.7–1.9% of plaice eggs) | `daan1985predation` abstract [R] |
| Forage fish eating cod eggs (Baltic) | sprat and herring consumed a "considerable proportion" of eggs early in the season, 1988–95; later work shows earlier estimates were too high and predation lower in the 2000s | `koster2000trophodynamic`; `neumann2014recovery`; `neumann2017quantifying` [R] |
| Herring predation on gadid larvae (Georges Bank) | strong spatial overlap of herring with haddock larvae, and with cod larvae in 1995; predation "likely important" (no consumption estimate) | `garrison2000predation` abstract [R] |
| Statistical: pelagic biomass versus cod recruitment | negative in the southern Gulf; P(negative herring effect) = 0.94 across 14 North Atlantic regions; mackerel 0.68; **no relationship on the ESS** | `swain2000pelagic`; `minto2012interactions`; `swain2012forage` [R] |
| Small cod predation and competition (ESS Ecopath) | high predation on small cod; competition with forage fish; poor condition | `bundy2005can` abstract [R]; diet fractions **not read** |

**Gap.** I found no direct ESS stomach-content evidence of herring, sand lance or
mackerel eating cod eggs or larvae.

---

## 6. Life-history parameters

FishBase species summary pages were read on 2026-11-13 (`froese2026fishbase`).
Length–weight relations are W = a·L^b, with W in g and L in cm total length; they are
FishBase Bayesian estimates (`froese2014bayesian`). L_max is the maximum length.
L_m is length at first maturity.

| species | L_max (cm) | max weight | max age (yr) | L_m (cm) | a | b | troph. level | source |
|---|---|---|---|---|---|---|---|---|
| Atlantic cod *Gadus morhua* | 200 TL | 96 kg | 25 | 65.4 (range 31–74) | 0.00676 | 3.08 | 4.1 | FishBase [R] |
| Haddock *Melanogrammus aeglefinus* | 112 TL | 16.8 kg | 20 | 34.9 | 0.00661 | 3.08 | 4.0 | FishBase [R] |
| Atlantic herring *Clupea harengus* | 45 SL | 1.1 kg | 25 | 16.7 | 0.00550 | 3.10 | 3.4 | FishBase [R] |
| Atlantic mackerel *Scomber scombrus* | 60 FL | 3.4 kg | 17 | 28.7 | 0.00631 | 3.07 | 3.6 | FishBase [R] |
| Capelin *Mallotus villosus* | 20 TL (25.2 ♀) | 52 g | 10 | 13.3 | 0.00363 | 3.21 | 3.2 | FishBase [R] |
| Northern sand lance *Ammodytes dubius* | 25 TL | — | 9 (t_max) | — | 0.00240 | 3.05 | 3.2 | FishBase [R] |

**von Bertalanffy K.**
- **Cod:**
  - FishBase growth table, overall: L∞ = 110 cm TL, K = 0.10 yr⁻¹.
  - Entry for **ICNAF 4V**: L∞ = 110 cm, K = 0.08.
  - Southern Gulf entries: L∞ 53.7–132 cm, K 0.08–0.29 (FishBase PopGrowth list, [R]).
- **Herring, mackerel, capelin, sand lance:** FishBase gives K only as inputs to its
  resilience estimate (herring 0.2–0.6; mackerel 0.23–0.27; capelin 0.3–0.5; sand lance
  0.33–0.38). These are **not** fitted von Bertalanffy estimates.

**Values used by Adekoya et al. 2026 (FishBase via rfishbase),** read from
`Ess_data/ESS_species_params.csv` in `adekoya2026code` [R]. They are worth matching for
comparability.

| species | w_max (g) | l_mat (cm) | age_mat (yr) | k_vb (yr⁻¹) | a | b |
|---|---|---|---|---|---|---|
| Atlantic cod | 82,637 | 66.5 | 6.18 | 0.163 | 0.00676 | 3.08 |
| Haddock | 13,539 | 35.0 | 2.8 | 0.24 | 0.00661 | 3.08 |
| Silver hake | 3,383 | 22.9 | 1.65 | 0.384 | 0.00479 | 3.11 |
| Pollock | 20,408 | 55.0 | 4.75 | 0.145 | 0.00661 | 3.07 |
| White hake | 20,482 | 33.9 | 1.4 | 0.162 | 0.00398 | 3.16 |
| American plaice | 4,742 | 26.0 | 6.43 | 0.093 | 0.00646 | 3.06 |
| Redfish (*S. fasciatus*) | 1,753 | 21.6 | 5.5 | 0.119 | 0.01023 | 3.13 |
| Spiny dogfish | 16,852 | 79.0 | 10 | 0.08 | 0.00288 | 3.07 |
| Thorny skate | 11,718 | 66.3 | 7.45 | 0.105 | 0.00316 | 3.25 |
| Atlantic herring | 733 | 25.3 | 3 | 0.33 | 0.00550 | 3.10 |
| Northern sand lance | 44 | 8.75 | 1.5 | 0.34 | 0.00240 | 3.05 |
| Capelin | 54.5 | 13.0 | 2 | 0.48 | 0.00363 | 3.21 |

(Values are rounded from the CSV.)

**Further sources.**
- NW Atlantic-specific length–weight relations are in `wigley2003length` (NEFSC surveys,
  1992–99). That document was not opened; it is the recommended source if regional a and
  b are wanted.
- Scotian Shelf sand lance growth and maturity (winter spawner, larger than elsewhere)
  are in `scott1968morphometrics`, full text not read.
- 4VsW cod maturity ogives and weights at age are in `fanning2003assessment` and
  `mohn2012laurentian`, not transcribed. Cod size and age at maturity declined
  (`hutchings2005life`, `olsen2004maturation`), so a single L_m is a simplification.

---

## 7. Suggested calibration and validation targets

These are my synthesis, not taken from a source.

1. **Pre-collapse steady state (around 1980–85).**
   - Cod SSB about 100–170 kt (survey-based peak 171.6 kt in 1984), with M ≈ 0.2 and
     landings 50–57 kt/yr.
   - Forage fish at roughly one-fifth of the 1995–2004 level.
   - Seals at well under 50,000 on Sable Island.
2. **Collapsed state, F ≈ 0 (around 1995–2005).**
   - Cod survey biomass about 0.1× the 1980s level; SSB 5–10 kt; adult M about 0.6–1.0.
   - Forage fish about 5–10× the pre-collapse level (survey ×5; Frank et al. ×10).
   - Pelagic-to-demersal feeder ratio about 3.
3. **Hysteresis test.** Cod should stay low after F is set to about 0.01 from 1994.
   - Check whether recovery appears when forage biomass declines (2005–12 survey ×0.5 of
     the peak), as `frank2011transient` and the 2009 SSB of 64 kt suggest.
   - Check this against `swain2012forage`, which attributes the 2009 rise to the 2004 year
     class and lower M.
4. **Seal sensitivity.** Include seal predation, which takes a large sand lance share,
   as an external mortality. Report results with and without the rise in seals. This
   follows the factual and counterfactual design of `adekoya2026reexamining`.
