---
name: vault-tags
description: Canonical tag vocabulary for the Obsidian vault; frequency counts and known duplicate/variant issues to flag before canonicalizing
metadata: 
  node_type: memory
  type: reference
  originSessionId: eb15bcde-7c29-453f-b4ce-2c4803c305b5
---

## How to Use This File

When classifying a note or writing frontmatter, choose from this canonical list. Do **not** invent new tags without user confirmation. For duplicates/variants flagged below, apply the canonical form and flag the variant to the user.

---

## High-Frequency Tags (≥ 50 uses)

| Tag | Count | Notes |
|---|---|---|
| `recipe` | 367 | Canonical for recipes |
| `Bahai` | 259 | **Canonical tag form** — no diacriticals in tags (see [[feedback_tag_regex]]) |
| `NLP` | 253 | NLP / psychology |
| `home` | 156 | Home & practical life |
| `Vegan` | 151 | |
| `Health` | 149 | |
| `clippings` | 142 | Web clippings (see duplicate: `clipping`) |
| `Computers` | 139 | |
| `travel` | 100 | |
| `FOL` | 94 | Friends of Georgetown Library |
| `social` | 94 | |
| `person` | 90 | Individual person notes |
| `PKM` | 84 | |
| `Software` | 76 | |
| `Georgetown` | 65 | |
| `tech` | 63 | *Variant of* `technology` — see Duplicates section |
| `science` | 63 | |
| `email` | 62 | |
| `history` | 62 | |
| `Tools` | 60 | |
| `AI` | 57 | |
| `clipping` | 57 | *Variant of* `clippings` — see Duplicates section |

---

## Medium-Frequency Tags (20–49 uses)

| Tag | Count | Notes |
|---|---|---|
| `Geology` | 58 | |
| `gmail-recipes` | 53 | Import artifact |
| `CompuServe` | 52 | Retro computing |
| `onenote-import` | 48 | Import artifact |
| `Hardware` | 46 | |
| `Finance` | 44 | |
| `Religion` | 42 | General; `Bahai` is more specific |
| `Genealogy` | 42 | |
| `Psychology` | 41 | Co-exists with `NLP` |
| `WFPB` | 40 | Whole Food Plant-Based |
| `Sketchplanations` | 39 | |
| `Community` | 38 | |
| `MegaFlood` | 38 | |
| `LSA` | 38 | Local Spiritual Assembly |
| `music` | 37 | |
| `food` | 37 | |
| `Washington` | 37 | |
| `email-recipe` | 37 | Import artifact |
| `video` | 37 | |
| `NLPMasterClass` | 36 | |
| `2024-WashingtonTrip` | 36 | Columbia River trip tag |
| `CompuServe-Forum` | 35 | |
| `books` | 34 | |
| `Archaeology` | 32 | |
| `BahaiScripture` | 32 | Notes attributed to Central Figures (Bahá'u'lláh, The Báb, 'Abdu'l-Bahá) |
| `retro-computer` | 31 | *Variant of* `RetroComputing` — see Duplicates section |
| `DailyNote` | 31 | |
| `Windows` | 31 | |
| `art` | 30 | |
| `Medical` | 29 | |
| `ForumArchive` | 29 | |
| `RetroComputing` | 28 | *Variant of* `retro-computer` — see Duplicates section |
| `soccer` | 27 | |
| `gardening` | 27 | |
| `YearInReview` | 26 | |
| `Administrative` | 25 | Bahá'í administrative topics |
| `Obsidian` | 25 | |
| `technology` | 24 | *Variant of* `tech` — see Duplicates section |
| `cooking` | 23 | |
| `GeorgetownLSA` | 23 | |
| `BahaiFaith` | 23 | *Variant of* `Bahai` — see Duplicates section |
| `baking` | 23 | |
| `Author` | 23 | |

---

## Lower-Frequency Tags (10–19 uses)

`race`, `technique`, `Learning`, `Texas`, `GCCMA`, `Talbot`, `SoftwareLicense`, `Unity`, `Linux`, `synthesis`, `LGL`, `productivity`, `Vegetarian`, `education`, `gluten-free`, `MLS`, `language`, `library`, `family`, `indian`, `People`, `Reference`, `AustinFC`, `Japan`, `BoxScore`, `racism`, `PersonalCalendar`, `dessert`, `conservation`, `fundraising`, `PersonalHistory`, `EmailAnalysis`, `bread`, `maker`, `UHJ`, `beans`, `PiDP-8`, `electronics`, `tofu`, `oil-free`, `Template`, `FamilyTree`, `soup`, `internet`, `RC2014`, `nature`, `Ecology`, `Paleontology`, `Culture`, `Z80`, `ClaudeCode`, `breakfast`, `security`, `Asian`, `DHE`, `Writing`, `curry`, `lentils`, `Calendar`, `administration`, `organization`, `book`, `astronomy`, `Trips`, `Communications`, `Networking`, `database`, `Irish`, `Mushrooms`, `receipt`, `peace`, `EliasWhiteTalbot`, `NLP_Psy`, `DOS`, `AbdulBaha`, `HCAS`, `nutrition`, `eBook`, `Trump`, `RaceAmity`, `TheIrrationalTvShow`, `MSAccess`, `building`

---

## Known Duplicates / Variants — Pending User Decision

These pairs exist in the vault. Canonical choice has not been confirmed by user — flag when encountered.

| Canonical (preferred) | Variant(s) | Action needed |
|---|---|---|
| `clippings` | `clipping` | Confirm canonical; migrate variant |
| `Bahai` | `BahaiFaith` | `BahaiFaith` is redundant; migrate to `Bahai` |
| `technology` vs `tech` | both active at 24 and 63 | Decide canonical; merge |
| `RetroComputing` | `retro-computer` | Decide canonical (PascalCase or kebab); merge |
| `NLP` | `NLP_Psy`, `Psychology` | `NLP` is canonical; `NLP_Psy` is redundant; `Psychology` may coexist |
| `BahaiScripture` | `AbdulBaha` | `AbdulBaha` may be a person tag; check usage |

---

## Import Artifact Tags (do not propagate)

These were created during mass imports and should not be applied to new notes:
- `gmail-recipes`
- `email-recipe`
- `onenote-import`
- `CompuServe-Forum` (use `CompuServe` + `ForumArchive` instead)

---

## Special Rules

- **`BahaiScripture`**: Add to any note attributed to a Central Figure (Bahá'u'lláh, The Báb, 'Abdu'l-Bahá). Do NOT add for Shoghi Effendi or UHJ. See [[feedback_bahai_scripture_tag]].
- **`Bahai`** (not `Bahá'í`): Tags must use ASCII-safe form. Everywhere else in note content, use correct diacriticals. See [[feedback_tag_regex]].
- **`EliasWhiteTalbot`**: Triggers project-folder routing override — see [[vault_mocs]].
