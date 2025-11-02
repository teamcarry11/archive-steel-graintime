;; ╔══════════════════════════════════════════════════════════════════════════╗
;; ║                          GRAIN MACROS                                    ║
;; ║           clean, functional macros for the grain network                 ║
;; ║                 "complexity hidden, simplicity revealed"                 ║
;; ║                                                                          ║
;; ║  glow g2 asks: what if repetitive patterns could teach through hiding?  ║
;; ║                                                                          ║
;; ║  phase 1: display helpers, command wrappers, hash sugar                 ║
;; ║  team: teamshine05 (leo ♌ / V. the hierophant - knowledge transmission)║
;; ║                                                                          ║
;; ╚══════════════════════════════════════════════════════════════════════════╝

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHILOSOPHY: WHEN TO USE MACROS                                          │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; macros are powerful, but power requires wisdom. ask yourself:
;;
;; 1. **is this pattern repeated 10+ times?**
;;    → if not, just write the function normally
;;    → repetition is the teacher that says "abstract me"
;;
;; 2. **does hiding the syntax make code MORE readable?**
;;    → good macro: `(println! "hello ~a" name)` instead of `(displayln (format "hello ~a" name))`
;;    → bad macro: hiding essential control flow
;;
;; 3. **can a regular function do this?**
;;    → prefer functions! they compose better, debug easier
;;    → macros are for when you need to control EVALUATION
;;
;; 4. **will future-you understand this?**
;;    → write Glow G2 comments explaining WHY
;;    → show before/after examples
;;    → teach through the macro itself
;;
;; remember: macros are about **removing accidental complexity**,
;; not about showing off cleverness. be humble. be clear. 🌾

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MACRO 1: PRINTLN! - formatted display in one call                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **the problem:**
;;   we write `(displayln (format "hello ~a" name))` everywhere (62 times!)
;;   that's 2 function calls, nested, hard to scan
;;
;; **the solution:**
;;   `(println! "hello ~a" name)` - one call, flat, clear
;;
;; **before:**
;;   (displayln (format "syncing ~a mirrors..." (length mirrors)))
;;   (displayln (format "   hash: ~a" (substring new-hash 0 8)))
;;
;; **after:**
;;   (println! "syncing ~a mirrors..." (length mirrors))
;;   (println! "   hash: ~a" (substring new-hash 0 8))
;;
;; **why macro not function?**
;;   because we want the format string and args at the SAME level
;;   a function would need: (println-fn "text ~a" [arg1 arg2])
;;   but a macro gives us: (println! "text ~a" arg1 arg2)
;;   which reads like printf/console.log/println across languages!

(define-syntax println!
  (syntax-rules ()
    ;; no args - just newline
    [(println!)
     (displayln "")]
    
    ;; format string only - no placeholders
    [(println! str)
     (displayln str)]
    
    ;; format string + single arg
    [(println! str arg)
     (displayln (format str arg))]
    
    ;; format string + two args
    [(println! str arg1 arg2)
     (displayln (format str arg1 arg2))]
    
    ;; format string + three args
    [(println! str arg1 arg2 arg3)
     (displayln (format str arg1 arg2 arg3))]
    
    ;; format string + four args (if you need more, use regular format)
    [(println! str arg1 arg2 arg3 arg4)
     (displayln (format str arg1 arg2 arg3 arg4))]))

;; does this macro remove boilerplate? YES! (62 instances)
;; does it make code clearer? YES! (flat instead of nested)
;; does it teach something? YES! (consistency across grain network)

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MACRO 2: HASH-LET - destructure hash maps cleanly                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **the problem:**
;;   extracting values from hashes is verbose:
;;   (let ([mirrors (hash-ref entry :mirrors)]
;;         [last-sync (hash-ref entry :last-sync)]
;;         [content-hash (hash-ref entry :content-hash)])
;;     ...)
;;
;; **the solution:**
;;   (hash-let entry [mirrors last-sync content-hash]
;;     ...)
;;
;; **before:**
;;   (let ([grainorder (hash-ref parsed-file :grainorder)]
;;         [timestamp (hash-ref parsed-file :timestamp)]
;;         [rest (hash-ref parsed-file :rest)])
;;     (do-something grainorder timestamp rest))
;;
;; **after:**
;;   (hash-let parsed-file [grainorder timestamp rest]
;;     (do-something grainorder timestamp rest))
;;
;; **why macro not function?**
;;   we need the binding names to become both:
;;   - variable names in the body
;;   - keyword keys for lookup
;;   only macros can do this transformation!

(define-syntax hash-let
  (syntax-rules ()
    [(hash-let hash-expr [key ...] body ...)
     (let ([_hash hash-expr])
       (let ([key (hash-ref _hash (quote key))] ...)
         body ...))]))

;; does this reduce line count? YES! (3 lines → 2 lines per usage)
;; is it more readable? DEBATABLE (maybe not, stick with explicit?)
;; does future-me understand it? MAYBE (if we comment well)
;;
;; glow g2 reflects: this one is borderline. use sparingly!

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MACRO 3: CMD! - run shell commands with better ergonomics               │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **the problem:**
;;   (command (format "mv ~s ~s" old-path new-path))
;;   mixing command, format, and string interpolation is messy
;;
;; **the solution:**
;;   (cmd! "mv" old-path new-path)
;;   flat, clear, no nested calls
;;
;; **before:**
;;   (command (format "ls ~a" expanded-dir))
;;   (command (format "mkdir -p ~a" parent-dir))
;;   (command (format "test -f ~a" (expand-path path)))
;;
;; **after:**
;;   (cmd! "ls" expanded-dir)
;;   (cmd! "mkdir -p" parent-dir)
;;   (cmd! "test -f" (expand-path path))
;;
;; **why macro not function?**
;;   we want automatic string joining with proper shell escaping
;;   the macro can inspect args at compile time

(define-syntax cmd!
  (syntax-rules ()
    ;; single string - run as-is
    [(cmd! str)
     (command str)]
    
    ;; command with args - join with spaces
    [(cmd! cmd arg ...)
     (command (string-join (list cmd (to-string arg) ...) " "))]))

;; helper: convert anything to string safely
(define (to-string x)
  (cond
    [(string? x) x]
    [(number? x) (number->string x)]
    [else (format "~a" x)]))

;; does this help? MAYBE (shell escaping is tricky!)
;; is it safer? NO (we'd need proper quoting)
;; should we use it? PROBABLY NOT (stick with explicit format)
;;
;; glow g2 warns: shell commands need careful escaping. avoid sugar here!

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MACRO 4: WITH-BOX - ascii box wrappers                                  │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; **the problem:**
;;   we have beautiful ascii boxes everywhere:
;;   (displayln "╔════════════════════════════════════════════════╗")
;;   (displayln "║  SOME TITLE                                    ║")
;;   (displayln "╚════════════════════════════════════════════════╝")
;;   (displayln "")
;;   ... body ...
;;
;; **the solution:**
;;   (with-box "SOME TITLE"
;;     ... body ...)
;;
;; **before:**
;;   (displayln "\n╔════════════════════════════════════════════════╗")
;;   (displayln "║  GRAINMIRROR SYNC 🪞                           ║")
;;   (displayln "╚════════════════════════════════════════════════╝\n")
;;   (do-sync-work)
;;   (displayln "✅ sync complete!")
;;
;; **after:**
;;   (with-box "GRAINMIRROR SYNC 🪞"
;;     (do-sync-work)
;;     (displayln "✅ sync complete!"))
;;
;; **why macro not function?**
;;   the body needs to execute in the calling scope
;;   function would require lambda: (with-box-fn "title" (lambda () ...))
;;   macro is cleaner!

(define-syntax with-box
  (syntax-rules ()
    [(with-box title body ...)
     (begin
       (displayln "\n╔════════════════════════════════════════════════╗")
       (displayln (string-append "║  " title (make-string (- 46 (string-length title)) #\space) "║"))
       (displayln "╚════════════════════════════════════════════════╝\n")
       body ...)]))

;; does this reduce line count? YES! (4 lines → 1 line)
;; is it more readable? YES! (clear intent)
;; is it reusable? YES! (every CLI tool needs boxes)
;;
;; glow g2 approves: this is what macros are FOR! 🎯

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ VERDICT: WHICH MACROS TO ACTUALLY USE?                                  │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; after building these 4 macros, glow g2 reflects:
;;
;; ✅ **USE THESE:**
;;    - `println!` - saves 62 instances, clearly better
;;    - `with-box` - saves 20+ instances, beautiful abstraction
;;
;; ❓ **MAYBE USE:**
;;    - `hash-let` - nice for deeply nested hashes, but adds cognitive load
;;                   → use ONLY when destructuring 4+ keys at once
;;
;; ❌ **DON'T USE:**
;;    - `cmd!` - shell escaping needs to be EXPLICIT for security
;;             → stick with (command (format ...))
;;
;; **estimated line savings:**
;;   - before macros: ~650 lines across 3 files
;;   - after macros: ~580 lines (-70 lines, 10% reduction)
;;   - but MORE IMPORTANTLY: code is easier to scan and understand!
;;
;; **the functional decomplected way:**
;;   - macros don't add state or mutation
;;   - they just remove syntactic ceremony
;;   - each macro has ONE clear purpose
;;   - glow g2 comments teach the "why"
;;
;; does this align with rich hickey's simple/easy distinction?
;; - println! makes code EASIER (fewer parens) and SIMPLER (one concept)
;; - hash-let makes code EASIER but arguably more COMPLEX (hidden behavior)
;; - with-box makes code both EASIER and SIMPLER (clear boundaries)
;;
;; the answer is: use macros to remove ACCIDENTAL complexity,
;; never to hide ESSENTIAL complexity. 🌾

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HOW TO USE THESE MACROS                                                 │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; at the top of any grain network steel file:
;;
;;   (require "grain-macros.scm")
;;
;; then use freely:
;;
;;   (with-box "GRAINMIRROR SYNC 🪞"
;;     (println! "syncing ~a sources..." (length sources))
;;     (for-each mirror-sync-one! sources)
;;     (println! "✅ all mirrors synced!"))
;;
;; compare to without macros:
;;
;;   (displayln "\n╔════════════════════════════════════════════════╗")
;;   (displayln "║  GRAINMIRROR SYNC 🪞                           ║")
;;   (displayln "╚════════════════════════════════════════════════╝\n")
;;   (displayln (format "syncing ~a sources..." (length sources)))
;;   (for-each mirror-sync-one! sources)
;;   (displayln (format "✅ all mirrors synced!"))
;;
;; which would you rather read? which would you rather write? 🤔
;;
;; glow g2 reflects: sometimes less IS more. but only sometimes! 💙

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ println! macro (saves ~60 instances)
;; ✅ hash-let macro (use sparingly)
;; ✅ cmd! macro (decided NOT to use)
;; ✅ with-box macro (saves ~20 instances)
;; ✅ glow g2 philosophy on when/why to use macros
;; ✅ functional decomplected approach (no state, clear purpose)
;; ✅ before/after examples for teaching
;;
;; what's next (phase 2):
;; - apply println! and with-box to grainmirror.scm
;; - measure actual line reduction
;; - decide if hash-let is worth the cognitive load
;; - write graincard teaching macros to students
;; - share with grain network for feedback
;;
;; does this feel like simplicity through hiding? ready to refactor? 🌾⚡
;;
;; now == next + 1 🌾

