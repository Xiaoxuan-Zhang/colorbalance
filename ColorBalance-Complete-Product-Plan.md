# ColorBalance — Complete Product Plan

Version 0.2 • October 8, 2026 • Product & Ideas

Combined product vision, strategy, competitive analysis, roadmap, PRD, epics and user stories, decision log, and research/release plan. Implementation and user validation remain unverified.


---

## ColorBalance product management pack
Version 0.2 • October 8, 2026 (America/Los_Angeles) • Owner: Product & Ideas
Status: planning baseline; implementation and user validation unverified.

### Purpose and use
Practice the complete product workflow while keeping one small iOS release practical at four hours per week. These documents are working specifications, not proof of shipped features or demand.

| Document | Purpose | Update trigger |
|---|---|---|
| 01 Product Vision | User, problem, promise, outcomes | Target problem changes |
| 02 Product Strategy | Positioning, bets, business and validation choices | Evidence changes a bet |
| 03 Competitive Analysis | Source-backed comparison and gaps | Material competitor change |
| 04 Product Roadmap | Product gates and next work | Gate result or capacity change |
| 05 PRD | Release behavior and acceptance | Scope or behavior changes |
| 06 Epics and User Stories | Executable backlog tied to requirements | Implementation/test evidence |
| 07 Decision Log | Decisions, rationale, alternatives, open questions | Material choice |
| 08 Research and Release Plan | Experiments, measurements, release checks | Test or release result |

Read vision → strategy → evidence → roadmap → PRD → backlog. Record a choice in the decision log, implement a story, test its acceptance criteria, and attach evidence before marking it done. Keep wording consistent across affected documents.

### Evidence labels
User decision = explicit instruction. Recommendation = PM judgment awaiting acceptance where material. Hypothesis = unvalidated belief. Historical context = reported earlier work, not freshly verified. Verified source = current public documentation, with limitations recorded.

### Baseline
User chose a small first launch and added local organization of photos and resulting palette reports. PM proposes a single-level Project container rather than separate projects plus nested folders. Pricing is undecided. Existing Flutter/Rust/Python work has not been inspected here. No customer interviews, usability tests, iOS build, or feature completion are claimed.

Later user instructions supersede older project-plan assumptions about mandatory 60–30–10 scoring, camera capture, and excluding project management. The master plan remains owned by Chief of Staff and was not edited.

### Maintenance rule
Use stable IDs across documents. No weekly document refresh for its own sake; update only when behavior, evidence, or a decision changes. No launch date until the technical baseline and remaining effort are known.


---

## ColorBalance — Product vision
Version 0.2 • October 8, 2026 • Planning baseline

### Vision
Help people understand and revisit the colors in their rooms through a private, approachable photo-based tool.

### Target user and job
Primary hypothesis: DIY home decorators using an iPhone, considering changes to one room, who have several room photos and want to understand the current palette.
Job: “When I am considering changes to a room, help me see which colors dominate, where they appear, and keep the analysis with my room photos so I can review it later.”

Secondary possibilities—design students, hobbyists, professional decorators—remain outside initial targeting until evidence supports them.

### Problem
A list of sampled colors does not explain how much of the photographed scene each group occupies or where that group appears. Scattered screenshots and photos also make past analysis difficult to find. These are problem hypotheses; no customer research has confirmed frequency or severity.

### Promise
Import a room photo, inspect approximate visible-image color percentages, save the photo and interactive report to a local Project, and export a readable result.

Percentages describe grouped pixels in the analyzed photo, not physical surface area, paint quantities, object identity, or design quality. Lighting, framing, reflections, and shadows affect results.

### Principles
- Photos are processed on device; no account or app-operated cloud storage.
- Complete one understandable workflow before expanding.
- Retain saved results so reopening does not silently change a report.
- Make deletion and storage limitations understandable.
- Treat 60–30–10 as optional educational context, never a universal score.

### Outcomes
Founder outcome: publish a functioning app and learn the release process; failure to attract users is acceptable when honestly recorded.
User outcome hypothesis: complete analysis, identify relevant regions, and retrieve a saved report without help.
Business outcome hypothesis: a low-maintenance utility may support a small one-time purchase. Profitability and willingness to pay are unvalidated.

### Boundaries
No AI redesign, recommendations, paint matching, shopping, cloud sync, shared projects, or Android launch in v1. Product & Ideas owns this product’s recommendations; Chief of Staff owns portfolio priorities and the master schedule.


---

## ColorBalance — Product strategy
Version 0.2 • October 8, 2026

### Choice
Continue a small launch experiment, using existing work where viable. Add local saved Projects because the user explicitly wants review and organization. Favor reliable retrieval over additional analysis features.

### Positioning hypothesis
For DIY decorators who want to understand existing room colors, ColorBalance is a private photo-analysis notebook that connects approximate color proportions to visible regions and saved room reports.

The combined workflow is a hypothesis, not a proven unique feature set. Palette extraction and organization already exist elsewhere (see competitive analysis).

### Strategic bets
| Bet | Evidence today | Cheap test | Response to failure |
|---|---|---|---|
| Region highlighting helps interpret results | Founder intent; no user evidence | Five users explain a selected group | Simplify presentation before adding features |
| Saved Projects support review | Explicit founder requirement | Users save then retrieve a report | Fix naming/navigation; avoid nested folders |
| Existing architecture is viable | Historical prototype only | CB-001 device build and one analysis | Timebox fix, then simplify architecture |
| A small paid utility can work | No payment evidence | After usability, ask about alternatives and price | Keep launch learning separate from revenue |

### Product choices
Recommended UI term: Projects. A Project behaves like a flat folder; there is no second hierarchy. Reports belong to exactly one Project or default Unsorted. One report contains one imported photo, its palette, percentages, and region mapping.

iOS first. No accounts, analytics SDK, ads, server processing, or subscriptions in the proposed v1. Collect early learning through voluntary feedback and observed sessions.

### Revenue
User rejected $12.99 for the small release. $2.99–$3.99 one-time unlock is a prior recommendation, not an approved price.
Recommendation: release initially free to reduce implementation burden; decide at release planning. If charging becomes part of v1, add purchase, restore, offline entitlement, and failure stories before locking scope. Never charge users to access already-saved data after entitlement errors.
No profit forecast: traffic, conversion, fees, support effort, and demand are unknown.

### Distribution
Start with five consenting DIY-decorator testers and an accurate App Store listing showing percentages, highlight, and saved Projects. Chief of Staff decides whether public project documentation supports discovery. Do not assume an audience or paid acquisition.

### Allocation and tradeoffs
At four hours/week, each feature must support import → analyze → inspect → save → reopen → export. More than eight estimated hours requires splitting or a written value test under the project plan. Local persistence adds reliability and storage work; it cannot be treated as a free UI addition.

### Continue/change/stop
Continue if the core pipeline works or a bounded fix is credible.
Simplify if architecture or folder complexity dominates remaining capacity.
Pause and hand off if no credible release fits available project capacity.
After launch, do not expand automatically; require evidence of a repeated user problem.


---

## ColorBalance — Competitive analysis
Version 0.2 • Research retrieved October 8–9, 2026 UTC

### Method and limits
Focused desk review of first-party product and help pages. No hands-on app testing, revenue data, comprehensive App Store census, or user reviews were analyzed. “Not established” is not “absent.” Exact current prices were not verified. Some Coolors pages returned 403; its official help page was accessible. Search-indexed older plan descriptions are insufficient for quoting current limits or prices.

### Comparison
| Alternative | Supported public evidence | Business model evidence | Unresolved comparison | Implication |
|---|---|---|---|---|
| Adobe Color / Express | Image extraction, editable swatches, HEX/RGB, saved libraries and broader design workflows [S1–S3] | Free palette tools; paid plan for automatic palette application in Express [S1,S2] | Per-image area percentages, cluster-region masks, fully local room archive not established | Extraction alone is weak differentiation |
| Coolors | Official help documents creating and managing palette projects/collections [S4] | Official indexed pages describe Pro subscription and ads [S5]; exact present terms unverified | Room-photo area reporting and local report reopening not established | Organization is already competitive, not a unique moat |
| Paletton | Browser-based color scheme designer with harmony controls [S6] | No revenue model established by reviewed page | Room analysis and persistence not established | Competes for palette exploration, less directly for room-photo interpretation |
| General AI assistants | Substitute hypothesis based on founder discussion; no controlled benchmark performed | No pricing comparison researched | Consistent percentages, masks, privacy and repeatable archive require testing | Test the workflow against actual alternatives before claiming advantage |
| Photos + screenshots | Practical substitute hypothesis; not a reviewed product claim | No incremental tool spend assumed, not verified | No automatic analysis | Saved reports must improve retrieval enough to matter |

### Findings
Verified: color extraction is available free; palette organization exists. Inference: a focused room-photo workflow could offer convenience, but no evidence establishes unmet demand or competitors’ inability to deliver it.
Do not advertise “first,” “unique,” or superior accuracy. Do not equate search omissions with competitive gaps.

### Opportunity hypotheses
1. Pair percentages with interactive regions so users understand what each group includes.
2. Reopen the same report with its photo and masks in a simple local room Project.
3. Make limitations and privacy clear without a subscription/account workflow.

None is validated. Local privacy requires implementation and SDK verification.

### Next bounded comparison
After CB-001, spend at most 45 minutes comparing the same three room photos with Adobe extraction and one accessible mobile competitor. Record output, steps, export, region inspection, account requirements, and offline behavior. Do not upload personal room photos to a service without the owner choosing to do so; use non-sensitive test images. Record unavailable features as unknown until actually tested.

### Sources
- [S1 Adobe image extraction](https://color.adobe.com/create/image)
- [S2 Adobe Color overview](https://color.adobe.com/)
- [S3 Adobe product description](https://www.adobe.com/products/color.html)
- [S4 Coolors official help: projects and collections](https://coolors-help.zendesk.com/hc/en-us/articles/360010537880-Create-and-manage-projects-and-collections)
- [S5 Coolors official generator, indexed plan description](https://coolors.co/000000-fffffc-beb7a4-087e8b-2081c3)
- [S6 Paletton](https://paletton.com/)


---

## ColorBalance — Product roadmap
Version 0.2 • October 8, 2026 • Recommendation, not master roadmap

### Product state
Active, release planning. Documentation prepared; technical readiness unknown. No implementation task is marked complete.
No calendar launch commitment. The existing plan allocates 72 hours to ColorBalance; remaining capacity and actual spent hours are unknown. Chief of Staff must reconcile scope against that allowance.

| Gate | Outcome | Required evidence | Action if failed |
|---|---|---|---|
| G0 Technical baseline | Existing app’s real state known | Device/build target, one import/analysis attempt, first blocker | Record blocker; bounded fix or simpler local path |
| G1 Complete workflow | Import, inspect, save, reopen, export | Demonstration and acceptance evidence for R1–R7 | Fix core omissions, avoid polish expansion |
| G2 Durable and understandable | Data survives restart; five-user test | Persistence tests and observations, R8–R10 | Repair data loss; address repeated confusion |
| G3 Submission ready | Production build and accurate disclosures | Release checklist, pricing decision, support/privacy links | Resolve submission blockers |
| G4 Launch learning | Submission outcome and feedback recorded | Actual acceptance/rejection, feedback and usage sources | Bounded fix, continue/pause decision |

### Now
CB-001: reproduce canonical Flutter app on intended iOS target (45–60 minutes).
Output: build status, working capabilities, first reproducible error, one next task.
If repository unavailable: locate canonical repo and branch (15 minutes); do not infer its state from history.

### Next, after G0
CB-002: walk through Project → photo → report → save → reopen screens (30 minutes).
CB-003: confirm durable report fields and save/reopen test (45–60 minutes).
CB-004: implement persistence as small slices: save one report; reopen; then container management.
Select actual implementation tasks from the backlog after evidence. Do not estimate an architecture rewrite before examining the code.

### Later
Complete export, storage/deletion recovery, accessibility, test sessions, production release preparation. Only after launch evaluate pricing, manual adjustments, comparisons, or Android from actual feedback.

### Capacity
One weekly outcome within four hours; retain project-level reserve. Implementation sessions should be 30–90 minutes. Project management is a material scope increase; estimate persistence and management after G0, then notify Chief of Staff of any schedule impact. This roadmap does not change portfolio order or master dates.

### Change control
User-approved needs enter PRD; PM design recommendations remain labeled. More than eight hours is split or justified. New feature requests go through problem → value → smallest slice → impact → decision log. Failed gates generate an explicit decision, never an automatic extension.


---

## ColorBalance — Product requirements document
Version 0.2 • October 8, 2026 • Draft implementation baseline
Owner: Product & Ideas • Release: iOS v1 • All behavior below is specified, not verified.

### Objective and scope
Deliver import → analyze → inspect → save to Project → reopen → export, entirely with on-device processing and app-local storage.
Local organization is a user requirement. A flat Project model and the detailed behavior below are PM recommendations.

### User flow and screens
Projects home lists named Projects and Unsorted. Project detail lists reports with photo thumbnails and titles, newest first. Report detail shows photo, palette, percentages and selectable highlight; actions save, move, rename, export, delete. Import is available from a Project or home.
Import from home defaults to Unsorted; users may choose/create a Project when saving. Existing report selection reopens its saved result without automatic reanalysis.

### Requirements and acceptance
| ID | Priority | Requirement | Observable acceptance |
|---|---|---|---|
| R1 | Must | Select one photo through system picker | JPEG/PNG/HEIC examples import with correct orientation; cancel leaves current data unchanged; unreadable image shows retry guidance |
| R2 | Must | Analyze dominant groups locally | Typically 3–6 groups; near-uniform image may yield fewer; percentages represent all analyzed pixels and total 100% after consistent display rounding; no photo upload |
| R3 | Must | Show understandable palette | Swatches, HEX and approximate percentages are readable; visible-image limitation is available; no universal design score |
| R4 | Must | Inspect color regions | Selecting a swatch highlights its corresponding saved mask; selecting again clears; other swatches replace selection; photo orientation/aspect aligns |
| R5 | Must | Save durable report | Successful save stores image copy, palette, fractions, masks and metadata; restart reopens same report; failure never shows saved success |
| R6 | Must | Organize Projects | Create/rename Project; move report between Project and Unsorted; rename report; blank names rejected after trim; duplicate names allowed, stable IDs distinguish items |
| R7 | Must | Export readable result | Share sheet receives image containing original analyzed photo, swatches, HEX, approximate percentages and report title; cancel preserves data; export excludes private path/location metadata |
| R8 | Must | Safe removal and storage failure | Confirm report deletion; Project deletion moves its reports to Unsorted and states this; low space causes recoverable save error; no half-saved report appears |
| R9 | Must | Offline, privacy and recoverability | After a selected photo is locally available, analyze/save/reopen/export preparation works in airplane mode; corrupt report shows recoverable error without affecting others |
| R10 | Must | Accessible and complete states | Loading/empty/error states; controls have meaningful screen-reader labels; selection has non-color cue; enlarged text stays usable on supported device sizes |
| R11 | Could, excluded by default | Explain 60–30–10 | Optional educational note only; no mandatory rule compliance or scoring |
| R12 | Deferred | In-app monetization | Requires separate scope decision and purchase/restore acceptance before implementation |

System photo retrieval can need network if the original is only in iCloud Photos; explain unavailable download rather than promising every import works offline. Export destination may be cloud-based at the user's choice.

### Numerical semantics
Percentages are cluster area divided by total analyzed image pixels. Retain small groups by assigning them to a remaining group rather than silently dropping pixels and implying full-photo coverage. Store raw fractions; round for display using a method that sums to 100.0% at one decimal. Synthetic color-block fixtures validate arithmetic; room photographs cannot establish physical-area accuracy. Algorithm and image size remain implementation choices after G0.
Do not promise semantic wall/furniture segmentation.

### Persistence contract
Project: stable ID, name, created/updated timestamps. Unsorted is reserved and cannot be renamed/deleted.
Report: stable ID, Project ID or Unsorted, title, timestamps, analysis version, image dimensions, image path, palette RGB/HEX, raw area fractions, and region labels/masks.
Own a normalized photo copy at the analysis resolution; disclose that it is not a full-resolution photo backup. Deleting the source in Photos must not break saved reports. Persist masks or an equivalent stable region map; do not recompute on open. Thumbnails and export temporaries are regenerable.
One photo/report, one container; no nesting, tags, batch import, search, version history, raw-photo archive, or side-by-side comparison in v1.

Writes must be atomic from the user's perspective; failed save leaves no visible record and cleans orphan temporary files. An update must preserve existing records and include a schema-version/migration plan before release. App uninstall can remove local app data; exported images remain in their chosen destination. Reports have no in-app recovery after confirmed deletion; confirmation must be explicit.

### Performance and scale: proposed targets
On the declared oldest supported test device: analyze a typical resized room photo within 5 seconds median across ten attempts; swatch change within 150 ms for most interactions; open saved report within 1 second for typical reports. These targets require measurement and may be revised with recorded evidence.
Test 100 saved reports across ten Projects without unbounded loading or visible UI stalls. No advertised numeric storage limit in v1; device storage constrains capacity. Thumbnail lists should not decode every full image at once.
Exact minimum iOS/device support remains open until G0.

### Apple storage and privacy considerations
Apple permits app-local data storage; follow app-container/file-location guidance [A1]. Use durable storage for irreplaceable user records and cache locations for regenerable thumbnails/temp exports. Ordinary device backup can include durable app data even without app cloud sync [A1,A2]. Recommendation: allow standard OS backup of user-created data; exclude regenerable assets where appropriate. Confirm this policy before privacy copy; do not claim “never leaves your phone.”
Use the system picker and minimum necessary access [A3]. Include accessible privacy policy in app and store metadata; disclosures must match the actual app and SDK behavior [A3]. Local storage does not guarantee App Review approval; adequate utility and completeness still matter.

### Release blockers
Data loss, broken restart retrieval, crashes in normal flow, mask misalignment, incorrect percentage accounting, photo transmission contradicting claims, broken export, inaccessible core controls, missing privacy/support material. All must be resolved before submission.

### Dependencies and open issues
Canonical repo/build target, viable Rust integration, baseline performance, actual package licenses and SDK network behavior, backup policy, pricing, supported iOS devices. No dependencies are claimed resolved.

### Official references
[A1 Using the file system effectively](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively)
[A2 Optimizing data for iCloud Backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
[A3 App Review Guidelines, 4.2 and 5.1.1](https://developer.apple.com/app-store/review/guidelines/)


---

## ColorBalance — Epics and user stories
Version 0.2 • October 8, 2026
All stories: Planned / not verified. Must stories define release scope. Effort is intentionally unestimated until CB-001; split implementation into 30–90-minute sessions.

| Epic | User outcome | Stories | PRD |
|---|---|---|---|
| E1 Photo analysis | Understand a room photo | US01–03 | R1–R3 |
| E2 Inspection | See which pixels a color group covers | US04 | R4 |
| E3 Saved Projects | Keep and retrieve results | US05–09 | R5,R6 |
| E4 Export and removal | Share results and control stored data | US10–12 | R7,R8 |
| E5 Reliable release | Trust normal use and limitations | US13–16 | R9,R10 |

### Story acceptance
US01 — As a decorator, I select a room photo so I can analyze it.
Given a supported locally available photo, when imported, then its orientation is correct and analysis can start. Cancel preserves prior state; unreadable/cloud-unavailable photo has recovery guidance. Dependency: CB-001.

US02 — As a decorator, I see color proportions so I can identify dominant groups.
Given a color-block fixture, when analyzed, then every pixel contributes to one group and fractions total one; display totals 100.0%. Near-uniform image may use fewer groups. Dependencies: US01, viable analyzer.

US03 — As a decorator, I understand the result’s limits so I avoid mistaking it for physical measurements.
Given a result, then HEX and approximate visible-image percentages are displayed with accessible explanatory copy; no quality score. Dependency: US02.

US04 — As a decorator, I select a swatch so I can inspect corresponding regions.
Given a result, selection aligns mask with photo; another swatch replaces selection; repeat tap clears it. Verify rotation and resized photos. Dependency: US02.

US05 — As a decorator, I save a report so I can return to it.
Given a completed analysis, save commits an owned image, metadata, palette and masks; restart reopens without recalculation. Low space produces failure without a phantom saved record. Dependencies: US02,US04.

US06 — As a decorator, I create and rename Projects so results reflect my rooms.
Given a trimmed nonblank name, create/rename succeeds; blank rejected; cancel has no effect. Unsorted remains available and reserved. Can implement shell before US05.

US07 — As a decorator, I save to or move between Projects so I can organize reports.
Given a saved report, move changes its container exactly once; canceled move preserves original; no duplicate report created. Dependencies: US05,US06.

US08 — As a decorator, I reopen a report so I can review the same analysis.
Given a saved report and deleted original Photos item, then stored photo/palette/highlight still work after app restart. Corrupt record does not prevent opening another. Dependencies: US05,US07.

US09 — As a decorator, I name reports so I can recognize different views.
Given a report, nonblank rename persists after restart; thumbnails/titles list newest first; duplicate names do not overwrite. Dependency: US05.

US10 — As a decorator, I export a report so I can share a readable image.
Given a result, share image has photo/title/swatches/HEX/percentages and no location metadata; cancel changes no record. System destination governs subsequent sharing. Dependencies: US03,US05.

US11 — As a decorator, I delete a report so I control stored data.
Given confirmation, report-owned assets are removed; cancel preserves them; source Photos asset and other reports remain. Dependency: US05.

US12 — As a decorator, I remove a Project without losing its reports.
Given confirmation explaining the move, delete Project sends reports to Unsorted; cancel changes nothing. Dependencies: US06,US07.

US13 — As a privacy-conscious user, I use saved content offline.
Given locally available input and airplane mode, analyze/save/reopen/export preparation succeeds; network inspection and SDK audit support no-upload claims. Dependencies: US01–10.

US14 — As a user with accessibility needs, I complete the main flow.
Given VoiceOver and enlarged text, controls have useful labels, selection is announced and not indicated only by color, and main flow remains usable. Cross-cutting, not end-stage polish.

US15 — As a user, I recover from failures without losing existing reports.
Given interruption, full storage, invalid input or corrupt report, then clear error/retry is offered; restart preserves earlier valid saves. Dependencies: persistence and analyzer.

US16 — As a user, I know what local saving means.
Given settings/help, then policy, deletion consequences, backup caveat and support link are accessible. No account or implied cloud sync. Dependency: resolved backup decision.

### Definition of ready
Story has linked requirement, observable acceptance, bounded implementation slice, and known dependency. Decide technical approach using repository evidence.

### Definition of done
Implementation exists; acceptance is exercised on declared target; evidence and limitations recorded; no unresolved release-blocking defect. Planned documentation does not mark stories done.

### Backlog hygiene
Record status, actual estimate, evidence and blocker when work begins. Deferred: nested folders, tags/search, batch analysis, manual editing, AI redesign, Android and payment flow unless separately approved.


---

## ColorBalance — Decision log
Version 0.2 • Recorded October 8, 2026
Historical decisions are sourced from supplied conversation context; exact earlier dates are not invented.

| ID | Status / owner | Choice and rationale | Alternatives / consequences | Revisit trigger |
|---|---|---|---|---|
| D01 | User decision | Small first release to publish and learn; failure acceptable | Extensive validation deferred; demand remains unknown | Launch feedback |
| D02 | User decision | Local organization for photos and reports; no app cloud storage v1 | Scope increases beyond prior “no projects” boundary | Persistence effort evidence |
| D03 | PM recommendation | One-level Projects plus Unsorted | Separate projects/folders or nesting adds navigation/data complexity | Repeated tester need |
| D04 | User decision | $12.99 unsuitable for small initial app | Lower unlock suggested, price still open | Release pricing decision |
| D05 | PM recommendation | Free first release, monetization later | $2.99–$3.99 one-time unlock requires purchase/restore scope | Before G3 |
| D06 | Current inherited direction / PM baseline | iOS first, no AI redesign/shopping/paint catalogs | Android and recommendations deferred | After launch evidence |
| D07 | PM recommendation | Percentages describe all analyzed image pixels; no 60–30–10 grade | Universal design score would overstate meaning | New educational need |
| D08 | PM recommendation | Owned analysis-resolution photo copy and stable saved mask | Original Photos reference risks breakage; full originals consume more storage | Device/storage tests |
| D09 | PM recommendation | Deleting Project moves reports to Unsorted | Cascade deletion risks accidental loss; destructive option deferred | Observed confusion |
| D10 | Open | Standard OS backup permitted for durable user data; no app sync | Absolute device-only promise requires separate policy/engineering review | Before privacy copy |
| D11 | Required next gate | Inspect existing implementation before re-estimating or rewriting | Historical work does not establish current readiness | CB-001 result |
| D12 | User instruction | Document full PM flow as practice, scaled to small app | One compact linked pack; maintain only on meaningful change | Process overhead becomes excessive |

### Open questions, owners and deadlines
- Canonical repo/branch and iOS device: founder, at G0.
- Pipeline build/runtime status and supported devices: implementation, G0.
- Project terminology: proposed default; confirm through review or usability, before final UI.
- Storage schema and migrations: implementation, before G1.
- Backup/privacy wording: PM and implementation verify platform behavior; Legal & Finance handles legal conclusions, before G3.
- Free vs paid launch: founder with PM recommendation, before G3.
- Actual remaining capacity and portfolio implications: Chief of Staff after G0 estimation.

### Adding a decision
Record date, status, owner, evidence, choice, rationale, rejected alternatives, consequence, linked requirements and revisit trigger. Mark superseded decisions; do not erase history. No recommendation is silently promoted to user approval.


---

## ColorBalance — Research and release plan
Version 0.2 • October 8, 2026
All experiments/checks below are planned. No results or participants are claimed.

### Experiment sequence
| Experiment | Question / method | Proposed criterion | Decision |
|---|---|---|---|
| X1 Baseline | Build intended iOS target, import and analyze one photo | Pipeline works or first blocker is reproducible | Continue / bounded fix / simplify |
| X2 Analysis sanity | Synthetic blocks plus 10 varied room images: neutral, dark, colorful, reflective, near-uniform | Pixel accounting correct; masks align; outputs interpretable with limitations | Fix arithmetic/alignment before usability |
| X3 Durability | Save, restart, remove source Photos item, move, cancel/delete, simulate storage failure and app update | No loss of valid saves; errors isolate affected report | Any data loss blocks release |
| X4 Usability | Five first-time target users; observe import, select, save to Project, reopen and export | At least 4/5 complete unaided and explain visible-image meaning | Below threshold: fix repeated confusion and retest affected flow |
| X5 Value | Ask what result helped, what they would use instead, whether they actually reopened later | Record concrete use and substitute; no demand threshold for first learning launch | Repeated value may justify improvement |
| X6 Payment, later | Discuss actual alternatives, purchase intent and price; optionally test paid release | Statements are weak evidence; actual purchases stronger | Do not infer profitability from five interviews |

Recruitment and sessions are tasks, not automated outreach. Use participant consent and non-sensitive photos where possible. Record anonymous participant codes, completion, intervention, time, interpretation, specific benefit, confusion and follow-up. No need for behavioral analytics SDK in v1.

### Measurement
Founder launch success: actual accepted App Store release, with submission outcome and learning recorded. A deliberate evidence-based stop is a valid project outcome but is not a successful publish.
Usability: successful unaided completion / participants; report counts with denominator.
Reliability: passing persistence/error scenarios / executed scenarios; list failures.
Post-launch: available App Store Connect downloads and reviews, voluntary feedback, support issues and actual revenue if charged. Do not report retention without a measurement source.

### Release checks
- [ ] G0 implementation evidence recorded and support devices declared.
- [ ] R1–R10 acceptance exercised; no unresolved release blockers.
- [ ] Synthetic fraction tests and representative room-photo results reviewed.
- [ ] Restart, interruption, deletion, storage failure and update persistence tested.
- [ ] Airplane-mode workflow and actual SDK/network behavior reviewed.
- [ ] Five-user observations recorded, or deviation explicitly decided and logged.
- [ ] Production build, package/asset licenses and supported OS checks complete.
- [ ] Pricing selected; if paid, purchase/restore/failure checks added and passed.
- [ ] App name availability, description/screenshots and age-rating answers verified.
- [ ] Privacy policy accessible in-app and store; disclosures reflect actual SDKs.
- [ ] Support URL/contact, review notes and export limitations complete.
- [ ] Submission outcome recorded; no approval guarantee.

Apple allows app-local storage within its platform model. Its guidance addresses correct durable/cache locations and backup treatment. A local app need not implement cloud sync, but device backups and user-chosen export destinations complicate an absolute “phone only” promise. Use verified implementation wording. Sources: PRD A1–A3.

### Stop / scope criteria
A normal-use crash or data-loss defect blocks submission. If one 60–90-minute fix attempt cannot bound the architecture blocker, write a simplified-path comparison; do not start an indefinite rewrite. If remaining work does not fit capacity, Chief of Staff reviews schedule/portfolio impact. After launch, a quiet app is learning evidence, not a reason to add every requested feature.

### Handoff to Chief of Staff
Product/state: ColorBalance active, release planning.
Evidence/decision: full product pack prepared; user requested local photo/report organization. Flat Projects is a PM recommendation. No app build, implementation or customer validation newly verified.
Blocker: canonical implementation and remaining effort unknown.
Smallest next action: CB-001, reproduce existing app and record first blocker (45–60 minutes).
Roadmap impact: persistence/organization expands v1; re-estimate after baseline, then reconcile with original 72-hour allocation. Master plan unchanged.
Time spent: founder time not reported.
Public-sharing potential: learning the full PM process while intentionally keeping first release small; Chief of Staff chooses whether to share.

