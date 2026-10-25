---
name: Hamari Virasat
description: The family's own bahi-khata. Red cloth binding, haldi-tinted ledger leaves, ink, and one haldi string.
colors:
  cloth: "#9b1b20"
  cloth-deep: "#6c1116"
  cloth-night: "#4a0b0f"
  on-cloth: "#f6e9c9"
  on-cloth-soft: "#efcdb9"
  haldi: "#e8b23a"
  haldi-deep: "#c8901a"
  paper: "#f6e9c9"
  paper-light: "#fbf4e1"
  paper-edge: "#e3cf9f"
  ink: "#1f1a16"
  ink-soft: "#4a3f35"
  ink-faint: "#6b5a47"
  rule-red: "#c2413a"
  rule-blue: "rgba(43, 76, 133, 0.2)"
  blue-ink: "#2b4c85"
  ochre-ink: "#855700"
  leaf: "#2f6b3a"
  danger-ink: "#9c2a1d"
  error-wash: "#fbe3dc"
typography:
  display:
    fontFamily: "Martel, Rozha One, Georgia, serif"
    fontSize: "clamp(2.2rem, 3.8vw, 3.3rem)"
    fontWeight: 800
    lineHeight: 1.08
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Martel, Rozha One, Georgia, serif"
    fontSize: "clamp(2rem, 3.8vw, 2.9rem)"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  title:
    fontFamily: "Martel, Rozha One, Georgia, serif"
    fontSize: "clamp(1.5rem, 3vw, 1.9rem)"
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  entry:
    fontFamily: "Martel, Rozha One, Georgia, serif"
    fontSize: "1.25rem"
    fontWeight: 800
    lineHeight: 1.25
  devanagari:
    fontFamily: "Rozha One, Martel, serif"
    fontSize: "1.2rem"
    fontWeight: 400
    lineHeight: 1.25
    letterSpacing: "0"
  body:
    fontFamily: "Mukta, system-ui, -apple-system, Segoe UI, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "Mukta, system-ui, -apple-system, Segoe UI, sans-serif"
    fontSize: "0.85rem"
    fontWeight: 700
    lineHeight: 2rem
    letterSpacing: "0.04em"
  hand:
    fontFamily: "Kalam, Mukta, cursive"
    fontSize: "1.05rem"
    fontWeight: 400
    lineHeight: 1.25
    letterSpacing: "0"
rounded:
  stamp: "3px"
  control: "4px"
  leaf: "6px"
spacing:
  line: "2rem"
  margin-column: "2.75rem"
  gutter: "clamp(1rem, 4vw, 2.5rem)"
  leaf-inline: "clamp(1.25rem, 3vw, 2.5rem)"
  band: "clamp(4rem, 8vw, 6.5rem)"
  container: "1200px"
components:
  button-cloth:
    backgroundColor: "{colors.cloth}"
    textColor: "{colors.on-cloth}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "0.6rem 1.4rem"
    height: "3rem"
  button-cloth-hover:
    backgroundColor: "{colors.cloth-deep}"
    textColor: "{colors.on-cloth}"
  button-haldi:
    backgroundColor: "{colors.haldi}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.6rem 1.4rem"
    height: "3rem"
  button-line:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.6rem 1.4rem"
    height: "3rem"
  button-quiet:
    backgroundColor: "transparent"
    textColor: "{colors.cloth}"
    padding: "0.35rem 0.6rem"
    height: "2.5rem"
  button-small:
    padding: "0.35rem 0.9rem"
    height: "2.5rem"
  input:
    backgroundColor: "{colors.paper-light}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.55rem 0.8rem"
    height: "3rem"
  leaf:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.leaf}"
    padding: "2rem clamp(1.25rem, 3vw, 2.5rem) 2rem 4.25rem"
  stamp-done:
    backgroundColor: "transparent"
    textColor: "{colors.leaf}"
    typography: "{typography.label}"
    rounded: "{rounded.stamp}"
    padding: "0 0.5rem"
  stamp-draft:
    backgroundColor: "transparent"
    textColor: "{colors.ochre-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.stamp}"
    padding: "0 0.5rem"
  book-tab:
    backgroundColor: "{colors.cloth}"
    textColor: "{colors.on-cloth}"
    rounded: "{rounded.leaf}"
    padding: "0.7rem 1rem 0.7rem 1.1rem"
  book-tab-selected:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
  starter:
    backgroundColor: "{colors.paper-light}"
    textColor: "{colors.ink}"
    rounded: "{rounded.control}"
    padding: "0.45rem 0.9rem"
    height: "2.75rem"
  segmented-selected:
    backgroundColor: "{colors.cloth}"
    textColor: "{colors.on-cloth}"
    height: "3rem"
  site-header:
    backgroundColor: "{colors.cloth}"
    textColor: "{colors.on-cloth}"
    height: "4.5rem"
  app-bar:
    backgroundColor: "{colors.cloth-night}"
    textColor: "{colors.on-cloth}"
    height: "4rem"
---

# Design System: Hamari Virasat

## Overview

**Creative North Star: "The Family Bahi-Khata"**

The whole product is the household's red cloth ledger, the one already opened and blessed at Diwali. Sindoor-red cloth is the ground of every screen, public site and Family Space alike; content sits on haldi-tinted paper leaves laid on that cloth. Leaves carry a red double margin rule down their left side, rows are ruled in faint blue, headings are set heavy in ink and red, and anything the family "wrote" (ritual names in an entry, who told it, when a step happens) is in handwriting. Haldi yellow is the one bright note, the string that ties the ledger shut.

The density is that of a ledger, not a brochure: one idea per region, tabular rows sharing a single ruling unit (2rem), big readable type for elders, and Devanagari set beside English as an equal, never as decoration. The public site opens on an open spread; the Family Space and operator console are the same ledger "in working order," with the cloth darkening to its night shade in the app bar.

The world explicitly refuses the old cream, maroon and gold heritage landing: no photo-beside-headline hero, no rows of feature cards, no glass, no decorative gradients, no icon tiles.

**Key Characteristics:**
- Red cloth ground everywhere; paper leaves are the only content surface.
- Red double margin rule and blue row rules are structure, drawn by the rows themselves.
- Four type voices with fixed jobs: Martel (Latin display), Rozha One (Devanagari display), Mukta (everything working), Kalam (only what the family wrote).
- Haldi is the single accent, reserved for the primary call on cloth, focus, selection and Devanagari on cloth.
- Status is a rubber stamp, not a pill or a badge.
- One ruling unit (2rem) sets row heights, label line-heights and section gaps inside leaves.

## Colors

A committed two-material palette: saturated red cloth and warm haldi paper, with ink, ruling colours and one string of yellow.

### Primary
- **Sindoor Cloth** (cloth): the ground of every page body, the site header, primary buttons, book tabs at rest, the selected segment, the count marker, Devanagari ritual names on paper, and the text-cursor colour.
- **Cloth in Shadow** (cloth-deep): headings on paper (H1, H2, page and panel titles, prices), the cloth band behind the privacy section, the hover state of cloth buttons, and inactive Family Space tabs.
- **Cloth at Night** (cloth-night): the footer and the Family Space / operator app bar; the darkest fold of the binding.
- **Cloth Text** (on-cloth) and **Soft Cloth Text** (on-cloth-soft): all text set directly on cloth; soft for secondary lines, captions, legal and greeting text.

### Secondary
- **Haldi String** (haldi): the single accent. The primary call in the cloth header (where a cloth button would disappear), the invite-code chip, Devanagari brand line and rule headings on cloth, focus rings and text selection.
- **Deep Haldi** (haldi-deep): the diya flame and the focused input's border.

### Tertiary (ledger inks)
- **Margin Red** (rule-red): the red margin rules, table header rules, entry-list top rules, and small uppercase column labels.
- **Line Blue** (rule-blue): the faint row rule under every ledger row.
- **Blue Ink** (blue-ink): "told by", relations and provenance lines; the ballpoint-blue of a hand entry.
- **Ochre Ink** (ochre-ink): draft / being-written status.
- **Leaf Green** (leaf): recorded / done status, ticks, guarantee and privacy-check marks.
- **Danger Ink** (danger-ink) on **Error Wash** (error-wash): destructive actions and error messages only.

### Neutral
- **Ledger Paper** (paper): the leaf surface; also the selected tab, so the tab reads as the page it opens.
- **Fresh Paper** (paper-light): inputs, tick boxes, starter chips, segmented control at rest, and the light band.
- **Paper Edge** (paper-edge): input outlines, the centre fold of a spread, dashed separators, and list rules on light bands.
- **Ink** (ink), **Soft Ink** (ink-soft), **Faint Ink** (ink-faint): body text, secondary text, and meta / hint text on paper.

### Named Rules
**The Cloth Ground Rule.** Every page's body background is cloth. Paper is laid on cloth as a leaf or a band; paper is never the page itself with red as a trim.

**The One String Rule.** Haldi is the only bright accent. It marks the one primary action on a surface, focus, selection and Devanagari on cloth. It never fills a band, a card or a heading on paper.

**The Ink Has Meaning Rule.** Blue ink means someone told it, ochre means still being written, green means recorded, red means ruling or structure. Do not use these inks decoratively.

## Typography

**Display Font:** Martel 800 (with Rozha One, Georgia)
**Devanagari Display:** Rozha One 400 (with Martel)
**Body / UI Font:** Mukta 400 to 700 (with system-ui)
**Handwriting:** Kalam 400 / 700 (with Mukta)

**Character:** A heavy, ink-dark Devanagari-aware serif for what the ledger declares, a plain friendly Indian sans for what you operate, and a ballpoint hand for what the family wrote in.

### Hierarchy
- **Display** (800, clamp 2.2 to 3.3rem, 1.08): the hero H1 on the opening leaf, in cloth-deep. One per page.
- **Headline** (800, clamp 2 to 2.9rem, 1.15): band headings (H2), centred over a band, max 40rem wide.
- **Title** (800, clamp 1.5 to 1.9rem; up to 2.4rem for a ritual page or detail title): panel and page titles on a leaf.
- **Entry** (Martel 800, 1.25rem): the ritual name in each ledger row of the Family Space.
- **Devanagari** (Rozha One 400, letter-spacing 0, about 1.2rem in rows, 0.85em when paired inside a Latin heading): the Hindi name of every cultural term, set beside the English, coloured cloth on paper and haldi on cloth.
- **Body** (Mukta 400, 1.125rem, 1.6): all prose; lede lines step up to 1.2rem; prose measures cap around 32 to 40rem.
- **Label** (Mukta 700, 0.85rem, 0.04 to 0.06em, uppercase, rule-red): ledger column headers and leaf section headings (Vidhi, Samagri); always the heading of the rows below it, never a line above a bigger heading.
- **Hand** (Kalam, about 1.05 to 1.1rem; 700 for step time bands): entries, told-by, step timing, status words in the example index, provenance.

### Named Rules
**The Written-In Rule.** Kalam appears only for what a family member would have written by hand: entry names in the example index, told by, time-of-day bands, status words, provenance. Never for headings, buttons, labels or prose.

**The Two Scripts Rule.** Devanagari is set in Rozha One with zero tracking, beside its English, never transliterated in its place and never as faint ornament. Uppercase and tracking apply to Latin only (`text-transform: none` on Devanagari inside labels).

**The Elder Floor Rule.** Body text is never below 1.125rem; secondary text not below about 0.95rem; only stamps and column labels go smaller (0.8 to 0.85rem), and they are always bold.

## Layout

A centred container (max 1200px) with a fluid gutter (clamp 1 to 2.5rem). The public page is a vertical stack of full-bleed bands, each padded by the band rhythm (clamp 4 to 6.5rem): cloth hero spread, light-paper example book, cloth-deep privacy rules, paper elders, light-paper pricing, cloth-night footer.

Inside a leaf, everything keys off the ruling unit (line, 2rem): table rows are one or two lines tall, labels are one line high, section gaps are one to one-and-a-half lines. The leaf's left padding clears the margin column (2.75rem plus 1.5rem) so text always starts right of the red rules.

**Signature compositions:**
- **The spread**: two leaves side by side with a centre fold (1px paper-edge with a soft shadow either side). Left leaf holds the H1, one line, a single-field form and the price line; right leaf holds the example index table.
- **The book with thumb tabs**: a leaf page with a column of cloth thumb-index tabs sticking out of its right edge (13rem). Choosing a tab turns the page.
- **The hisaab sheet**: pricing as a two-column account with a red vertical rule before the amounts column.
- **Family Space**: cloth field, family name in on-cloth display over it, folder tabs that sit on top of the leaf (negative margin), then one leaf per tab.

**Responsive:** at 960px the site nav collapses into a toggle menu and pricing stacks; at 860px spreads, books, privacy rules and elders stack to one column (book tabs become a horizontal scrolling row of folder tabs on top of the page); at 720px form rows and member rows stack and the accounts table becomes cards; at 560px the margin column narrows (2.25rem padding, rules shifted), the hero form stacks with a full-width button, and the tithi column hides.

## Elevation & Depth

Depth is physical and low: paper lies on cloth. Leaves cast one soft, cloth-tinted shadow (shadow-leaf); there are no layered elevations, no floating cards and no glass. Buttons on cloth carry a small soft drop so they read as pressed into the binding. Motion supplies the remaining depth: the page-turn and the thumb tabs.

### Shadow Vocabulary
- **Leaf** (`0 1px 2px rgba(31,26,22,0.12), 0 18px 40px -12px rgba(74,11,15,0.35)`): every paper leaf on cloth.
- **Fold** (`-6px 0 10px -4px` / `6px 0 10px -4px rgba(74,11,15,0.18)`): the centre fold of a spread.
- **Cloth button** (`0 2px 6px -2px rgba(74,11,15,0.5)`) and **haldi button** (`0 2px 8px -2px rgba(0,0,0,0.35)`).
- **Selected tab** (`4px 6px 14px -8px rgba(74,11,15,0.35)`): the thumb tab pulled out to the page.
- **Photograph** (`0 24px 50px -20px rgba(74,11,15,0.55)`): the single printed-book photograph.

### Named Rules
**The Paper-On-Cloth Rule.** The only elevated surface is a paper leaf. Nothing floats above a leaf except a selected tab joining it.

## Shapes

Paper corners are only just softened: leaves, tabs and the photograph use a 6px corner, controls (buttons, inputs, chips, segmented control) 4px, stamps and tick boxes 3px. Edges that touch something are squared: the two halves of a spread square off at the fold, a folder tab squares its bottom edge into the leaf, and the leaf squares the corner a tab joins. Inputs are open at the bottom: rounded top corners, square bottom, with a heavier 2px ink underline, as if written on a line. Borders are drawn rules (1 to 1.5px) in red, blue or paper-edge, solid for structure and dashed for "fill in here" (the own-ritual starter, form sub-sections, the demo footer).

The red margin rule is drawn with hard-stop `linear-gradient` stops on the leaf background; this is ruling, not a gradient.

## Components

### Buttons
Firm, legible and few.
- **Shape:** 4px corners, minimum 3rem tall (2.5rem for small and quiet), Mukta 700 at 1.05rem, optional trailing 18px icon.
- **Cloth (primary):** cloth with on-cloth text, darkens to cloth-deep on hover. The default primary on paper.
- **Haldi:** haldi with ink text, lightening on hover. The primary on cloth, where a cloth button would vanish.
- **Line:** 1.5px current-colour outline, ink text, faint ink wash on hover. Secondary actions.
- **Quiet:** underlined cloth text link styled as a button; underline thickens on hover. Back links, inline "add" and tertiary actions; with danger-ink for delete.
- **States:** press nudges down 1px; disabled is 55% opacity with a not-allowed cursor; focus is the global 3px haldi outline at 2px offset.

### Stamps (status)
A rubber stamp on the entry: 1.5px current-colour border, 3px corners, Mukta 700 0.8rem uppercase, transparent fill. Green for recorded, ochre for draft. The "Example" stamp marks all sample-family content.

### Leaves (containers)
- **Corner Style:** 6px, squared where they meet a fold or tab.
- **Background:** paper, with the red double margin rule at 2.75rem.
- **Shadow Strategy:** the single leaf shadow.
- **Internal Padding:** one line top and bottom; fluid inline; left clears the margin column.

### Inputs / Fields
- **Style:** fresh-paper fill, 1.5px paper-edge outline, 2px faint-ink underline, rounded top only, 3rem minimum, 1.1rem text. Label above in Mukta 600 soft ink; hint below in faint ink.
- **Focus:** fill brightens, outline turns deep haldi, underline turns cloth, with a 3px haldi glow.
- **Error:** a block message on error-wash with danger-ink text and a 4px corner.
- **Invite / code input:** uppercase, tracked 0.08em, tabular figures.

### Ledger rows (tables and lists)
Every list of records is a ruled ledger: a 1.5px rule-red line on top, a rule-blue line under each row, uppercase rule-red column labels. Rows are at least two lines tall in the example index and 4rem in the Family Space, with a faint haldi wash on hover. Applies to the example index, ritual entries, members, the hisaab and the operator accounts table.

### Navigation
- **Site header:** sticky, cloth, 4.5rem, diya mark plus "Hamari Virasat" in Martel over the Devanagari name in haldi; centre links in on-cloth Mukta 500 with a faint paper wash on hover; collapses to a toggle menu under 960px.
- **App bar:** cloth-night, 4rem, brand plus a section label after a thin cloth-line divider; sign-out on the right.
- **Tabs:** cloth-deep folder tabs on cloth; the selected tab turns paper and joins the leaf.
- **Segmented control:** cloth outline, fresh-paper segments, the selected segment filled cloth.

### Thumb-Index Tabs and the Page Turn (signature)
Cloth tabs (Devanagari in haldi over English) stick out from the right edge of the example book, offset by 0.4rem and sliding flush on hover. The selected tab turns paper with ink text and pulls out further. Selecting one replays the page-turn: a 7-degree Y rotation from the spine that settles over 0.6s on the ease-out curve. Under 860px they become a horizontal row of folder tabs on top of the page with no slide.

### Starter chips and samagri ticks
Starter chips are fresh-paper with a paper-edge outline and a Devanagari name in cloth; "your own" uses a dashed outline. Samagri items are full-width rows with a 1.4rem tick box; ticked items strike through in faint ink and the box turns green.

## Do's and Don'ts

### Do:
- **Do** put every surface on the cloth ground and every piece of content on a paper leaf or paper band.
- **Do** rule lists and tables with a red top rule and blue row rules; size rows in multiples of the 2rem line.
- **Do** set every cultural term in Devanagari (Rozha One) beside its English.
- **Do** keep haldi to the one primary action on cloth, focus, selection and Devanagari on cloth.
- **Do** show status as a stamp, and label all sample-family content with the Example stamp.
- **Do** keep targets at 2.75 to 3rem and body text at 1.125rem or larger for elders.

### Don't:
- **Don't** return to the cream, maroon and gold heritage landing: no photo-beside-headline hero, no rows of feature cards.
- **Don't** use glass, blur, or colour gradients; gradient syntax is allowed only to draw hard-stop ruling.
- **Don't** put icons in tinted tiles or circles; icons sit bare, in cloth or leaf colour, beside their text.
- **Don't** use Kalam for anything the family did not write.
- **Don't** add a second accent colour or use the ledger inks (blue, ochre, green, red) as decoration.
- **Don't** float cards above leaves or stack shadows; the leaf is the only elevated surface.

## Text-safe variants

Two tokens exist so the ledger colours pass 4.5:1 when they are text, not lines:

- `--rule-red-ink` (#a3302a): margin red for labels, column heads and step numbers. `--rule-red` stays for rules and borders.
- `--haldi-on-cloth` (#f2c867): haldi for text on the cloth. `--haldi` stays for buttons, the invite chip and selection.
