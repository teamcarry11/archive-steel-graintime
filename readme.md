# graintime - astronomical timestamps for version control

**team:** teamshine05 (leo ♌ / V. the hierophant - sacred knowledge)  
**grainbranch:** `12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamshine05`  
**status:** ⚠️ **work in progress** - migrating to org structure  
**voice:** glow g2 (patient teacher, asks questions, hand-holds)

---

> **🌙 what if git branches remembered the stars?**

this is **teamshine05's graintime** - a system for encoding astronomical data into version control:

* **nakshatra**: moon's position (27 lunar mansions)
* **ascendant**: rising sign + degree at moment of creation
* **solar house**: sun's house position (time of day awareness)
* **holocene era**: 12025 HE (not 2025 CE - acknowledging 10,000 years of human civilization)

**graintime** makes your git branches astronomically aware. immutable. temporally precise. cosmically connected.

does this intrigue you? let me show you what's inside... 🌾

---

## 📁 current modules (newest first!)

**`grainbranch.scm`** (1130 pdt 10-28) - **branch automation** 🌾  
→ [read it here](https://github.com/teamshine05/graintime/blob/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamshine05/grainbranch.scm)

* 389 lines of steel automation magic
* create grainbranches with one command
* handles git operations + github api
* multi-remote support (github + codeberg)
* **CLI**: `steel grainbranch.scm create teamtravel12`

**`graintime.scm`** (0000 pdt 10-28) - **astronomical calculations** 🌙  
→ [read it here](https://github.com/teamshine05/graintime/blob/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamshine05/graintime.scm)

* 400+ lines of steel astronomical logic
* nakshatra system (mantreshwara's classical vedic order - krittika #1!)
* nakshatra abbreviation (for <75 char branch names)
* offline fallback (conservative estimation when no network)
* zodiac signs (sidereal, not tropical)
* holocene era conversion
* **API**: `(graintime-now "teamtravel12")` → full grainbranch name

---

## 🌟 what is team 05?

**leo ♌** (fixed fire) - creative, radiant, self-assured  
**hierophant V** (tarot) - sacred knowledge, teaching, tradition meets innovation

_the hierophant holds ancient wisdom but isn't afraid to illuminate new paths, right?_ ☀️⚡

---

## 🎯 what graintime does

### astronomical git branches

every grainbranch encodes:
- **exact moment**: year, month, day, hour, minute, timezone (holocene era)
- **moon's nakshatra**: which of 27 lunar mansions was the moon in?
- **ascendant**: what was rising on the eastern horizon? (sign + degree)
- **sun's house**: which of 12 houses was the sun in? (time of day)
- **team identifier**: which team created this branch?

example:
```
12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamshine05
```

this tells a complete story:
- holocene year 12025, october 28
- 11:30am pacific daylight time
- moon in uttara ashadha nakshatra
- aries rising at 23 degrees
- sun in 12th house (late morning, approaching noon)
- created by teamshine05

### offline fallback

no internet? no problem! graintime includes conservative estimation algorithms:
- moon's nakshatra estimated from day-of-year (27.3 day cycle)
- ascendant estimated from time-of-day (~2 hours per sign)
- sun's house estimated from hour (2 hours per house)

estimated values are marked with `~` prefix so you know they're approximations.

when connectivity returns, verify and update if needed!

### format validation

before creating a branch, graintime validates:
- ≤75 characters (github's sweet spot for clean display)
- proper component formatting (no typos, out-of-range values)
- nakshatra abbreviation applied if needed

### pure steel implementation

no java time libraries. no clojure interop. pure rust+steel stack!
- `(require "graintime.scm")` and you're ready
- call from other steel scripts
- rust FFI for future swiss ephemeris integration

---

## 🛠️ usage

### quick start (grainbranch automation)

```bash
# navigate to your git repo
cd ~/myproject

# create astronomically-timestamped branch
steel grainbranch.scm create teamtravel12

# that's it! grainbranch will:
# 1. calculate current astronomical data
# 2. generate grainbranch name
# 3. create local branch
# 4. push to github (and other remotes)
# 5. set as default branch
# 6. update repo description
```

### manual usage (graintime calculations)

```steel
(require "graintime.scm")

;; generate graintime for current moment (offline estimation)
(graintime-now "teamtravel12")
;; → "12025-10-28--1130-PDT--moon-~uttaradha-asc-arie23-sun-12h--teamtravel12"
;;   (note: ~ prefix means moon position is estimated)

;; manual graintime with known astronomy
(format-graintime 2025 10 28 11 30 "PDT"
                  "uttara-ashadha" 0 23 12 "teamtravel12")
;; → "12025-10-28--1130-PDT--moon-uttashsdh-asc-arie23-sun-12h--teamtravel12"

;; validate a graintime string
(is-valid-graintime? "12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12")
;; → #t

;; abbreviate long nakshatra names
(abbreviate-nakshatra "uttara-ashadha")
;; → "uttashsdh" (9 chars instead of 14!)

(abbreviate-nakshatra "purva-bhadrapada")
;; → "purvbhdrpd" (10 chars instead of 16!)
```

---

## 📚 the 27 nakshatras (mantreshwara's order)

we follow mantreshwara's classical vedic tradition from **phaladeepika**, where **krittika** is the 1st nakshatra:

1. krittika (0° aries)
2. rohini
3. mrigashira
4. ardra
5. punarvasu
6. pushya
7. ashlesha
8. magha
9. purva-phalguni
10. uttara-phalguni
11. hasta
12. chitra
13. swati
14. vishakha
15. anuradha
16. jyeshtha
17. mula
18. purva-ashadha
19. **uttara-ashadha** ← moon was here at 1130 PDT!
20. shravana
21. dhanishta
22. shatabhisha
23. purva-bhadrapada
24. uttara-bhadrapada
25. revati
26. ashwini
27. bharani

each nakshatra is 13°20' of arc (360° / 27 = 13.333°).

the moon completes the full cycle in ~27.3 days.

---

## 🔗 architecture

### template repo structure

this is the **template/org side** - shared specs and base implementations:

* **location**: `teamshine05/graintime/`
* **purpose**: canonical steel implementations, shared by all teams
* **what**: graintime.scm + grainbranch.scm (the core logic)
* **symlinked**: into personal grainstores for development

### personal repo connections

teams using graintime will:
1. **symlink** this repo into their grainstore (e.g., `grainstore/teamshine05/graintime/`)
2. **import** the steel modules in their scripts
3. **extend** with custom logic if needed (but keep core here!)

example symlink:
```bash
ln -s ~/github/teamshine05/graintime ~/kae3g/grainkae3g/grainstore/teamshine05/graintime
```

this keeps the template clean while allowing personal customization!

---

## 🌊 philosophy

### immutability as honesty

when you create a grainbranch, you're saying: "this work happened HERE, at THIS moment, under THESE stars."

you can't change that. the moon won't reverse its orbit for you!

honest computing means acknowledging the irreversible flow of time.

### cosmic context

why encode astronomy? because **time is more than a clock tick**.

the moon's nakshatra connects you to ancient vedic wisdom.  
the ascendant connects you to your local horizon.  
the sun's house connects you to the rhythm of day and night.

these aren't "extra metadata" - they're **temporal context**.

### offline resilience

connectivity isn't guaranteed. satellites fail. cables break. you're in a cabin in the woods.

graintime embraces offline-first with conservative estimation.

mark it as estimated (`~` prefix), continue working, verify later.

### glow g2 voice

every steel script is a teaching moment!

comments ask socratic questions. explain WHY, not just WHAT. check for understanding.

code should read like a patient teacher explaining to an eager student.

---

## 🎓 learning paths

**start here**: read `graintime.scm` - it's full of teaching comments!

**then explore**:
1. **grainbranch.scm** - see how git automation works
2. **create a branch** - try `steel grainbranch.scm create teamshine05`
3. **read the patent** - full specification at [teamkae3gtravel12/xzvsbj](https://github.com/kae3g/teamkae3gtravel12/blob/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12/xzvsbj-12025-10-28--0030-pdt--graintime-patent-whitepaper.md)

each builds on the last. follow your curiosity! ☀️

---

## 📋 implementation status

### ✅ phase 1 complete

* graintime.scm (400+ lines)
  - nakshatra system (mantreshwara order)
  - nakshatra abbreviation
  - zodiac signs (sidereal)
  - holocene era conversion
  - format validation
  - offline fallback
* grainbranch.scm (389 lines)
  - git repository detection
  - branch creation automation
  - github api integration
  - multi-remote push
  - cli interface

### 🚧 phase 2 in progress

* swiss ephemeris integration (precise astronomy via rust FFI)
* graintime parser (string → components)
* graintime diff (compare two graintimes)
* graintime visualization (cli output with colors)
* rust FFI bindings (call from rust code)

### 📋 phase 3 planned

* gitlab/codeberg api support
* batch mode (create for multiple repos)
* interactive mode (prompt for values)
* grainbranch.md metadata file generation
* integration with grainflow (deployment automation)

---

## 💭 questions?

**"why vedic astrology specifically?"**  
→ mantreshwara's system aligns krittika with aries (first sign), creating beautiful synchronicity between lunar and solar cycles!

**"what if i don't believe in astrology?"**  
→ perfect! treat it as **arbitrary but consistent temporal metadata**. the nakshatra number is just a day-of-month mod 27. still useful!

**"can i use this with my existing repos?"**  
→ absolutely! `steel grainbranch.scm create yourteamname` works anywhere git works!

**"is the offline estimation accurate?"**  
→ within ~1 nakshatra (moon) and ~1 sign (ascendant). good enough for identification, but mark as estimated with `~` prefix!

**"why steel instead of clojure/babashka?"**  
→ pure rust+steel stack! safety meets elegance. R5RS compliant scheme. no JVM, no java interop, just rust and lisp harmony!

---

## 🌐 related projects

* **teamtreasure02/grainorder** - permutation-based file naming (the organizational complement to graintime)
* **teamtreasure02/graindb** - immutable database with grainorder entity IDs and time-travel queries
* **teamtravel12/grainflow** - deployment automation that uses grainbranches
* **teamkae3gtravel12** - personal grainstore exploring all grain network concepts

---

## ⚠️ status note

this repository is currently **transitioning from personal exploration to org structure**.

what this means:
- **core logic is stable** (graintime.scm, grainbranch.scm work!)
- **documentation is being refined** for broader audience
- **examples are being generalized** from kae3g-specific to team-agnostic
- **testing is in progress** across different repos and teams

**feel free to explore**, but know that some rough edges remain as we polish for production use!

issues and PRs welcome - especially if you find bugs or unclear documentation! 🙏

---

## ☀️ final thoughts

this is a **journey**. the hierophant teaches through patient explanation, connecting ancient wisdom with modern practice.

you don't need to understand vedic astrology to use graintime. you don't need to believe in cosmic synchronicity.

but maybe, just maybe, encoding the stars into your version control will make you pause and think:

_"this commit happened at THIS moment, under THESE stars. it's unique. it's unrepeatable. it's part of something larger."_

and that's the real magic - **awareness of time as flow, not just sequence**. 🌊⚡

_may your grainbranches shine like stars..._ ☀️🌾

---

## license

dual-licensed under your choice of:
- **mit license** - see [license-mit.md](license-mit.md)
- **apache license 2.0** - see [license-apache.md](license-apache.md)

you may use this software under either license, or under any other permissive open source license of your choosing, provided you include attribution to the original authors.

**we believe in maximum freedom for users and developers!** 🌾

---

**org repo**: https://github.com/teamshine05/graintime  
**grainbranch**: `12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamshine05`  
**related**: [team 12 grainstore](https://github.com/kae3g/teamkae3gtravel12)  
**main monorepo**: https://github.com/kae3g/grainkae3g

_now == next + 1_ 🌾

