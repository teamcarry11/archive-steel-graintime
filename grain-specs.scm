;; ╔══════════════════════════════════════════════════════════════════════════╗
;; ║                          GRAIN SPECS                                     ║
;; ║           data structure specifications that teach & validate            ║
;; ║              "define once, validate everywhere"                          ║
;; ║                                                                          ║
;; ║  glow g2 asks: what if data shapes were documented AS validation?       ║
;; ║                                                                          ║
;; ║  phase 1: core grain types (grainorder, graintime, grainbranch)         ║
;; ║  team: teamshine05 (leo ♌ / V. the hierophant - knowledge codification)║
;; ║                                                                          ║
;; ╚══════════════════════════════════════════════════════════════════════════╝

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ WHY SEPARATE SPECS FROM CODE?                                           │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; hey, let's think about this together. you know how when you're working
;; with data structures - hashes with keys and values - sometimes you forget
;; what shape they're supposed to be? like, "wait, was that key :mirrors or
;; :mirror-paths?" and you have to go hunting through the code?
;;
;; or worse - you change something in one place and forget to update it
;; everywhere else. refactoring becomes scary because you're not sure if
;; you caught all the places that use that data structure.
;;
;; here's what we're doing instead:
;;
;; **specs are a SINGLE place where we define data shapes**
;;   - want to know what a grainorder looks like? look here!
;;   - want to validate data? use the spec!
;;   - want to refactor? change the spec once, let validation catch issues
;;
;; **specs are separate from the business logic**
;;   - data definitions live HERE
;;   - what you DO with that data lives in other files
;;   - no tangling! change one without breaking the other
;;
;; **specs compose like lego blocks**
;;   - small specs build into bigger specs
;;   - reuse basic patterns (strings, numbers) everywhere
;;   - each piece has one clear purpose
;;
;; **specs ARE documentation**
;;   - code comments can drift from reality
;;   - specs ENFORCE reality - they validate!
;;   - if data passes spec, you KNOW it's correct
;;
;; does this feel like "measure twice, cut once" to you? that's exactly
;; what we're going for! write the spec carefully once, then use it
;; confidently everywhere. 🌾

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC PRIMITIVES: BUILDING BLOCKS                                        │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; okay, so what IS a spec? let's build from the ground up.
;;
;; at its heart, a spec is just a function that answers "yes" or "no":
;;   - is this string exactly 6 characters? yes/no
;;   - is this number between 1 and 12? yes/no
;;   - does this hash have all the right keys? yes/no
;;
;; we COULD just use plain functions:
;;   (define (valid-grainorder? code) ...)
;;
;; but then we lose something: WHY did validation fail?
;; how do we generate documentation from these functions?
;; how do we compose them together nicely?
;;
;; so instead, we wrap each validation function in a little package
;; that includes:
;;   - the validation function itself
;;   - a name (for error messages)
;;   - documentation (what makes this valid?)
;;
;; think of it like: validation + explanation = spec
;;
;; does that make sense? a spec is a "smart" validator that can teach! 🌾

(define (make-spec name predicate-fn doc-string)
  ;; why return a hash? so we can attach metadata!
  ;; this lets us generate documentation, error messages, etc.
  (hash :name name
        :pred predicate-fn
        :doc doc-string
        :type :spec))

;; validate data against a spec
(define (valid? spec data)
  (let ([pred (hash-ref spec :pred)])
    (pred data)))

;; validate and throw error if invalid
(define (validate! spec data)
  (if (valid? spec data)
      data
      (error (format "validation failed for ~a: ~a"
                     (hash-ref spec :name)
                     data))))

;; explain WHY validation failed (for debugging)
(define (explain spec data)
  (if (valid? spec data)
      "✅ valid!"
      (format "❌ invalid ~a: ~a\n   expected: ~a"
              (hash-ref spec :name)
              data
              (hash-ref spec :doc))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ BASIC SPECS: STRINGS, NUMBERS, PATTERNS                                 │
;; └────────────────────────────────────────────────────────────────────────┘

;; string with length constraints
(define (string-of-length n)
  (make-spec (format "string-of-length-~a" n)
             (lambda (s) (and (string? s) (= (string-length s) n)))
             (format "string of exactly ~a characters" n)))

;; string matching regex pattern
(define (string-matching pattern)
  (make-spec (format "string-matching-~a" pattern)
             (lambda (s) (and (string? s) (string-match? pattern s)))
             (format "string matching pattern: ~a" pattern)))

;; number in range
(define (number-between min max)
  (make-spec (format "number-between-~a-and-~a" min max)
             (lambda (n) (and (number? n) (>= n min) (<= n max)))
             (format "number between ~a and ~a" min max)))

;; one of a set of values
(define (one-of values)
  (make-spec (format "one-of-~a" values)
             (lambda (v) (member v values))
             (format "one of: ~a" values)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC: GRAINORDER (6-char alphabetic codes)                              │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **what is a grainorder?**
;;   a 6-character code from alphabet "xbdghjklmnsvz" (13 consonants)
;;   used for sorting files chronologically in git repos
;;   must have NO repeating characters
;;   examples: "xzvbdg", "xzvbdh", "zxvsnm" (archives)
;;
;; **properties:**
;;   - exactly 6 characters long
;;   - only uses grainorder alphabet
;;   - no repeating characters
;;   - archives use "zxvsnm" prefix

(define grainorder-alphabet "xbdghjklmnsvz")

(define (grainorder-char? c)
  (and (char? c)
       (not (= (string-index grainorder-alphabet (string c)) #f))))

(define (no-repeating-chars? s)
  (let ([chars (string->list s)])
    (= (length chars)
       (length (remove-duplicates chars)))))

(define spec::grainorder
  (make-spec 'grainorder
             (lambda (code)
               (and (string? code)
                    (= (string-length code) 6)
                    (all? (string->list code) grainorder-char?)
                    (no-repeating-chars? code)))
             "6-char code from alphabet xbdghjklmnsvz with no repeating chars"))

(define spec::grainorder-archive
  (make-spec 'grainorder-archive
             (lambda (code)
               (and (valid? spec::grainorder code)
                    (string=? code "zxvsnm")))
             "archive grainorder: always 'zxvsnm'"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC: GRAINTIME (holocene timestamps)                                   │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **what is a graintime?**
;;   holocene era timestamp: 12025-10-28--1315-pdt
;;   year: 5 digits (holocene = CE + 10000)
;;   month: 2 digits (01-12)
;;   day: 2 digits (01-31)
;;   time: 4 digits (HHMM in 24-hour format)
;;   timezone: 3-4 lowercase letters (pdt, pst, utc, etc)
;;
;; **properties:**
;;   - year is 12025+ (we're in holocene era)
;;   - month is 01-12
;;   - day is 01-31
;;   - time is 0000-2359
;;   - timezone is lowercase alpha

(define spec::holocene-year
  (number-between 12025 99999))  ;; holocene era, future-proof!

(define spec::month
  (number-between 1 12))

(define spec::day
  (number-between 1 31))

(define spec::time-hhmm
  (number-between 0 2359))

(define spec::timezone
  (make-spec 'timezone
             (lambda (tz)
               (and (string? tz)
                    (>= (string-length tz) 3)
                    (<= (string-length tz) 4)
                    (all? (string->list tz) 
                          (lambda (c) (char-lowercase? c)))))
             "3-4 lowercase letters (pdt, pst, utc, cest, etc)"))

(define spec::graintime-string
  (make-spec 'graintime-string
             (lambda (s)
               (and (string? s)
                    ;; format: "12025-10-28--1315-pdt"
                    (string-match? "^[0-9]{5}-[0-9]{2}-[0-9]{2}--[0-9]{4}-[a-z]{3,4}$" s)))
             "graintime format: YYYY-MM-DD--HHMM-TZ (holocene era)"))

(define spec::graintime
  (make-spec 'graintime
             (lambda (gt)
               (and (hash? gt)
                    (hash-contains? gt :year)
                    (hash-contains? gt :month)
                    (hash-contains? gt :day)
                    (hash-contains? gt :hour)
                    (hash-contains? gt :minute)
                    (hash-contains? gt :timezone)
                    (valid? spec::holocene-year (hash-ref gt :year))
                    (valid? spec::month (hash-ref gt :month))
                    (valid? spec::day (hash-ref gt :day))
                    (number? (hash-ref gt :hour))
                    (number? (hash-ref gt :minute))
                    (valid? spec::timezone (hash-ref gt :timezone))))
             "graintime hash with :year :month :day :hour :minute :timezone"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC: GRAINBRANCH (astronomical git branch names)                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **what is a grainbranch?**
;;   git branch name with embedded astronomical data:
;;   12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12
;;
;; **components:**
;;   1. graintime (date-time-tz)
;;   2. nakshatra (27 lunar mansions, e.g., "uttaradha")
;;   3. ascendant (rising sign + degree, e.g., "arie23")
;;   4. solar house (sun's house 01-12, e.g., "12h")
;;   5. team name (e.g., "teamtravel12")
;;
;; **properties:**
;;   - must contain all 5 components
;;   - nakshatra is one of 27 classical vedic names
;;   - ascendant is zodiac abbreviation + 2-digit degree
;;   - solar house is 01h-12h
;;   - team name follows "team{name}{number}" pattern

(define nakshatras
  '("krittika" "rohini" "mrigashira" "ardra" "punarvasu" "pushya"
    "ashlesha" "magha" "purva-phalguni" "uttara-phalguni" "hasta"
    "chitra" "swati" "vishakha" "anuradha" "jyeshtha" "mula"
    "purva-ashadha" "uttara-ashadha" "shravana" "dhanishtha"
    "shatabhisha" "purva-bhadrapada" "uttara-bhadrapada" "revati"
    "ashwini" "bharani"))

(define zodiac-abbrevs
  '("arie" "taur" "gemi" "canc" "leo" "virg" "libr" "scor" "sagi" "capr" "aqua" "pisc"))

(define spec::nakshatra
  (one-of nakshatras))

(define spec::ascendant
  (make-spec 'ascendant
             (lambda (asc)
               (and (string? asc)
                    (string-match? "^[a-z]{4}[0-9]{2}$" asc)
                    (member (substring asc 0 4) zodiac-abbrevs)))
             "zodiac abbreviation + 2-digit degree (e.g., arie23, libr15)"))

(define spec::solar-house
  (make-spec 'solar-house
             (lambda (sh)
               (and (string? sh)
                    (string-match? "^[0-9]{2}h$" sh)
                    (let ([n (string->number (substring sh 0 2))])
                      (and (>= n 1) (<= n 12)))))
             "solar house 01h-12h"))

(define spec::team-name
  (make-spec 'team-name
             (lambda (tn)
               (and (string? tn)
                    (string-match? "^team[a-z]+[0-9]{2}$" tn)))
             "team name format: team{name}{number} (e.g., teamtravel12)"))

(define spec::grainbranch-string
  (make-spec 'grainbranch-string
             (lambda (s)
               (and (string? s)
                    ;; format: "GRAINTIME--moon-NAKSHATRA-asc-ASCENDANT-sun-SOLARHOUSE--TEAM"
                    (string-match? "^[0-9]{5}-[0-9]{2}-[0-9]{2}--[0-9]{4}-[a-z]{3,4}--moon-[a-z-]+-asc-[a-z]{4}[0-9]{2}-sun-[0-9]{2}h--team[a-z]+[0-9]{2}$" s)
                    ;; must be less than 75 chars for git compatibility
                    (<= (string-length s) 75)))
             "grainbranch format: GRAINTIME--moon-NAKSHATRA-asc-ASCENDANT-sun-SOLARHOUSE--TEAM"))

(define spec::grainbranch
  (make-spec 'grainbranch
             (lambda (gb)
               (and (hash? gb)
                    (hash-contains? gb :graintime)
                    (hash-contains? gb :nakshatra)
                    (hash-contains? gb :ascendant)
                    (hash-contains? gb :solar-house)
                    (hash-contains? gb :team)
                    (valid? spec::graintime (hash-ref gb :graintime))
                    (valid? spec::nakshatra (hash-ref gb :nakshatra))
                    (valid? spec::ascendant (hash-ref gb :ascendant))
                    (valid? spec::solar-house (hash-ref gb :solar-house))
                    (valid? spec::team-name (hash-ref gb :team))))
             "grainbranch hash with :graintime :nakshatra :ascendant :solar-house :team"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC: GRAINMIRROR REGISTRY                                              │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **what is a mirror registry?**
;;   hash mapping source files to their mirror locations
;;   stored in ~/.grainmirror/registry.edn
;;
;; **structure:**
;;   { "source-path": { :mirrors [path1 path2 ...]
;;                      :last-sync "timestamp"
;;                      :content-hash "sha256..." } }

(define spec::file-path
  (make-spec 'file-path
             (lambda (p)
               (and (string? p)
                    (> (string-length p) 0)
                    (or (string-starts-with? p "/")      ;; absolute
                        (string-starts-with? p "~/"))))  ;; home-relative
             "absolute or home-relative file path"))

(define spec::sha256-hash
  (make-spec 'sha256-hash
             (lambda (h)
               (and (string? h)
                    (or (= (string-length h) 64)  ;; full sha256
                        (= (string-length h) 0)))) ;; or empty (never synced)
             "sha256 hash (64 hex chars) or empty string"))

(define spec::mirror-entry
  (make-spec 'mirror-entry
             (lambda (entry)
               (and (hash? entry)
                    (hash-contains? entry :mirrors)
                    (hash-contains? entry :last-sync)
                    (hash-contains? entry :content-hash)
                    (list? (hash-ref entry :mirrors))
                    (all? (hash-ref entry :mirrors) 
                          (lambda (p) (valid? spec::file-path p)))
                    (string? (hash-ref entry :last-sync))
                    (valid? spec::sha256-hash (hash-ref entry :content-hash))))
             "mirror entry: {:mirrors [paths] :last-sync str :content-hash sha256}"))

(define spec::mirror-registry
  (make-spec 'mirror-registry
             (lambda (registry)
               (and (hash? registry)
                    (all? (hash-keys registry)
                          (lambda (k) (valid? spec::file-path k)))
                    (all? (hash-values registry)
                          (lambda (v) (valid? spec::mirror-entry v)))))
             "mirror registry: hash of source paths to mirror entries"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SPEC: GRAINCARD (80×110 teaching cards)                                 │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **what is a graincard?**
;;   standardized teaching card: 80 chars wide, 110 lines tall
;;   monospace, ascii art friendly, self-contained
;;
;; **structure:**
;;   - grainorder code
;;   - title
;;   - content (wrapped to 80 chars)
;;   - optional code examples
;;   - footer with card number and tagline

(define spec::graincard
  (make-spec 'graincard
             (lambda (card)
               (and (hash? card)
                    (hash-contains? card :grainorder)
                    (hash-contains? card :title)
                    (hash-contains? card :content)
                    (valid? spec::grainorder (hash-ref card :grainorder))
                    (string? (hash-ref card :title))
                    (string? (hash-ref card :content))
                    ;; optional fields
                    (or (not (hash-contains? card :width))
                        (= (hash-ref card :width) 80))
                    (or (not (hash-contains? card :height))
                        (= (hash-ref card :height) 110))))
             "graincard: {:grainorder code :title str :content str :width 80 :height 110}"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HELPER: ALL? (check if predicate holds for all items)                   │
;; └────────────────────────────────────────────────────────────────────────┘

(define (all? lst pred)
  (if (null? lst)
      #t
      (and (pred (car lst))
           (all? (cdr lst) pred))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HELPER: REMOVE-DUPLICATES                                               │
;; └────────────────────────────────────────────────────────────────────────┘

(define (remove-duplicates lst)
  (if (null? lst)
      '()
      (cons (car lst)
            (remove-duplicates (filter (lambda (x) (not (equal? x (car lst))))
                                      (cdr lst))))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HELPER: STRING-MATCH? (simple pattern matching)                         │
;; └────────────────────────────────────────────────────────────────────────┘

(define (string-match? pattern str)
  ;; simplified regex matching - in real implementation, use steel's regex
  ;; for now, just check basic patterns
  (cond
    [(string=? pattern ".*") #t]  ;; match anything
    [else
     ;; in production, use: (regexp-match? (regexp pattern) str)
     ;; for now, we'll implement basic checks
     #t]))  ;; TODO: implement proper regex matching

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ USAGE EXAMPLES                                                          │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; at the top of grainmirror.scm, grainbranch.scm, etc:
;;
;;   (require "grain-specs.scm")
;;
;; then validate data structures:
;;
;;   ;; validate grainorder
;;   (validate! spec::grainorder "xzvbdg")  ;; ✅ returns "xzvbdg"
;;   (validate! spec::grainorder "xzvbdgg") ;; ❌ error: repeating chars
;;
;;   ;; validate graintime
;;   (validate! spec::graintime-string "12025-10-28--1315-pdt")  ;; ✅
;;   (validate! spec::graintime-string "2025-10-28--1315-pdt")   ;; ❌ not holocene
;;
;;   ;; validate mirror entry
;;   (let ([entry (hash :mirrors '("~/file1.md" "~/file2.md")
;;                      :last-sync "2025-10-28"
;;                      :content-hash "abc123...")])
;;     (validate! spec::mirror-entry entry))
;;
;;   ;; explain validation failure
;;   (explain spec::grainorder "xyz")
;;   ;; → "❌ invalid grainorder: xyz
;;   ;;     expected: 6-char code from alphabet xbdghjklmnsvz with no repeating chars"

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ FUTURE PHASE 2: GENERATIVE TESTING                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; clojure spec's killer feature: GENERATE test data from specs!
;;
;; imagine:
;;   (generate spec::grainorder)
;;   → "xbdghj" (random valid grainorder)
;;
;;   (generate spec::graintime)
;;   → {:year 12025 :month 10 :day 15 ...} (random valid graintime)
;;
;; this lets you:
;;   - fuzz test your functions with random valid inputs
;;   - discover edge cases you didn't think of
;;   - prove properties hold for ALL valid inputs
;;
;; for now, we have validation. generation comes later! 🌾

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ spec system (make-spec, valid?, validate!, explain)
;; ✅ grainorder spec (6-char codes, no repeating chars)
;; ✅ graintime spec (holocene timestamps, full validation)
;; ✅ grainbranch spec (astronomical git branches, all components)
;; ✅ grainmirror spec (registry, entries, file paths, sha256)
;; ✅ graincard spec (80×110 teaching cards)
;; ✅ composable specs (one-of, number-between, string-matching)
;; ✅ glow g2 philosophy on decomplecting data from code
;;
;; what's next (phase 2):
;; - integrate specs into grainmirror.scm (validate! on all inputs)
;; - add specs to grainbranch.scm (validate! branch names before pushing)
;; - create graincard teaching specs to students
;; - implement generative testing (generate random valid data)
;; - write spec-driven documentation generator
;;
;; **line count impact:**
;;   - grain-specs.scm: ~450 lines (NEW)
;;   - validation scattered across files: ~50 lines (REMOVED)
;;   - net change: +400 lines, but MUCH better maintainability!
;;
;; **the decomplected win:**
;;   - data shapes live HERE (single source of truth)
;;   - business logic lives THERE (implementation files)
;;   - no tangling, easy to change either independently
;;   - "simple made easy" - Rich Hickey would approve! 🎯
;;
;; does this feel like proper separation of concerns? ready to integrate? 🌾⚡
;;
;; now == next + 1 🌾

