# ColorBalance — UI design specification

Version 1 · October 26, 2026 · Design proposal for review

## Direction

**A quiet studio for exploring color.** Mobile-first, responsive on desktop. Minimalist editorial composition: generous whitespace, neutral gallery surfaces, crisp type, and controlled blue actions. Room images and extracted palettes provide the visual personality. Avoid colored glass panels behind images, decorative gradients and saturated backgrounds that compete with judging color.

The bracketed styles and colors in the brief were examples, not chosen requirements. This direction is a design assumption. It preserves the agreed save/group/name flow; it does not introduce accounts, collaboration or recoloring.

## Design tokens

| Role | Token | Usage |
|---|---|---|
| Canvas | #F7F7F5 | App background |
| Surface | #FFFFFF | Image mat, cards, sheets |
| Ink | #202124 | Headings, primary text |
| Secondary ink | #595959 | Instructions, counts, metadata |
| Action | #244AB8 | Primary buttons, focus, selection |
| Action hover | #19398E | Hover on primary controls |
| Selected surface | #EEF2FF | Selected palette row |
| Control border | #757575 | Inputs, secondary controls, visible boundaries |
| Decorative divider | #D8D8D4 | Nonessential separators only |
| Error ink | #A12828 | Errors on white |

Typography: Inter if bundled locally, with ui-sans-serif/system-ui fallback. Code uses the Tailwind sans stack, requiring no font download. Titles 36/40 mobile, up to 60/64 desktop on Home only; screen headings 30–36; sheet headings 24; body 16/24; secondary labels 14/20; editorial eyebrow 12/18. Use sentence case, normal letter spacing for reading, tabular numerals for percentages. No truncation of entered names in dialogs; wrap names in cards and project rows.

Spacing: 4/8/12/16/24/32/48/64. Screen padding 16 mobile, 32 desktop. Cards radius 16–24; controls 12; sheets 24. Avoid excessive shadows: use one shadow only for overlays.

## Responsive layout

- 320–639 CSS px: one content column; photo actions stack, image precedes palette; full-width bottom sheet. Safe-area padding must be applied by the host shell.
- 640–1023: photo actions side by side; saved cards in two columns; centered sheets up to 480 px.
- 1024+: centered max-width 1152 px; Home in two columns; result uses roughly 62% image / 38% palette; saved cards in three columns. Desktop gets more space, not more features.
- Result image uses contain/aspect-ratio sizing. Never crop away analyzed pixels. Browser thumbnails may crop, but the full analysis preserves the source view.
- Content grows vertically. Avoid fixed-height text boxes. Sheets max 90dvh; project results max 35dvh, scroll independently. Title, search and action footer remain outside the project list. Entire sheet can scroll at high zoom or with the keyboard open.
- Selection action bar stays in normal document flow in this implementation, avoiding obscured focus. A future sticky version needs matching bottom padding and keyboard testing.

## Page and sheet layouts

| Screen | Structure and emphasis | Navigation / preservation |
|---|---|---|
| 01 Home | Brand; editorial headline; concise value statement; two large Take Photo / Choose from Library controls; secondary Explore Saved Analyses. Desktop room illustration at right; on mobile below actions. | No setup first. Photo acquisition cancellation returns Home. No direct project entry here. |
| 02 New result | Back + Save toolbar; heading; full room; palette rows with swatch, identifier, hex, percentage and selected mark. | Save opens 03. Back asks before discarding unsaved analysis. Tap color toggles highlight without editing analysis. |
| 03 Save | Sheet title; analysis-name input with default; Save as Separate Analysis primary; Save to Project secondary. | Cancel closes without losing analysis; draft naming is discarded. Save opens saved result. Project action opens 13 preserving name. No inline project list. |
| 04 Saved browser | Home; heading; All Analyses / Projects view buttons; named thumbnail cards with project context; Select. | All Analyses includes grouped and standalone work. Opening preserves browser scroll for return. |
| 05 Selection | Same cards; selected checkmarks plus selected count; Cancel; Add to Project action. | Toggle selection. Zero selection disables add. Cancel clears selection only. |
| 06 Bulk picker | Selected count; search; bounded scroll list; Create New Project below list. | Destination commits grouping and returns browser. Cancel preserves selection. Create opens 07. |
| 07 Create project | Name field; Create & Add with selection count. | Keep selected analyses and draft name when returning to 06. Validate blank name inline. |
| 08 Saved result | Same image and palette; Back; Add to Project; compact Rename action. | No Save. Returns to originating browser/project. After first save, Back goes Home. |
| 09 Quick picker | Same shared project picker, one analysis context; existing projects only. | Cancel leaves membership unchanged. Successful add stays on the analysis with highlight state preserved. |
| 10 Projects view | Inside Saved Analyses; same view controls; project cards show name and analysis count. | Open project; switch back to All Analyses. |
| 11 Project contents | Project heading; Back to Projects; analysis cards. | Open saved result; returning restores the project context. |
| 12 Rename | Small sheet; current name; Rename; Cancel. | Cancel discards edited name. Success updates card and result title, not photo filename. |
| 13 Save picker | Analysis-name context; search; scroll list; Back to Save. | Back retains name. Destination commits save. No project required to save independently. |

**Small design recommendation:** because Rename is currently the only menu command, the React draft exposes a compact labeled Rename button instead of a one-item overflow menu. This saves a tap without adding a capability. If visual review prefers the earlier menu, restore it using the same rename sheet.

## Component checklist

- [x] App shell, responsive content container, skip link, page heading
- [x] Primary / secondary / disabled / focus button styles; 48 px minimum control height
- [x] Two prominent photo-entry actions
- [x] Image stage and palette row, non-color-only selected state
- [x] Analysis card with title and project context
- [x] All Analyses / Projects view selector using native buttons and aria-pressed
- [x] Project card with count
- [x] Selection mode, selected count, zero-selection disabled action
- [x] Shared modal shell using native dialog; Escape handling and return focus
- [x] Shared searchable, scrollable project picker
- [x] Analysis naming, project naming and rename fields
- [x] Empty content and no-search-results copy
- [x] Loading / saving announcements, inline error and success status
- [x] Unsaved-discard confirmation
- [ ] Actual camera and photo-library adapters
- [ ] Actual color extraction, per-photo region masks and persisted storage
- [ ] Integration accessibility testing with keyboard, screen readers and device zoom

## Loading, empty and error behavior

| Situation | Behavior / copy | Recovery |
|---|---|---|
| Analysis loading | Keep source preview in production; “Finding the colors in your room…” with indeterminate activity, no fake percentage. Demo shows a simple status panel. | Cancel stops the operation; retain source for retry in production. Demo returns Home. |
| Saving / grouping / renaming | “Saving changes…”; disable submissions and cancellation once commit starts. | Announce successful persistence; never claim canceled after commit. |
| Empty saved browser | “Your first color story starts here.” | Photo entry action |
| Empty project | “This project is ready for ideas.” | Explore Saved Analyses |
| Empty project list | “No projects yet.” | Bulk picker offers Create New; saving still offers separate save. |
| No search results | “No matching projects.” | Clear Search; creation remains available in bulk flow |
| Analysis failure | “We couldn’t analyze this photo. Try again.” | Retry; preserve source in integrated app |
| Save/group failure | “That change could not be saved. Your input is still here.” | Retry without retyping or reselecting |
| Blank rename/project name | Field-specific inline instruction | Keep focus and input; no mutation |
| Camera denied | Explain why access is needed only after Take Photo | Choose from Library; platform Settings link where supported |
| Unreadable file | State supported file formats according to actual decoder | Choose Another; do not lose existing saved work |
| Partial bulk persistence | Prefer transactional commit; otherwise show actual completed and failed counts | Retry failed IDs only; idempotent membership writes |

## Accessibility target and verification

Target WCAG 2.2 AA. Full conformance is not established by this artifact; it requires testing the integrated product, its actual content, and native adapters.

Calculated contrast (sRGB WCAG formula):

| Pair | Ratio |
|---|---:|
| Ink #202124 on canvas #F7F7F5 | 15.01:1 |
| Secondary #595959 on canvas | 6.53:1 |
| White on blue #244AB8 | 7.65:1 |
| Control border #757575 on white | 4.61:1 |
| Blue focus indicator on white | 7.65:1 |
| Error #A12828 on white | 7.37:1 |

Normal text targets at least 4.5:1; large text at least 3:1; essential non-text control cues at least 3:1. Choose 48×48 CSS px controls, exceeding WCAG 2.2 AA's 24×24 minimum (with exceptions). Actual palette colors are data: surround swatches with visible borders and provide text identifiers/hex/percentages rather than requiring users to distinguish hues.

Implementation safeguards: native buttons, labeled inputs, aria-pressed selection, polite success announcements, alert errors, 3 px focus outline with 4 px offset, focus moved to page headings, native modal focus containment and Escape support. No animation is needed. Use real text, not text baked into imagery. Long titles wrap.

Acceptance checks before release: Tab/Shift+Tab through every flow; Escape restores context; no keyboard traps; visible focus remains unobscured; test at 320 CSS px and 200% text/400% zoom; VoiceOver/TalkBack names and statuses; all focus targets survive conditional view changes; test virtual keyboards and safe areas; inspect photo alt text and mask explanation. Automated checks alone cannot certify these.

Sources:
- https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
- https://www.w3.org/TR/WCAG22/

## Code and integration boundary

ColorBalanceUI.tsx exports one React component using Tailwind utilities. It is an interactive review demo, not a new production app. Illustrative room SVG and fixed percentages are labeled sample content in review controls; photo buttons run a simulated analysis. No files are uploaded. Session state supports standalone save, grouping ungrouped items, naming and renaming. Review controls can clear sample data and fail the next operation.

Use inside an existing React + TypeScript + Tailwind project. Import and render ColorBalanceUI. Ensure Tailwind scans this TSX file; include the generated CSS once in the host app. No icon or font dependency is required. Bundle Inter locally only if desired.

Integrate four boundaries: acquirePhoto(source), analyzePhoto(file, abortSignal), saveAnalysis(data), updateProjectMembership(ids, projectId). Preserve stable IDs and use cancellation tokens; commit notifications must follow durable storage. Replace Room with the full source image and its region masks. Keep processing and persistence local as required.

Unresolved product rule: one project per analysis vs multiple memberships. Demo conservatively blocks adding an already-grouped analysis to a different project; it never silently moves it. Decide this before production implementation. This does not block design review of ungrouped-item flows.

## Handoffs

Chief of Staff: visual UI draft, screen specifications, component checklist and React/Tailwind demo created. Design still under review; no production implementation or usability research claimed.

Product & Ideas: existing user-directed capabilities retained. Resolve project-membership cardinality. Compact Rename button is a UX recommendation replacing the previous one-item menu. No additional product scope approved here.

## Validation performed

- TypeScript typecheck passed with DOM types and React types.
- React bundle and Tailwind stylesheet built successfully; included together in ColorBalance_UI_Preview.html (no runtime CDN dependency).
- Token contrast ratios calculated as listed above.
- Browser interaction and visual checks were attempted but could not run because a Chromium binary was unavailable and its download was invalid. No claim of browser-tested behavior or full accessibility conformance is made.
- Open the HTML locally for review; code is also provided separately for integration. Review controls demonstrate empty and failure states. Actual device permissions, masks, persistence and screen-reader behavior still need integration testing.
