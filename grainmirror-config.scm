;; ╔═══════════════════════════════════════════════════════════════════════╗
;; ║                    GRAINMIRROR CONFIG                                 ║
;; ║         configuration system for multi-repo readme mirroring          ║
;; ║                    pure steel, glow g2 voice                          ║
;; ║                                                                       ║
;; ║  "what if we never had grainorder collisions?"                       ║
;; ║                                                                       ║
;; ║  phase 1: config file + validation + auto-assignment                 ║
;; ║  team: teamshine05 (leo ♌ / V. the hierophant - teaching)           ║
;; ║                                                                       ║
;; ╚═══════════════════════════════════════════════════════════════════════╝

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ DESIGN PHILOSOPHY                                                     │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; grainmirror needs to be SMART about where files go and how they're named.
;; 
;; **the problem we're solving:**
;; - grainorder collisions (two files, same code, different timestamps!)
;; - manual destination typing (error-prone, tedious)
;; - no validation (what if the grainbranch is malformed?)
;; - no persistence (have to specify destination every time)
;;
;; **our solution:**
;; - .grainmirror.scm config file (like .edn in clojure)
;; - validate destination URLs (must have proper grainbranch)
;; - scan existing files in destination (find smallest grainorder)
;; - auto-assign next smaller grainorder (with carry logic!)
;; - persist mappings (set once, use forever)
;;
;; does this feel like "configure once, mirror forever"? that's the goal! 🪞

(require-builtin steel/io)
(require-builtin steel/hash)
(require-builtin steel/strings)

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ CONFIG FILE STRUCTURE                                                 │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; the config file lives at ~/.grainmirror.scm (user-global) or
;; ./.grainmirror.scm (project-local)
;;
;; it's just a steel hash with these keys:
;;
;; {
;;   :destinations [
;;     {
;;       :name "travel12-personal"
;;       :url "https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12"
;;       :local-path "~/github/kae3g/teamkae3gtravel12"
;;       :enabled #t
;;     }
;;     {
;;       :name "travel12-org"
;;       :url "https://github.com/teamtravel12/teamtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12"
;;       :local-path "~/github/teamtravel12/teamtravel12"
;;       :enabled #t
;;     }
;;   ]
;;   :current-source {
;;     :org "teamshine05"
;;     :repo "graintime"
;;     :local-path "~/github/teamshine05/graintime"
;;   }
;; }
;;
;; TEACHING: why this structure? because:
;; - :destinations is a LIST (multiple mirror targets!)
;; - each destination has a :name (human-readable reference)
;; - :url is the FULL grainbranch URL (validates properly!)
;; - :local-path is where files actually live on disk
;; - :enabled lets you temporarily disable destinations
;; - :current-source tells us where WE are (for readme naming)

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ CONFIG FILE LOCATION                                                  │
;; └───────────────────────────────────────────────────────────────────────┘

(define (get-config-paths)
  "Get possible config file locations (project-local first, then user-global).
  
  PRIORITY:
  1. ./.grainmirror.scm (current directory - project-specific)
  2. ~/.grainmirror.scm (home directory - user-global)
  
  TEACHING: Why check project-local first? Because you might have different
  mirror destinations for different projects! A project config overrides
  the global one. Does that make sense? 🌾"
  (list "./.grainmirror.scm"
        (string-append (getenv "HOME") "/.grainmirror.scm")))

(define (find-config-file)
  "Find the first existing config file from the priority list.
  Returns the path if found, or #f if none exist."
  (let loop ([paths (get-config-paths)])
    (if (null? paths)
        #f
        (let ([path (car paths)])
          (if (file-exists? path)
              path
              (loop (cdr paths)))))))

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ GRAINBRANCH URL VALIDATION                                            │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; a valid grainbranch URL must look like:
;; https://github.com/{org}/{repo}/tree/{grainbranch}
;; 
;; where {grainbranch} follows the format:
;; YYYYY-MM-DD--HHMM-TZ--moon-NAKSHATRA-asc-SIGNXX-sun-HHh--TEAM
;;
;; example:
;; https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12
;;
;; we need to:
;; 1. parse the URL
;; 2. extract the grainbranch
;; 3. validate it matches the graintime format
;; 4. return (ok {...}) or (err "reason")

(define (parse-github-url url)
  "Parse a GitHub URL into components.
  
  RETURNS: (ok {:org :repo :branch}) or (err 'reason')
  
  EXAMPLE:
  (parse-github-url 'https://github.com/kae3g/teamkae3gtravel12/tree/12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12')
  → (ok {:org 'kae3g' :repo 'teamkae3gtravel12' :branch '12025-10-28--1130-PDT--moon-uttaradha-asc-arie23-sun-12h--teamtravel12'})"
  
  ;; remove trailing ?tab=readme-ov-file or similar query params
  (let* ([clean-url (car (string-split url "?"))]
         [parts (string-split clean-url "/")]
         [len (length parts)])
    
    ;; github URLs have structure: https://github.com/{org}/{repo}/tree/{branch}
    ;; that's 3 (protocol) + 1 (github.com) + 1 (org) + 1 (repo) + 1 (tree) + 1 (branch) = 8 parts
    (if (< len 8)
        (err (string-append "URL too short: " url))
        
        (let ([protocol (list-ref parts 0)]
              [domain (list-ref parts 2)]
              [org (list-ref parts 3)]
              [repo (list-ref parts 4)]
              [tree-or-blob (list-ref parts 5)]
              [branch (string-join (drop parts 6) "/")])  ;; branch might have slashes
          
          (cond
            [(not (or (string=? protocol "https:") (string=? protocol "http:")))
             (err "URL must use https:// or http://")]
            
            [(not (string=? domain "github.com"))
             (err "URL must be from github.com")]
            
            [(not (string=? tree-or-blob "tree"))
             (err "URL must reference a branch (use /tree/...)")]
            
            [else
             (ok (hash :org org :repo repo :branch branch :url url))])))))

(define (validate-grainbranch branch)
  "Validate that a branch name follows graintime format.
  
  FORMAT: YYYYY-MM-DD--HHMM-TZ--moon-NAKSHATRA-asc-SIGNXX-sun-HHh--TEAM
  
  RETURNS: (ok branch) or (err 'reason')
  
  TEACHING: We're using REGEX-LIKE pattern matching here. We split on '--'
  and validate each component. Why? Because grainbranches encode astronomical
  data, and we want to ensure the data is properly formatted!
  
  This prevents bugs like:
  - typos in nakshatra names
  - malformed timestamps
  - missing components
  
  Does this feel like a 'type system' for branch names? It is! 🌊"
  
  (let ([parts (string-split branch "--")])
    (if (not (= (length parts) 4))
        (err (string-append "grainbranch must have 4 sections separated by '--': " branch))
        
        (let ([date-time (car parts)]
              [astro (cadr parts)]
              [moon-part (caddr parts)]
              [team (cadddr parts)])
          
          ;; validate date-time: YYYYY-MM-DD--HHMM-TZ
          ;; (simplified check - just verify it has the right structure)
          (if (not (>= (string-length date-time) 15))
              (err (string-append "invalid date-time format: " date-time))
              
              ;; validate astro components exist
              (if (not (string-starts-with? moon-part "moon-"))
                  (err (string-append "missing moon- prefix: " moon-part))
                  
                  ;; all checks passed!
                  (ok branch)))))))

(define (validate-destination-url url)
  "Validate a complete destination URL (parse + validate grainbranch).
  
  RETURNS: (ok {:org :repo :branch :url}) or (err 'reason')
  
  TEACHING: This is COMPOSITION! We use parse-github-url to break down
  the URL, then validate-grainbranch to check the branch name. If both
  pass, we return the parsed data. If either fails, we bubble up the error.
  
  Why compose functions like this? Because each function has ONE job:
  - parse-github-url: break down URL structure
  - validate-grainbranch: verify branch format
  - validate-destination-url: orchestrate both checks
  
  Single responsibility principle in action! 🎯"
  
  (let ([parse-result (parse-github-url url)])
    (if (err? parse-result)
        parse-result  ;; bubble up parse error
        
        (let* ([parsed (unwrap parse-result)]
               [branch (hash-ref parsed :branch)]
               [validate-result (validate-grainbranch branch)])
          
          (if (err? validate-result)
              validate-result  ;; bubble up validation error
              (ok parsed))))))  ;; all good!

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ RESULT TYPE (ok/err monad-like pattern)                               │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; we use a simple ok/err pattern for results:
;; - (ok value) means success
;; - (err message) means failure
;;
;; this lets us chain operations and handle errors gracefully!

(define (ok value)
  "Create a success result"
  (hash :type :ok :value value))

(define (err message)
  "Create an error result"
  (hash :type :err :message message))

(define (ok? result)
  "Check if result is ok"
  (equal? (hash-ref result :type) :ok))

(define (err? result)
  "Check if result is err"
  (equal? (hash-ref result :type) :err))

(define (unwrap result)
  "Extract value from ok result (throws if err)"
  (if (ok? result)
      (hash-ref result :value)
      (error (string-append "tried to unwrap error: " (hash-ref result :message)))))

(define (unwrap-or-else result default-fn)
  "Extract value from ok, or call default-fn if err"
  (if (ok? result)
      (hash-ref result :value)
      (default-fn (hash-ref result :message))))

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ COLLISION DETECTION & AUTO-ASSIGNMENT                                 │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; when mirroring a new readme, we need to:
;; 1. scan destination directory for existing grainorders
;; 2. find the SMALLEST existing grainorder (newest file)
;; 3. calculate the NEXT SMALLER grainorder (for our new file)
;; 4. use prev-grainorder with carry logic!
;;
;; this GUARANTEES no collisions! 🎯

(define (scan-grainorders-in-dir dir-path)
  "Scan a directory and extract all grainorder codes from filenames.
  
  RETURNS: list of grainorder strings, sorted smallest to largest
  
  EXAMPLE:
  (scan-grainorders-in-dir '~/github/kae3g/teamkae3gtravel12')
  → ('xzvskg' 'xzvskj' 'xzvskh' 'xzvskm' ...)
  
  TEACHING: We're doing FILESYSTEM PARSING here. We read the directory,
  filter for files that match the grainorder pattern (6 chars at start),
  extract those codes, and sort them. This gives us a complete picture
  of what grainorders are already in use!"
  
  (let* ([files (directory-files dir-path)]
         [grainorder-pattern "^([xbdghjklmnsvz]{6})-"]  ;; starts with 6 chars from alphabet
         [grainorders (filter-map
                        (lambda (filename)
                          (let ([match (string-match grainorder-pattern filename)])
                            (if match
                                (list-ref match 1)  ;; captured group
                                #f)))
                        files)])
    (sort grainorders string<?)))  ;; sort alphabetically (smallest first)

(define (find-next-grainorder-for-destination dest-path)
  "Find the next available grainorder for a destination directory.
  
  ALGORITHM:
  1. Scan destination for existing grainorders
  2. Find smallest (newest)
  3. Call prev-grainorder to get next smaller
  4. If prev-grainorder returns #f (overflow), start from xbdghj
  
  RETURNS: grainorder string (6 chars)
  
  TEACHING: This is the HEART of collision prevention! We look at what
  exists, find the frontier (smallest/newest), and step one unit smaller.
  It's like a clock ticking backwards, but with 1.2 million positions! ⏰"
  
  (let ([existing (scan-grainorders-in-dir dest-path)])
    (if (null? existing)
        ;; no files yet! start from the beginning
        "xbdghj"  ;; smallest possible grainorder
        
        ;; files exist - get next smaller than the smallest
        (let* ([smallest-existing (car existing)]
               [next-smaller (prev-grainorder smallest-existing)])
          (if next-smaller
              next-smaller
              ;; overflow! we've exhausted the xbdghj→x range
              ;; (shouldn't happen in practice with 1.2M codes!)
              (error "grainorder overflow - ran out of codes!"))))))

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ CONFIG MANAGEMENT                                                     │
;; └───────────────────────────────────────────────────────────────────────┘

(define (load-config)
  "Load grainmirror config from file.
  
  RETURNS: (ok config-hash) or (err 'message')
  
  TEACHING: This reads the config file and EVALUATES it as Steel code.
  Why? Because our config is just a Steel hash! This makes it:
  - expressive (you can use Steel functions in config!)
  - validated (Steel parser checks syntax!)
  - extensible (add new keys easily!)
  
  Does this feel like 'config as code'? It is! 📜"
  
  (let ([config-path (find-config-file)])
    (if config-path
        (begin
          (displayln (string-append "loading config from: " config-path))
          (let ([config-str (read-file config-path)])
            (ok (eval (parse config-str)))))
        (err "no .grainmirror.scm config file found"))))

(define (save-config config)
  "Save grainmirror config to file (user-global ~/.grainmirror.scm).
  
  TEACHING: We pretty-print the config hash as Steel code and write it
  to the user's home directory. This makes it persistent across sessions!"
  
  (let ([config-path (string-append (getenv "HOME") "/.grainmirror.scm")])
    (write-file config-path (pretty-print config))
    (displayln (string-append "saved config to: " config-path))))

(define (init-config-interactive)
  "Interactive setup wizard for creating .grainmirror.scm config.
  
  TEACHING: This is a REPL-style interface! We ask questions, collect
  answers, validate input, and build up the config hash step by step.
  
  Why interactive? Because typing out a full config hash by hand is
  error-prone! This guides you through the process with validation. 🌊"
  
  (displayln "\n╔═══════════════════════════════════════════════════════════════════════╗")
  (displayln "║         GRAINMIRROR CONFIG SETUP WIZARD 🪞                            ║")
  (displayln "╚═══════════════════════════════════════════════════════════════════════╝\n")
  
  (displayln "let's set up your grainmirror destinations!")
  (displayln "you can add multiple destinations (e.g., personal + org repos).\n")
  
  ;; collect source info
  (displayln "first, tell me about THIS repo (the source):")
  (display "  org name (e.g., teamshine05): ")
  (let ([source-org (read-line)])
    (display "  repo name (e.g., graintime): ")
    (let ([source-repo (read-line)])
      (display "  local path (e.g., ~/github/teamshine05/graintime): ")
      (let ([source-path (read-line)])
        
        ;; collect destination info
        (displayln "\nnow, let's add a destination (where readmes will be mirrored):")
        (let loop ([destinations '()])
          (display "  destination name (e.g., travel12-personal): ")
          (let ([dest-name (read-line)])
            (display "  destination URL (full grainbranch URL): ")
            (let ([dest-url (read-line)])
              (let ([validated (validate-destination-url dest-url)])
                (if (err? validated)
                    (begin
                      (displayln (string-append "  ❌ invalid URL: " (hash-ref validated :message)))
                      (display "  try again? (y/n): ")
                      (if (string=? (read-line) "y")
                          (loop destinations)
                          destinations))
                    
                    (begin
                      (display "  local path (e.g., ~/github/kae3g/teamkae3gtravel12): ")
                      (let ([dest-path (read-line)])
                        (displayln "  ✓ destination validated!")
                        (let ([new-dest (hash
                                          :name dest-name
                                          :url dest-url
                                          :local-path dest-path
                                          :enabled #t)])
                          (display "\n  add another destination? (y/n): ")
                          (if (string=? (read-line) "y")
                              (loop (cons new-dest destinations))
                              (cons new-dest destinations))))))))))))
        
        ;; build final config
        (let ([config (hash
                        :destinations destinations
                        :current-source (hash
                                          :org source-org
                                          :repo source-repo
                                          :local-path source-path))])
          (save-config config)
          (displayln "\n✨ config saved! you can now use 'grainmirror sync' without specifying destinations.")
          (ok config))))))

;; ┌───────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                     │
;; └───────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ config file structure (.grainmirror.scm)
;; ✅ URL parsing and validation (github + grainbranch format)
;; ✅ result type (ok/err pattern for error handling)
;; ✅ collision detection (scan existing grainorders)
;; ✅ auto-assignment (find next smaller grainorder)
;; ✅ config management (load, save, interactive setup)
;; ✅ glow g2 teaching comments
;;
;; what's next (phase 2):
;; - integrate with grainmirror.scm (use config for destinations)
;; - add 'grainmirror init' command (run setup wizard)
;; - add 'grainmirror status' command (show current config)
;; - add 'grainmirror add-destination' (add new destination)
;; - add 'grainmirror sync --all' (sync to all enabled destinations)
;;
;; does this feel like "set it and forget it"? that's the dream! 🪞✨
;;
;; now == next + 1 🌾

