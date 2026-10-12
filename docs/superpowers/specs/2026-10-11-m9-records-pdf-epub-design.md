# M9 Records vault, visit summary PDF and EPUB — design

*Approved in conversation 2026-10-11. Supersedes the M9 scope in [ARCHITECTURE §15](../../ARCHITECTURE.md#m9-records-vault-visit-summary-pdf-and-epub) where they differ; §15, the Plan and the other docs are updated in the PRs that build it.*

## 1. Intent

- **What the owner asked for:** finish M9, the last open Phase 2 milestone, which was deferred on 2026-10-06. It covers three things:
  - a records vault for reports, scans and prescriptions;
  - a visit summary PDF she can hand to her doctor;
  - EPUB books in the reader.
- **Who uses it:** the owner's wife on her Android phone; the owner tests on his iPhone.
- **Success:**
  - Her reports and scans live in Navmaas, encrypted, and open in one tap at a visit.
  - Before a visit she makes a PDF of what she logged since the last one, picks what goes in, and shares it.
  - A DRM-free EPUB opens in the reader like a text book and keeps her place.

## 2. Constraints carried over

- **No network.** Release builds keep no `INTERNET`.
- **No interpretation.** Records and the PDF show values and her own words only. Nothing is rated, ranged, coloured or flagged, and the PDF says nothing is normal or a concern.
- **Encrypted at rest.** Record bytes go only through `AttachmentStore` and are decrypted only in memory. The one exception is the temporary plain copy handed to the share sheet (§4.5). The Plan's hard line is that she must be warned before it.
- **Design first:** the boards are approved before code (ADR 043). Content and words live in `app_en.arb` and are covered by the hard-line test.
- **Process:**
  - Each PR bumps the version and uses a Conventional Commits title.
  - The docs stay in sync in the same PR.
  - Branches come from `main`.

## 3. Pieces and order

| # | PR | Branch | Version | Schema |
|---|---|---|---|---|
| 1 | M9a `feat: records vault and visit summary PDF` | `feat/m9a-records-visit-summary` | 1.7.0 | v13 |
| 2 | M9b `feat: EPUB books` | `feat/m9b-epub` (from `main` after M9a merges) | 1.8.0 | v14 (no table change) |

**Packages** (owner approved 2026-10-11): `pdf` is new. `archive` and `xml` are already in the lockfile through `image` / `pdfrx` and become direct dependencies. All three are offline and pure Dart. They are recorded in ARCHITECTURE §3 and one ADR.

## 4. M9a — Records and the visit summary

### 4.1 Schema v13 (one bump)

- `attachment` gains these columns:
  - `pregnancy_id`: references `pregnancy`; nullable in SQL, always set by the app.
  - `category`: `textEnum<RecordCategory>`, one of `report`, `scan`, `prescription` or `other`; defaults to `other`.
  - `title`: text, defaults to `''`.
  - `taken_on`: a date-only text column, like `startDate`; nullable.
  - `size_bytes`: integer, nullable.
- `appointment_id` stays nullable, as it already is.
- **Migration** for existing rows (prescription photos from M3b):
  - `pregnancy_id` comes from the row's appointment.
  - `category` is set to `prescription`.
  - `title` stays `''`, and the UI shows the category word when the title is empty.
  - `taken_on` is set to the appointment's date.
  - `size_bytes` stays null.
- `make-migrations`, plus the migration test for every version pair, including "an old photo shows under Prescriptions".
- **Backups:** the `.navmaas` format doesn't change. The whole `attachments/` folder and the key are already in it (§11).
  - Its "photos" count becomes "records". The manifest field stays `photos` so older backups still read.
  - An older backup restores and migrates.
- **Delete all:** already covered, since it removes the folder and the key.

### 4.2 Care → Records

- **Care tile:** a "Records" tile in Care's grid, showing the count or "None yet" and the latest record's title.
- **The Records screen (`/care/records`):**
  - Overline: Care. Title: Records.
  - A "Make visit summary" button (secondary) at the top.
  - Filter chips: All · Reports · Scans · Prescriptions · Other.
  - Records are grouped by month of `taken_on` (falling back to `created_at`), newest first.
  - Each row shows a thumbnail (an image, or a PDF glyph), the title or category word, the date and the size.
- **Empty state:** one calm line plus Add.
- **Add** (FAB-style primary button):
  1. A sheet offers Take photo, Choose photo and Choose file (images or PDF). It carries the existing privacy line: "Kept encrypted on this phone."
  2. **Photos** use `image_picker` with `maxWidth: 2400` and `imageQuality: 85`, as visits do today. **Files** use `file_picker` with `jpg`, `jpeg`, `png`, `heic` and `pdf`.
     - A file over 25 MB is refused with an amber line, "Too large to keep here (25 MB at most)".
     - HEIC is kept as it is and shown through `Image.memory`. If a phone can't decode it, the viewer shows the "couldn't open" state.
  3. **Details** dialog:
     - Title (optional).
     - Kind: four chips, preselected from where she started (Prescription from a visit, Other elsewhere).
     - Date: defaults to today, or the visit's date when added from a visit. Never later than today.
     - Visit: when added from a visit it's already linked. From Records there's no link; linking later isn't in M9.
  4. **Saving…** shows progress while it encrypts. A large PDF takes a few seconds, since AES-GCM runs in pure Dart.

### 4.3 Record viewer (`/care/records/:id`)

- **Images:** `InteractiveViewer` over `Image.memory`.
- **PDFs:** `pdfrx`'s viewer from bytes (`PdfDocumentRef` from data), with page m of n.
- **Top bar:** back, the title as the heading, and a ⋯ menu with Edit details, Share and Delete.
  - **Edit details** opens the same dialog as Add.
  - **Delete** is red and asks first. It soft-deletes the row and deletes the file, as `removeAttachment` does today.
- **Couldn't decrypt or decode:** a calm line, with Delete still available.

### 4.4 Visit screen

- The photo row becomes **Records from this visit**:
  - thumbnails of the visit's records, each tapping into the viewer;
  - Add, which runs the same flow with the visit linked and Prescription preselected.
- The ✕ remove button on thumbnails goes. Deleting happens in the viewer, with its confirm.
- A **Make visit summary** button opens the summary screen, with the range starting at the previous visit before this one.

### 4.5 Sharing a record

- Share first shows a dialog: "Share a copy?" / "The shared copy isn't encrypted. Navmaas deletes its copy after sharing." with Cancel and Share.
- The bytes are decrypted into `recordsTempDir` (the temporary folder `navmaas-share/`), named `<title or category>.<ext>`. The file goes to `share_plus`, which already shares backups.
- The copy is deleted when the share sheet returns, whatever the result.
- The folder is cleared at app start, like `clearVoiceTemp`, in case the app was killed mid-share.
- The visit summary PDF uses the same folder and the same clean-up.

### 4.6 Visit summary (`/visit-summary`)

- **Range** (`PillSegmented`): Since last visit · Last 4 weeks · Whole pregnancy · Custom.
  - **Since last visit** is the default. It starts on the date of the most recent past visit (from a visit screen, the previous visit before that one) and runs to today. With no past visit it becomes Whole pregnancy.
  - **Custom** opens a date-range picker clamped to the pregnancy's start date and today.
- **Sections** (checkboxes, with the last choice kept in `settings` as `summary_sections`):

| Section | On by default | Content (values only) |
|---|---|---|
| Pregnancy summary | ✅ | Name, due date, week and day today, dating method, doctor and clinic |
| Supplements | ✅ | Each supplement with its dose as written, and "taken on N of M days" in the range |
| Vitals | ✅ | Weight, BP and blood-sugar readings in the range (date, time, value, sugar context), as a table |
| Questions | ✅ | Unasked questions, plus questions linked to this visit |
| Kicks and contractions | ✅ | Kick sessions (count, time taken) and contraction summaries, using `patterns.dart`'s averages |
| Records | ✅ | Titles, kinds and dates of records in the range (list only; files are never put in the PDF) |
| Wellbeing | ☐ | Mood words, symptoms with strength, and sleep and water per day |
| Birth plan | ☐ | Her answers under each prompt |

- **Make PDF:**
  1. `visitSummaryContent(...)` is pure Dart. It takes the rows and the choices and returns `SummaryDoc`: a title, the range, and a list of sections, each with headed lines or table rows.
  2. `renderSummaryPdf(SummaryDoc)` uses `pdf` with A4 pages and static **Nunito Regular / Bold** TTFs. These are made from the bundled OFL variable font by a one-off `fonttools instancer` run and committed under `assets/fonts/pdf/` with the OFL text.
  3. The footer says "Made with Navmaas on {date} · values as she logged them".
  4. The PDF goes to the share sheet through §4.5's temporary folder, then is deleted.
- **Empty sections** print one line, "Nothing logged in this range". A section is never left out silently.
- **Words:** headings and labels live in `app_en.arb` (`summary*`), and the content test checks them. Nothing interprets: no "normal", "high", "low", "concern", "risk" and so on.

### 4.7 Tests and done-when (M9a)

- **AttachmentStore (unit):**
  - A saved image or PDF has no JPEG, PNG, HEIC or `%PDF` signature on disk.
  - After viewing, nothing appears under any app folder.
  - After a share, `recordsTempDir` is empty.
  - App start clears leftovers.
- **Migration:** every version pair. A v12 photo becomes a v13 Prescription with the visit's `pregnancy_id` and date.
- **Backup round-trip:** with records of each kind, and a v12 backup restoring onto v13.
- **Repository:** per pregnancy (a new pregnancy shows no records); the category filter; month grouping; the 25 MB limit; a date never in the future.
- **`visitSummaryContent`:**
  - only the chosen sections;
  - the range respected at both ends;
  - "since last visit" with and without a past visit;
  - empty sections get their line;
  - no interpretation words in any produced line (the word list from the content test).
- **`renderSummaryPdf`:** produces a valid PDF (the `%PDF` header, more than one page for long data). Text extraction runs on a device in `integration_test/visit_summary_test.dart` through `pdfrx`, and checks that the chosen headings are present and the unchosen ones absent.
- **Widgets:**
  - add record from a photo and from a file;
  - the viewer for an image and a PDF;
  - share warning, then share, then the temporary copy is gone;
  - delete;
  - the visit's records;
  - the summary screen's defaults and the remembered sections.
- Accessibility entries and goldens (light and dark, macOS and Linux) for every new screen, sheet and dialog.

## 5. M9b — EPUB books

### 5.1 Import

- `libraryExtensions` gains `'epub': LibraryKind.epub`. `LibraryKind` is stored as text, so no table changes; but the schema goes to v14 so 1.7.0 refuses a 1.8.0 backup, because its restore checks only `schemaVersion` and drift can't read an unknown kind (owner approved 2026-10-12).
- **At import**, a quick check (unzip `META-INF/container.xml` and the OPF):
  - not a valid EPUB: "Couldn't read this book";
  - `META-INF/encryption.xml` lists encrypted content (DRM): "This book is locked (DRM) and can't be opened here".
  - Both are calm lines, and nothing is copied.
- The file is kept as `.epub` in `db/library/` like other books, and backups include it the same way.

### 5.2 Parsing (`lib/features/sessions/domain/epub.dart`, pure Dart)

- `parseEpub(Uint8List) → EpubBook(title, chapters: [(title, paragraphs)])`.
- **Unzip** with `archive`: `container.xml` gives the OPF path; the OPF gives `dc:title`, the manifest and the spine order; the nav document (EPUB 3) or `toc.ncx` (EPUB 2) gives chapter titles.
- **Each spine XHTML** is parsed with `xml` (lenient: if a document doesn't parse, its text is extracted with tags stripped). It keeps:
  - `h1`–`h3`, which become the chapter title when no TOC title exists;
  - `p`, `li` and `blockquote`, each becoming a paragraph;
  - `br` as a line break.
- It skips `img`, `svg`, `table`, `script` and `style`.
- **Entities** go through `xml`'s decoder (named HTML entities beyond XML's five are mapped for the common ones: `&nbsp;`, `&mdash;`, `&rsquo;` and the like).
- Empty chapters are dropped.

### 5.3 Reader

- The EPUB path reuses the text reader:
  - `paragraphs` are the chapters joined, each chapter's title as a heading paragraph (Literata, larger, `Semantics(header: true)`);
  - position in hundred-thousandths (thousandths for text; a novel needs the finer place), Paper / Night, eye rest and session logging as for text.
- **Contents** button (an icon button with a tooltip) in the top bar for EPUBs only. It opens a sheet listing the chapters; tapping one scrolls to that chapter's offset. The offset comes from the heading's render box (`getOffsetToReveal`); the text view builds every paragraph, so the heading always exists (CLAUDE.md's lazy-list rule doesn't apply).
- Parsing happens on open, in `compute()` so a large book doesn't block the frame.
- A parse failure shows the existing "couldn't open" state.

### 5.4 Tests and done-when (M9b)

- `parseEpub` covers:
  - EPUB 2 (ncx) and EPUB 3 (nav);
  - the spine order kept;
  - images and tables skipped;
  - entities decoded;
  - malformed XHTML falling back;
  - DRM detected;
  - not-a-zip.
- **Widget test:** an EPUB built in the test (with `archive`) is imported, opens with its chapters, Contents jumps to chapter 2, and reopening lands at the same place.
- The library list shows "EPUB" and reading progress like a text book.
- Accessibility entry and goldens for the reader with Contents and the Contents sheet.

## 6. Prototype boards (Gate 2, light and dark)

1. Care with the Records tile
2. Records (list + filter chips + Make visit summary)
3. Records, empty
4. Add record sheet
5. Record details dialog
6. Record viewer (image)
7. Record viewer (PDF, with ⋯ menu open)
8. Share warning dialog
9. Visit with "Records from this visit" and Make visit summary
10. Visit summary (range + sections)
11. Library Add sheet accepting EPUB
12. Reader (EPUB) with the Contents button
13. Contents sheet

Differences that remain after build go in DESIGN_SYSTEM §8.

## 7. Owner decisions recorded (go into the Plan)

- **Packages:** `pdf` (new), with `archive` and `xml` promoted to direct dependencies.
- **Records belong to a pregnancy** (`pregnancy_id`, like visits and vitals). A new pregnancy starts with none, and backups keep them all.
- **Visit summary range:** "Since last visit" by default (Whole pregnancy when there is no past visit), with Last 4 weeks, Whole pregnancy and Custom.
- **Sections** on by default: the pregnancy summary, supplements, vitals, questions, kicks and contractions, and records. Off by default: wellbeing and the birth plan. Her last choice is remembered.
- **Where the summary is made:** a visit screen and Care → Records. Not Me; ARCHITECTURE §15 said "from a visit or from Me", and this changes it.
- **The visit screen** shows "Records from this visit". Its Add creates a record linked to the visit, with Prescription preselected.
- **EPUB** gets a Contents sheet for chapters in the reader.
- **Split:** M9a, records and the PDF (1.7.0, schema v13); M9b, EPUB (1.8.0).
- **Still to come:** approval of the prototype boards (§6), then the implementation plan.
