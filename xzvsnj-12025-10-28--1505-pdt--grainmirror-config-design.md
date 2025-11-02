# grainmirror configuration system - preventing collisions with style! 🪞⚡

**grainorder**: xzvskd  
**timestamp**: 12025-10-28--1505-pdt  
**team**: teamshine05 (leo ♌ / V. the hierophant - knowledge systems)  
**language**: steel (rust-hosted scheme)  
**purpose**: configuration system for grainmirror to prevent grainorder collisions

---

## 🤔 what problem are we solving?

hey, let's talk about what just happened! we created a beautiful grainmirror system that copies readmes across repos with unique timestamps and grainorders. but then we hit a problem - **grainorder collisions**! 

look at this:
```
teamkae3gtravel12/
├── xzvskg-12025-10-28--1410-pdt--readme-kae3g-teamkae3gtravel12.md
└── xzvskg-12025-10-28--1455-pdt--readme-teamrebel10-graincard.md  ← COLLISION!
```

both files have `xzvskg` but different timestamps (1410 vs 1455) and different sources (kae3g vs teamrebel10). that's not right! if `xzvskg` was the smallest grainorder at 1410, then the 1455 file should have gotten an even SMALLER grainorder, right?

**why did this happen?**

when we assigned `xzvskg` to the 1455 file, we only looked at files from the SAME source repo. we didn't check ALL existing grainorders in the destination directory!

**what should have happened?**

1. scan destination directory: "what's the current smallest grainorder?"
2. find: `xzvskg` (from 1410)
3. calculate: "what's the next smaller grainorder?" → `xzvskd`
4. assign: `xzvskd` to the 1455 file (no collision!)

does this make sense? we need to look at the WHOLE destination, not just our own files! 🌊

---

## 💎 the solution: configuration + validation

here's what we're building:

### 1. steel config file (`.grainmirror.scm`)

a simple, readable config that defines:
- **where** to mirror files (destination repos with full grainbranch URLs)
- **what** to mirror (source files)
- **how** to validate (grainbranch format checking)

example:
```steel
;; .grainmirror.scm - grainmirror configuration
(define grainmirror-config
  (hash
    ;; destination hubs (full grainbranch URLs)
    :destinations 
      (list
        "https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12")
    
    ;; source to mirror mappings
    :sources
      (hash
        "~/github/teamshine05/graintime/readme.md" 
          (hash :org "teamshine05" 
                :repo "graintime")
        
        "~/github/teamrebel10/graincard/readme.md"
          (hash :org "teamrebel10"
                :repo "graincard"))))
```

### 2. grainbranch validation

before we mirror anything, validate the destination URL:

```steel
(define (valid-grainbranch-url? url)
  "Check if URL has a properly formatted grainbranch.
  
  EXAMPLE VALID:
  https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12
  
  MUST MATCH:
  - YYYYY-MM-DD--HHMM-TZ format
  - moon-NAKSHATRA
  - asc-SIGNXX
  - sun-XXh
  - team name
  
  TEACHING: Why validate? Because if someone accidentally points to
  a repo without a proper grainbranch, we could create a mess! Better
  to error early and clearly than to quietly fail later. 🌾"
  
  ;; extract the branch name from URL
  (let* ([parts (string-split url "/tree/")]
         [branch (if (= (length parts) 2) (cadr parts) #f)])
    (if branch
        ;; validate grainbranch format using grain-specs
        (valid? spec::grainbranch-name branch)
        #f)))
```

### 3. collision detection

scan the destination directory for ALL existing grainorders:

```steel
(define (find-smallest-grainorder directory-path)
  "Scan directory and return the smallest (newest) grainorder.
  
  ALGORITHM:
  1. List all files matching grainorder pattern (6 chars)
  2. Extract grainorder from each filename
  3. Sort alphabetically (smallest first)
  4. Return the smallest one
  
  TEACHING: This is crucial! We need to know what grainorders are
  ALREADY taken in the destination, regardless of which repo they
  came from. Think of it like checking what parking spots are taken
  before you park - you need to see ALL cars, not just your own! 🚗"
  
  (let* ([files (directory-list directory-path)]
         [grainorder-files (filter has-grainorder? files)]
         [grainorders (map extract-grainorder grainorder-files)]
         [sorted (sort grainorders string<?)])  ;; ascending = smallest first
    (if (empty? sorted)
        "xzvsnm"  ;; no files yet, start at maximum non-archive
        (car sorted))))  ;; return smallest existing
```

### 4. auto-assignment with carry logic

use our improved `prev-grainorder` function:

```steel
(define (assign-next-grainorder destination-dir)
  "Assign the next available grainorder (smaller than current smallest).
  
  PROCESS:
  1. Find current smallest grainorder in destination
  2. Calculate next smaller (using prev-grainorder with carry)
  3. If hit 'b' at position, carry left and reset right
  4. Return new unique grainorder
  
  EXAMPLE:
  - Current smallest: xzvskg
  - Next smaller: xzvskd (decrement last char g→d)
  
  EXAMPLE WITH CARRY:
  - Current smallest: xzvskb (hit 'b' limit!)
  - Next smaller: xzvsdb (carry: k→d, reset b→z)
  
  TEACHING: This is like counting backwards! When you hit 0 in one
  position, you borrow from the left. Here, when we hit 'b' (our
  smallest char), we 'borrow' from the previous position. Does
  this feel like elementary school subtraction? That's exactly
  what it is, just in base-13 with no repeating digits! 🔢"
  
  (let ([smallest (find-smallest-grainorder destination-dir)])
    (prev-grainorder smallest)))
```

---

## 🛠️ implementation plan

### phase 1: config file format ✅ (this doc!)

- [x] design `.grainmirror.scm` format
- [x] specify destination URL validation rules
- [x] define source mappings structure

### phase 2: validation functions 🚧

- [ ] implement `valid-grainbranch-url?` using grain-specs
- [ ] parse URL to extract branch name
- [ ] validate against grainbranch regex/spec
- [ ] provide clear error messages on invalid URLs

### phase 3: collision detection 🚧

- [ ] implement `find-smallest-grainorder` 
- [ ] scan destination directory recursively
- [ ] extract grainorders from filenames
- [ ] return current smallest (newest)

### phase 4: auto-assignment 🚧

- [ ] integrate with `prev-grainorder` (carry logic)
- [ ] handle edge cases (empty directory, overflow)
- [ ] test with multiple simultaneous mirrors

### phase 5: interactive setup 📋

- [ ] `grainmirror init` command
- [ ] prompt for destination URL
- [ ] validate on input
- [ ] write `.grainmirror.scm` config file

### phase 6: non-interactive setup 📋

- [ ] `grainmirror config set` command
- [ ] accept destination URL as argument
- [ ] validate before writing
- [ ] merge with existing config

---

## 📋 config file spec

### location

```
~/.grainmirror.scm          # global config (all repos)
./.grainmirror.scm          # local config (this repo only)
```

**precedence**: local overrides global

### format

```steel
;; .grainmirror.scm
;; grainmirror configuration (steel hash)

(define grainmirror-config
  (hash
    ;; DESTINATIONS: where to mirror files
    ;; must be full GitHub URLs with valid grainbranches
    :destinations 
      (list
        "https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12"
        "https://github.com/teamtravel12/teamtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12")
    
    ;; SOURCES: what to mirror (source file → metadata)
    :sources
      (hash
        ;; teamshine05/graintime readme
        "~/github/teamshine05/graintime/readme.md"
          (hash :org "teamshine05"
                :repo "graintime"
                :description "astronomical timestamps for version control")
        
        ;; teamrebel10/graincard readme
        "~/github/teamrebel10/graincard/readme.md"
          (hash :org "teamrebel10"
                :repo "graincard"
                :description "75×100 monospace teaching cards")
        
        ;; teamtreasure02/grainorder readme
        "~/github/teamtreasure02/grainorder/readme.md"
          (hash :org "teamtreasure02"
                :repo "grainorder"
                :description "permutation-based file naming"))
    
    ;; OPTIONS: behavior configuration
    :options
      (hash
        :auto-assign-grainorder #t      ;; auto-calculate next smallest
        :validate-destinations #t       ;; validate grainbranch URLs
        :error-on-collision #t          ;; error if grainorder collision
        :verbose #t)))                  ;; print detailed progress
```

### validation rules

**destination URLs must**:
- start with `https://github.com/`
- include `/tree/` path separator
- have valid grainbranch after `/tree/`
- grainbranch format: `YYYYY-MM-DD--HHMM-TZ--moon-NAKSHATRA-asc-SIGNXX-sun-XXh--TEAM`

**source paths must**:
- be absolute or relative file paths
- point to existing readable files
- include org and repo metadata

**grainorders must**:
- be exactly 6 characters
- use only grainorder alphabet (xbdghjklmnsvz)
- have no repeating characters
- be unique within destination directory

---

## 🎯 usage examples

### interactive setup

```bash
$ steel grainmirror.scm init

🪞 grainmirror configuration setup

destination URL (must include valid grainbranch):
> https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12

✓ valid grainbranch detected!
  date: 12025-10-28 1130 PDT
  moon: uttaradha (21st nakshatra)
  asc: aries 23°
  sun: 12th house
  team: teamtravel12

add source file to mirror? (y/n)
> y

source file path:
> ~/github/teamshine05/graintime/readme.md

org name:
> teamshine05

repo name:
> graintime

✓ configuration saved to .grainmirror.scm
✓ ready to mirror! run: steel grainmirror.scm sync
```

### non-interactive setup

```bash
$ steel grainmirror.scm config set-destination \
  "https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12"

✓ destination validated and saved!

$ steel grainmirror.scm config add-source \
  ~/github/teamshine05/graintime/readme.md \
  --org teamshine05 \
  --repo graintime

✓ source added to config!
```

### sync with collision detection

```bash
$ steel grainmirror.scm sync

🪞 grainmirror sync starting...

scanning destination: ~/github/kae3g/teamkae3gtravel12
  found 12 existing files
  smallest grainorder: xzvskg (1455 PDT)

calculating next grainorder...
  prev-grainorder(xzvskg) = xzvskd
  ✓ no collision!

mirroring: ~/github/teamshine05/graintime/readme.md
  → ~/github/kae3g/teamkae3gtravel12/xzvskd-12025-10-28--1505-pdt--readme-teamshine05-graintime.md
  ✓ copied successfully!

✅ sync complete! 1 file mirrored, 0 collisions
```

### error on invalid grainbranch

```bash
$ steel grainmirror.scm config set-destination \
  "https://github.com/kae3g/teamkae3gtravel12/tree/main"

❌ error: invalid grainbranch URL!

destination URL must include a valid grainbranch:
  format: YYYYY-MM-DD--HHMM-TZ--moon-NAKSHATRA-asc-SIGNXX-sun-XXh--TEAM
  
  your URL: https://github.com/kae3g/teamkae3gtravel12/tree/main
  branch: main ← not a valid grainbranch!

valid example:
  https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12

hint: grainbranches encode astronomical data. regular branch names
      like 'main' or 'master' won't work with grainmirror!
```

---

## 💡 why this design?

### explicit configuration

**problem**: typing long URLs every time is error-prone  
**solution**: set once in config, use forever

### validation first

**problem**: invalid destinations cause silent failures  
**solution**: validate grainbranch format before any operation

### collision detection

**problem**: multiple files can have same grainorder from different sources  
**solution**: scan entire destination, assign next smallest available

### carry logic

**problem**: running out of grainorders (e.g., last char hits 'b')  
**solution**: carry left, reset right, just like subtraction!

### clear errors

**problem**: cryptic failures confuse users  
**solution**: friendly error messages with examples and hints

---

## 🎓 teaching moment: why grainbranch validation?

you might be thinking: "why do we care what branch name the destination uses? can't we just mirror to any repo?"

great question! here's why grainbranch validation matters:

### 1. temporal consistency

grainbranches encode WHEN something happened:
- date and time (holocene era)
- moon's nakshatra (vedic lunar mansion)
- ascendant (rising sign + degree)
- sun's house (time of day)

if we mirror to a repo without a grainbranch, we lose this temporal awareness. we can't answer questions like "what was the moon doing when this code was written?" or "how old is this file really?"

### 2. immutable snapshots

grainbranches are IMMUTABLE - once created, they never change. this means:
- the URL is a permanent address
- you can link to it forever
- git history stays clean

if we mirror to `main` or `master`, those branches are MUTABLE - they change constantly. your mirror could get overwritten, rebased, force-pushed, etc. not cool!

### 3. multi-repo synchronization

when ALL repos use grainbranches, we can synchronize them temporally:
- "show me all repos from this nakshatra"
- "what changed during this moon phase?"
- "compare two temporal snapshots across repos"

this only works if everyone plays by the same rules!

### 4. self-documenting URLs

look at this URL:
```
https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12
```

without clicking, you already know:
- when it was created (oct 28, 12025 at 11:30 PDT)
- what the moon was doing (uttara ashadha nakshatra)
- what was rising (aries 23°)
- what time of day (12th solar house)
- whose perspective (teamtravel12)

that's beautiful! it's self-documenting. regular branch names like `main` tell you nothing.

does this make sense? we validate grainbranches because they're not just branch names - they're temporal addresses, immutable snapshots, and self-documenting contexts all rolled into one! 🌾⚡

---

## 🔮 future enhancements

### automatic grainbranch detection

```steel
;; detect current grainbranch from git
(define (current-grainbranch)
  (let ([branch (command "git branch --show-current")])
    (if (valid-grainbranch? branch)
        branch
        (error "not on a grainbranch! create one first."))))
```

### multi-destination sync

```steel
;; sync to multiple destinations at once
(grainmirror-sync 
  :sources ["readme.md"]
  :destinations [
    "teamkae3gtravel12"
    "teamtravel12"
    "grainkae3g"])
```

### git integration

```steel
;; auto-commit after sync
(grainmirror-sync 
  :auto-commit #t
  :commit-message "🪞⚡ grainmirror sync - {timestamp}")
```

### webhook triggers

```steel
;; sync when source file changes (filesystem watch)
(grainmirror-watch 
  :sources ["readme.md"]
  :on-change sync-all)
```

---

## 🌊 philosophical note

why are we being so careful about collisions and validation?

because **grainmirror is about conscious duplication**. we're not symlinking (invisible, magical). we're not using git submodules (complex, fragile). we're making HARD COPIES on purpose!

with hard copies, we need to be thoughtful:
- where do they live?
- how do we name them?
- what happens when names collide?
- how do we keep them in sync?

these questions have ANSWERS, not workarounds. that's what this config system provides - clear answers to clear questions.

it's like the difference between:
- **throwing clothes on the floor** (symlinks)
- **having a closet organizer** (grainmirror with config)

both store your clothes, but only one makes you feel calm when you open the door! 🌾✨

---

## 📊 status

**this document**: design specification (phase 1 complete!)  
**implementation**: phases 2-6 in progress  
**testing**: coming soon  
**deployment**: after testing passes

---

## 🔗 related

**grainorder**: https://github.com/teamtreasure02/grainorder  
**graintime**: https://github.com/teamshine05/graintime  
**grainmirror**: https://github.com/teamshine05/graintime (this module!)  
**grain-specs**: https://github.com/teamshine05/graintime/grain-specs.scm

**personal hub**: https://github.com/kae3g/teamkae3gtravel12  
**org mirror**: https://github.com/teamtravel12/teamtravel12

---

**grainorder**: xzvskd  
**timestamp**: 12025-10-28--1505-pdt  
**author**: kae3g (@risc.love, kj3x39)  
**team**: teamshine05 (leo ♌ / V. the hierophant - knowledge systems)  
**voice**: glow g2 (patient listening teacher)

*now == next + 1* 🌾

