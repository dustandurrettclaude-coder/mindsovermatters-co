# KJ review, actions 1–6: implementation log (2026-09-28)

This log records what was built for the six recommended actions in
`2026-09-27-kj-second-brain-vs-mom.md` (§6), where the deliverables live, how they were verified, and
what remains for Dustan. The build is a set of drop-in files. Nothing in Minds Over Matters was
modified by this branch: not the live brain, not the installed personal skills, not the product kit
source. This repository is public, so the product files themselves are not committed here. The entry
files (index, Cowork prompts, audit, paste block, listing copy, keyed appendix) sit in the private
workspace mirror (Google Drive, `Minds Over Matters/_drafts/kj-actions-2026-09-28/`); the full tree
(81 files) is delivered as a zip through the session with a sha256 manifest, to be extracted there.

## The licensing assumption

Dustan raised the question of whether the product needs a license key at all, or should be a one-time
purchase owned forever. The build takes the one-time purchase as primary: v4.1 ships an offline
signed-key check whose only enforcement is the 365-day term, and under own-it-forever that check
buys nothing while costing a manual key issue (the only hard stop in setup), a Node.js prerequisite
for buyers, and a support surface. A one-page appendix in the deliverables lists exactly what to
re-insert if the license stays, and the two ways to remove the one-business-day wait (instant issue
from the existing sale webhook, or a grace key on the first run). The decision itself is Dustan's and
is carried as a pending confirmation.

## What was built, by action

1. **Onboarding (product).** One six-step buyer path across README, START-HERE, MOM-BUYER-SETUP, the
   HTML setup guide and the install prompt; the 14/7/6 variants are gone. The license key and its
   steps are removed from every buyer surface and from the setup skill and the update-pack reviewer
   skill. One "tell MOM about yourself" moment: the About-Me page feeds setup, and the interview skill
   only fills gaps. A `[[SETUP-MINUTES]]` placeholder replaces the missing setup-time estimate; it is
   filled only from a timed fresh install. The Free-plan path is presented as first-class.
2. **Product retrieval.** The two-lane retrieval proven in the personal brain (up to 5 open goals and
   5 context memos for the active domain, 90-character titles, one receipt line) is ported into the
   product's session bootstrap and recall skills, with a separate guarded last-used stamp that never
   blocks retrieval on an un-upgraded brain. The checkpoint skill's retrieval claim is now true. The
   domain resolves from the chat, else from an open handoff, else the retrieval is reported as skipped.
3. **Outcome capture.** At goal close, one question ("what happened in the world?", kinds revenue /
   response / metric / none-yet) writes the goal's outcome; none-yet leaves it empty on purpose. It runs
   in full closes only. The nightly Dream routine gains a lane that proposes an outcome check-in for
   goals done 30 days or more with no outcome, capped at five per night, once per goal, excluding loop
   run-instances. Built for the personal brain (migration) and the product (setup SQL). A sales view
   lets a close append the sales summary to a product goal's outcome.
4. **Provenance hygiene.** Writer stamps take the form role@surface/model; the session initializer
   records the surface on the session row; confirmations are incremented only when a later session
   re-reads a memo and still relies on it, or when a manual item is explicitly re-confirmed (a plain
   re-load is not a confirmation); confirmed-by values are constrained to a small vocabulary by a
   change-only validation trigger, with the evidence sentence moved to a new column so old free-text
   rows keep accepting edits; policy #12's session-stamp trigger is implemented with a stamp/block
   toggle (default stamp, since the created-session column is a foreign key and several writers run
   without a session); the four provenance columns ship in the product's setup SQL with an idempotent
   upgrade block; the updated-at touch triggers ignore confirmation-only and last-used-only writes.
5. **Buyer surfaces.** The three-sentence model appears once, verbatim, on each buyer surface (README,
   guide, START-HERE, MOM-BUYER-SETUP, listing copy draft) so one global replace revises it; day-one
   vocabulary is held to ten concepts; the alias lists are gone from buyer documents. The model and
   the listing copy are draft copy awaiting Dustan's "final". The landing page in this repository has
   no content file to carry it (only a CNAME), so no page change was made here.
6. **Per-goal handoff rows (personal).** The close skill writes one handoff row per goal with leftover
   work, keyed by goal id, beside the existing global slot; the kickoff names the goal and its claim
   SQL registers the goal's domain in the active-sessions table; the session initializer reads the
   per-goal row and warns, without blocking, when another session already holds that domain.

Two product defects found on the way were fixed inside the same files: the checkpoint skill's
next-action save used a delete-and-insert that dropped the goal row's other columns (now a single
merging update), and the Dashboard Guide page shipped with a script error that disabled its tabs and
copy button.

## Deliverables (private workspace mirror; full tree in the zip)

| Folder | Contents |
|---|---|
| `kit-patch/` | 19 patched kit files at their kit-relative paths, plus unified diffs and the sha256 of each cut-2b source file |
| `personal-skills/` | close v5.15, session-init v3.4, reconcile v1.10, their diffs, base hashes and changelog entries |
| `sql/` | the personal-brain migration, a 15-check verify file, a full rollback, and before/after texts of the two replaced functions |
| `notes/` | six builder reports, four verification records, the Skill Impact Audit, the Handbook and Setup Guide text changes (59 page-checked pairs), the listing copy draft, the keyed-variant appendix, the brain paste block, and an index |
| `drafts-2026-09-28/` | the Cowork install prompt (part A: migration and personal skills; part B: kit source) |

## Verification

Independent verifiers that did not build the files were given the claims, told to assume mistakes
exist, and asked to report only with evidence (path, pattern and an alternate phrasing for any claim
of absence).

- **Skill text (14 of 15 claims confirmed).** The one exception was intended: the product bootstrap
  skill's description had to change to stay true once it performs retrieval; no trigger phrase was
  added, so the routing table is unchanged.
- **SQL migration (10 of 10 confirmed)** on a throwaway local replica of the live schema: idempotent on
  a second run; the rollback restores the exact before-state; the check-in lane filed 5, 5, 1, 0 across
  four runs, oldest first, never the same goal twice; the pre-existing lanes produced identical output
  before and after. Three hardening notes (stale session pointer handling, a non-finite date guard,
  error message wording) were folded back into the files.
- **Buyer documents (6 of 11 confirmed at first pass).** The failures were text: an entry in the
  product's patch notes overstated two behaviours and omitted five runtime changes, three bullets
  lacked labels, and three stray wordings survived. All were fixed and re-checked. The embedded
  install prompt in the HTML guide was confirmed identical to the prompt file, and all 59 Handbook and
  Setup Guide passages were found on their stated pages.
- **Mechanical checks** (diffs reproduce every patched file byte for byte, license and step-count
  greps, SQL parsing, frontmatter, byte counts): content confirmed on every count (all 19 kit files and
  3 personal skills reproduce byte for byte; 116 of 116 reported figures match; 282 SQL units parse).
  Three claims failed on method or wording, not substance: the diff headers carried absolute paths,
  so plain `patch -p1` could not locate files (every diff was regenerated with portable headers and
  re-proven with `patch -p1` and `git apply`); the license grep counted the patch-notes entry that
  describes the removal and the unchanged v4.1 history; and two skill descriptions changed, both
  keeping their exact trigger lists so the routing table is unchanged.

## Order of landing (the one hard condition)

1. Personal brain: apply the migration, run the 15-check verify, then install the three personal
   skills in the same sitting. Neither half is safe alone: the new skills fail without the new column,
   and the old close skill's free-text ticks fail against the new vocabulary trigger.
2. Product: copy the 19 files over the cut-2b source once the recorded source hashes match; the cut
   itself (fingerprints, skill bundles, version strings, the license checker's disposition, the timed
   install, PDF re-render, release gate) is a separate session.
3. Store: switch the product to a one-time purchase and paste the final listing copy, once the copy is
   approved and the licensing decision is recorded.

## Open for Dustan (each also a pending-confirmation row)

1. The licensing decision (one-time purchase recommended).
2. Approval of the draft copy (three-sentence model; listing copy).
3. The timed Free-plan install that fills `[[SETUP-MINUTES]]`.
4. The dashboard's proposals tab must learn the new check-in proposal type and must not offer a
   mechanical apply for it.
5. Product findings recorded, not fixed: the stale-memo cleanup never flags memos written by the
   checkpoint and close skills (status mismatch); five product writers never stamp a source type; the
   dashboard capture box cannot stamp one under its current column grant; the interview skill's
   standalone triggers could still start a first interview.
