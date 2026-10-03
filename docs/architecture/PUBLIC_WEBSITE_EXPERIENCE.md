# Public Website Experience

**Status:** implemented on `feature/master_refactor_integration`
**Scope:** public homepage, programme cards, primary navigation, admissions entry page, About, FAQ, and Learning Journal.

## Design direction

The public site is an academy website for students and families. It presents Sohoj Academy's learning approach and currently published programme offerings before directing visitors to registration or the Digital Campus. It is not an ERP navigation page.

The visual language keeps the existing dark navy foundation, blue and green accents, bilingual English/Bangla copy, rounded components, and the academy's “learning made easy” positioning. The website uses dark mode only. Language selection remains available.

## Page and navigation map

| Destination | Purpose |
| --- | --- |
| `/` | Photo-led introduction, live programme offerings, six-step learning flow, academy differentiators, and registration entry points |
| `/#programs` | Current public programme cards sourced from active ERP offering data |
| `/#method` | Sohoj Learning Method flow: Understand → Practise → Test → Find mistakes → Learn again → Improve |
| `/#why-sohoj` | Small groups, assessment, guardian visibility, and academic records |
| `/about` | Academy mission, vision, and learning commitments |
| `/faq` | Practical information on registration, admission, fees, subjects, and placement |
| `/journal` | Short study guidance for students and guardians |
| `/interest` | Public interest or admission application form, without student account creation |
| `/auth` | One Digital Campus action in the primary navbar |

All navbar section links use absolute home anchors, so they work from secondary pages. Interest applicants have a direct “Go to homepage” path.

## Programme cards

Cards retain the public details supplied by ERP. The offering title, academic context, available subjects, fee summary, and application action are visible immediately. Longer descriptions and supporting schedule, requirements, admission policy, and placement details are inside a native expandable disclosure. The disclosure works without client JavaScript and remains keyboard accessible.

Applications remain separate from interest registration. The button is shown only when the offering accepts applications; the public form remains the same source for student and guardian details.

## Photo and learning diagram

The homepage uses a locally bundled illustrative classroom photo with an explicit illustrative alt description; it is not presented as a documentary photo of a specific Sohoj Academy class. The learning method is shown as a six-step raised-card flow diagram with directional progression and a return-to-learning narrative when a gap is found.

## Content maintenance

Programme content and fees continue to come from ERP records. About, FAQ, and journal copy are currently checked-in website content. If academy staff need to edit these without code changes, add a purpose-built CRM content editor in a later task; do not place these public content fields inside accounting or academic master-data forms.

## Acceptance checks

- Exactly one Digital Campus action is visible in each navbar breakpoint.
- Program, Learning Method, and Why Sohoj links resolve from every public route.
- Programme details collapse by default and expand in place.
- No public theme switch is rendered; dark styling is the configured default.
- About, FAQ, Journal, and interest routes render with the shared public navbar and footer.
- The interest page returns visitors to the homepage with explicit home wording.
- English and Bengali copy are available for the public-site additions.
