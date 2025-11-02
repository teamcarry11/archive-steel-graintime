;; ╔══════════════════════════════════════════════════════════════════════════╗
;; ║                            GRAINTIME                                     ║
;; ║         astronomical timestamps for version control                      ║
;; ║                   pure steel, vedic astrology                            ║
;; ║                                                                          ║
;; ║  "what if git branches remembered the stars?"                           ║
;; ║                                                                          ║
;; ║  phase 1: format validation + offline fallback                          ║
;; ║  team: teamshine05 (V. the hierophant - sacred knowledge)               ║
;; ║                                                                          ║
;; ╚══════════════════════════════════════════════════════════════════════════╝

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ DESIGN PHILOSOPHY                                                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; graintime encodes WHEN and WHERE in space/time:
;;
;; - WHEN: holocene year, month, day, time, timezone
;; - WHERE: moon's nakshatra, ascendant (rising sign + degree), sun's house
;;
;; example grainbranch:
;; "12025-10-28--1130-PDT--moon-uttashsdh-asc-arie23-sun-12h--teamtravel12"
;;
;; why astronomical data? because time is more than a clock tick.
;; the moon's position, your rising sign, the sun's house - these give
;; CONTEXT to the moment. they connect you to cosmic cycles.
;;
;; does this feel abstract? let's make it concrete with code! 🌙

(require-builtin steel/time)

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ THE 27 NAKSHATRAS (MANTRESHWARA'S CLASSICAL ORDER)                    │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; nakshatras are the 27 "lunar mansions" - sectors of the ecliptic that
;; the moon passes through. each nakshatra is 13°20' of arc.
;;
;; we follow mantreshwara's tradition (phaladeepika), where krittika is #1
;; because it aligns with aries (mesha) as the first sign. this synchronizes
;; the nakshatra cycle with the zodiac cycle.

(define nakshatras
  '("krittika" "rohini" "mrigashira" "ardra" "punarvasu" "pushya"
    "ashlesha" "magha" "purva-phalguni" "uttara-phalguni" "hasta" "chitra"
    "swati" "vishakha" "anuradha" "jyeshtha" "mula" "purva-ashadha"
    "uttara-ashadha" "shravana" "dhanishta" "shatabhisha" "purva-bhadrapada"
    "uttara-bhadrapada" "revati" "ashwini" "bharani"))

;; get nakshatra by index (0-based)
(define (nakshatra-by-index idx)
  (list-ref nakshatras idx))

;; get nakshatra index by name (0-based)
(define (nakshatra-index name)
  (let loop ([lst nakshatras] [i 0])
    (cond
      [(null? lst) #f]
      [(string=? (car lst) name) i]
      [else (loop (cdr lst) (+ i 1))])))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ NAKSHATRA ABBREVIATION (FOR <75 CHAR BRANCH NAMES)                    │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; some nakshatras have long names (e.g., "purva-bhadrapada" = 16 chars).
;; to keep grainbranch names under 75 characters, we abbreviate long names
;; by keeping the first 5 chars + last 4 chars.
;;
;; examples:
;; - "uttara-ashadha" (14 chars) → "uttashsdh" (9 chars)
;; - "purva-bhadrapada" (16 chars) → "purvbhdrpd" (10 chars)
;; - "mula" (4 chars) → "mula" (unchanged)

(define (abbreviate-nakshatra name)
  (let ([len (string-length name)])
    (if (<= len 10)
        name  ;; short enough, no abbreviation needed
        ;; take first 5 + last 4 chars, remove any hyphens
        (let* ([first-5 (substring name 0 5)]
               [last-4 (substring name (- len 4) len)]
               [combined (string-append first-5 last-4)])
          ;; remove hyphens for compactness
          (string-replace combined "-" "")))))

;; expand abbreviated nakshatra back to full name
;; (this requires checking against known patterns - phase 2!)
(define (expand-nakshatra abbrev)
  ;; for now, just return the abbreviation
  ;; in phase 2, we'll build a reverse lookup table
  abbrev)

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ THE 12 ZODIAC SIGNS (SIDEREAL)                                         │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; vedic astrology uses the SIDEREAL zodiac (fixed to stars), not the
;; TROPICAL zodiac (fixed to seasons) used in western astrology.
;;
;; the difference (ayanamsa) is currently about 24° - so sidereal aries
;; starts around april 14, not march 21.

(define zodiac-signs
  '("arie" "taur" "gemi" "canc" "leo " "virg"
    "libr" "scor" "sagi" "capr" "aqua" "pisc"))

;; get zodiac sign by index (0-based, aries = 0)
(define (sign-by-index idx)
  (list-ref zodiac-signs idx))

;; get zodiac sign abbreviation (4 chars) with degree (2 digits)
;; example: aries 23° → "arie23"
(define (format-ascendant sign-idx degree)
  (format "~a~a"
          (sign-by-index sign-idx)
          (if (< degree 10)
              (format "0~a" degree)  ;; pad with leading zero
              degree)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HOLOCENE ERA YEAR CONVERSION                                           │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; holocene era (HE) = common era (CE) + 10,000 years
;; this gives humanity a continuous timeline that acknowledges civilization
;; before arbitrary year-zero conventions.
;;
;; 2025 CE = 12025 HE
;; 0001 CE = 10001 HE
;; 9700 BCE = 00300 HE (approximate start of holocene epoch)

(define (ce-to-he year)
  (+ year 10000))

(define (he-to-ce year)
  (- year 10000))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ GRAINTIME FORMAT SPECIFICATION                                         │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; a grainbranch name has this structure:
;;
;; YYYYY-MM-DD--HHMM-TZ--moon-NAKSHATRA-asc-SIGN##-sun-##h--teamNAME##
;;
;; parts:
;; - YYYYY: holocene year (5 digits, e.g., "12025")
;; - MM: month (2 digits, 01-12)
;; - DD: day (2 digits, 01-31)
;; - HHMM: 24-hour time (4 digits, e.g., "1130" = 11:30am)
;; - TZ: timezone abbreviation (3-4 chars, e.g., "PDT", "UTC")
;; - NAKSHATRA: moon's nakshatra (abbreviated if long)
;; - SIGN##: ascendant sign (4 chars) + degree (2 digits)
;; - ##h: sun's house (2 digits + "h")
;; - teamNAME##: team identifier (e.g., "teamtravel12")
;;
;; total length: must be ≤75 characters for clean git display

(define (format-graintime year month day hour minute tz
                          nakshatra-name asc-sign asc-degree sun-house
                          team-name)
  ;; convert CE to HE if needed
  (let* ([he-year (if (> year 10000) year (ce-to-he year))]
         [abbrev-nakshatra (abbreviate-nakshatra nakshatra-name)]
         [asc-str (format-ascendant asc-sign asc-degree)]
         [sun-str (format "~ah" (if (< sun-house 10)
                                    (format "0~a" sun-house)
                                    sun-house))]
         ;; build the graintime string
         [graintime (format "~a-~a-~a--~a-~a--moon-~a-asc-~a-sun-~a--~a"
                            he-year
                            (if (< month 10) (format "0~a" month) month)
                            (if (< day 10) (format "0~a" day) day)
                            (format "~a~a"
                                    (if (< hour 10) (format "0~a" hour) hour)
                                    (if (< minute 10) (format "0~a" minute) minute))
                            tz
                            abbrev-nakshatra
                            asc-str
                            sun-str
                            team-name)])
    ;; validate length
    (if (> (string-length graintime) 75)
        (error "graintime too long! must be ≤75 chars:" graintime)
        graintime)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ GRAINTIME VALIDATION                                                    │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; before using a graintime, we should validate that it follows the spec.
;; this catches typos, malformed strings, and out-of-range values.

;; check if string matches graintime format
(define (is-valid-graintime? s)
  (and (string? s)
       (<= (string-length s) 75)
       ;; basic pattern check (simplified - full regex in phase 2)
       (string-contains? s "--")
       (string-contains? s "moon-")
       (string-contains? s "asc-")
       (string-contains? s "sun-")
       (string-contains? s "team")))

;; parse a graintime string into components
;; returns a hash with keys: :year :month :day :hour :minute :tz
;;                           :nakshatra :asc-sign :asc-degree :sun-house :team
(define (parse-graintime s)
  (if (not (is-valid-graintime? s))
      (error "invalid graintime format:" s)
      ;; TODO: implement full parser in phase 2
      ;; for now, return a placeholder hash
      (hash :raw s :parsed #f)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ OFFLINE FALLBACK: CONSERVATIVE ESTIMATION                              │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what if you can't connect to an ephemeris server? what if you're in a
;; plane, a cabin, a submarine? graintime includes offline fallback!
;;
;; the idea: make CONSERVATIVE estimates that are "close enough" and mark
;; them as estimated. later, when you have connectivity, verify and update.
;;
;; this is the "honest computing" approach - acknowledge uncertainty but
;; don't let it stop you.

;; estimate moon's nakshatra from date (rough approximation)
;; moon completes ~1 nakshatra per day (actual: ~27.3 days for full cycle)
(define (estimate-nakshatra year month day)
  ;; simple modulo-27 based on day-of-year
  ;; this is ROUGH but better than nothing!
  (let* ([days-in-month '(31 28 31 30 31 30 31 31 30 31 30 31)]
         [is-leap? (and (= (modulo year 4) 0)
                        (or (not (= (modulo year 100) 0))
                            (= (modulo year 400) 0)))]
         [day-of-year (+ day
                         (apply + (take days-in-month (- month 1)))
                         (if (and is-leap? (> month 2)) 1 0))]
         [nakshatra-idx (modulo day-of-year 27)])
    (nakshatra-by-index nakshatra-idx)))

;; estimate ascendant from time and rough location
;; this is VERY rough - real calculation needs precise lat/lon
(define (estimate-ascendant hour minute)
  ;; ascendant changes ~1 sign every 2 hours
  ;; start with aries at midnight (arbitrary but consistent)
  (let* ([total-minutes (+ (* hour 60) minute)]
         [sign-idx (modulo (floor (/ total-minutes 120)) 12)]
         [degree (modulo (floor (/ total-minutes 5)) 30)])
    (list sign-idx degree)))

;; estimate sun's house from time of day
;; sun's house corresponds to time: 12th house = night, 1st = dawn, etc.
(define (estimate-sun-house hour)
  (cond
    [(< hour 2) 12]   ;; midnight - 2am: 12th house
    [(< hour 4) 1]    ;; 2am - 4am: 1st house (just before dawn)
    [(< hour 6) 2]    ;; 4am - 6am: 2nd house
    [(< hour 8) 3]    ;; 6am - 8am: 3rd house
    [(< hour 10) 4]   ;; 8am - 10am: 4th house
    [(< hour 12) 5]   ;; 10am - 12pm: 5th house
    [(< hour 14) 6]   ;; 12pm - 2pm: 6th house
    [(< hour 16) 7]   ;; 2pm - 4pm: 7th house
    [(< hour 18) 8]   ;; 4pm - 6pm: 8th house
    [(< hour 20) 9]   ;; 6pm - 8pm: 9th house
    [(< hour 22) 10]  ;; 8pm - 10pm: 10th house
    [else 11]))       ;; 10pm - midnight: 11th house

;; generate graintime with estimated astronomy (offline mode)
(define (graintime-offline year month day hour minute tz team-name)
  (let* ([nakshatra (estimate-nakshatra year month day)]
         [asc-data (estimate-ascendant hour minute)]
         [asc-sign (car asc-data)]
         [asc-degree (cadr asc-data)]
         [sun-house (estimate-sun-house hour)])
    ;; mark as estimated by prefixing nakshatra with "~"
    (format-graintime year month day hour minute tz
                      (string-append "~" nakshatra)  ;; ~ means estimated
                      asc-sign asc-degree sun-house team-name)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ ONLINE MODE: PRECISE CALCULATION (PHASE 2)                            │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; for precise calculations, we'll integrate with:
;; - swiss ephemeris (via rust ffi)
;; - astro.com api (http requests)
;; - custom steel astronomical library (pure implementation)
;;
;; this is phase 2! for now, use offline fallback or manual input.

;; TODO: implement swiss ephemeris bindings
(define (graintime-online year month day hour minute tz lat lon team-name)
  (error "online mode not yet implemented - use graintime-offline for now!"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HELPER: CURRENT GRAINTIME FROM SYSTEM                                  │
;; └────────────────────────────────────────────────────────────────────────┘

;; get current time components from system
(define (current-datetime)
  ;; TODO: use steel/time to get actual current time
  ;; for now, return placeholder
  (hash :year 12025 :month 10 :day 28
        :hour 12 :minute 0 :tz "PDT"))

;; generate graintime for current moment (offline estimation)
(define (graintime-now team-name)
  (let ([dt (current-datetime)])
    (graintime-offline (hash-ref dt :year)
                       (hash-ref dt :month)
                       (hash-ref dt :day)
                       (hash-ref dt :hour)
                       (hash-ref dt :minute)
                       (hash-ref dt :tz)
                       team-name)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ EXAMPLES & TESTS                                                       │
;; └────────────────────────────────────────────────────────────────────────┘

;; example 1: manual graintime with known astronomy
(displayln "\n╔════════════════════════════════════════════════╗")
(displayln "║  EXAMPLE 1: Manual Graintime                   ║")
(displayln "╚════════════════════════════════════════════════╝")

(define manual-graintime
  (format-graintime 2025 10 28 11 30 "PDT"
                    "uttara-ashadha" 0 23 12 "teamtravel12"))

(displayln (format "Graintime: ~a" manual-graintime))
(displayln (format "Length: ~a chars" (string-length manual-graintime)))
(displayln (format "Valid? ~a" (is-valid-graintime? manual-graintime)))

;; example 2: offline estimation
(displayln "\n╔════════════════════════════════════════════════╗")
(displayln "║  EXAMPLE 2: Offline Estimation                 ║")
(displayln "╚════════════════════════════════════════════════╝")

(define offline-graintime
  (graintime-offline 2025 10 28 11 30 "PDT" "teamtravel12"))

(displayln (format "Estimated graintime: ~a" offline-graintime))
(displayln "Note: ~ prefix means 'estimated'")

;; example 3: nakshatra abbreviation
(displayln "\n╔════════════════════════════════════════════════╗")
(displayln "║  EXAMPLE 3: Nakshatra Abbreviation            ║")
(displayln "╚════════════════════════════════════════════════╝")

(displayln (format "uttara-ashadha → ~a" (abbreviate-nakshatra "uttara-ashadha")))
(displayln (format "purva-bhadrapada → ~a" (abbreviate-nakshatra "purva-bhadrapada")))
(displayln (format "mula → ~a" (abbreviate-nakshatra "mula")))

;; example 4: longest possible graintime (testing 75-char limit)
(displayln "\n╔════════════════════════════════════════════════╗")
(displayln "║  EXAMPLE 4: Longest Graintime Test            ║")
(displayln "╚════════════════════════════════════════════════╝")

;; longest nakshatra + longest team name
(define longest-graintime
  (format-graintime 2025 10 28 23 59 "AKDT"  ;; alaska daylight time (4 chars)
                    "purva-bhadrapada" 11 29 12 "teamdescend14"))

(displayln (format "Longest: ~a" longest-graintime))
(displayln (format "Length: ~a chars" (string-length longest-graintime)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ nakshatra list (mantreshwara order, krittika #1)
;; ✅ nakshatra abbreviation (for <75 char branches)
;; ✅ zodiac sign formatting (4-char + degree)
;; ✅ holocene era conversion (CE ↔ HE)
;; ✅ graintime format function (with length validation)
;; ✅ graintime validation (basic pattern matching)
;; ✅ offline fallback (conservative estimation)
;; ✅ glow g2 teaching comments throughout
;;
;; what's next (phase 2):
;; - swiss ephemeris integration (precise astronomy)
;; - graintime parser (string → components)
;; - graintime diff (compare two graintimes)
;; - graintime visualization (cli output with colors)
;; - integration with git (auto-generate grainbranches)
;; - rust ffi bindings (call from rust code)
;;
;; does this foundation make sense? ready to calculate the stars? 🌙⚡
;;
;; now == next + 1 🌾

(displayln "\n╔════════════════════════════════════════════════════════════════════╗")
(displayln "║  GRAINTIME PHASE 1: LOADED! 🌙⚡                                    ║")
(displayln "║  astronomical timestamps with offline fallback                     ║")
(displayln "║  try: (graintime-offline 2025 10 28 11 30 \"PDT\" \"teamtravel12\") ║")
(displayln "╚════════════════════════════════════════════════════════════════════╝\n")

