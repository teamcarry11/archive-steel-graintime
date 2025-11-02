;; ╔══════════════════════════════════════════════════════════════════════════╗
;; ║                          GRAINMIRROR                                     ║
;; ║          reflect files across multiple repos without symlinks            ║
;; ║                   pure steel, tracked hard copies                        ║
;; ║                                                                          ║
;; ║  "what if the same file could exist in many places, knowingly?"         ║
;; ║                                                                          ║
;; ║  phase 1: registration + sync + verification                            ║
;; ║  team: teamshine05 (leo ♌ / V. the hierophant - knowledge distribution)║
;; ║                                                                          ║
;; ╚══════════════════════════════════════════════════════════════════════════╝

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ DESIGN PHILOSOPHY                                                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; grainmirror solves a specific problem: you want the SAME file to exist
;; in MULTIPLE git repositories, tracked independently by git, visible on
;; github, but maintained from a single canonical source.
;;
;; why not symlinks?
;; - github doesn't follow symlinks in web UI
;; - git doesn't track symlink targets (only the symlink itself)
;; - you want each repo to have its own git history for that file
;;
;; why not git submodules?
;; - too heavyweight for individual files
;; - forces shared git history
;; - IDE visibility issues
;;
;; grainmirror gives you:
;; - **hard copies**: real files in each location
;; - **tracked mapping**: know where all copies live
;; - **sync on demand**: update all mirrors with one command
;; - **drift detection**: see which mirrors are out of sync
;; - **git-friendly**: each copy has independent git history
;;
;; think of it like:
;; - carbon copies (before photocopiers!)
;; - hall of mirrors (same image, many reflections)
;; - broadcast (one source, many receivers)
;;
;; does this feel like conscious duplication? good! 🪞

(require-builtin steel/io)
(require-builtin steel/hash)

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MIRROR REGISTRY                                                         │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; the registry is a simple data structure:
;; {
;;   "source-path-1": {
;;     :mirrors ["mirror-path-1" "mirror-path-2" ...]
;;     :last-sync "timestamp"
;;     :content-hash "sha256-hash"
;;   }
;;   "source-path-2": { ... }
;; }
;;
;; stored in: ~/.grainmirror/registry.edn

(define registry-file (string-append (getenv "HOME") "/.grainmirror/registry.edn"))

;; load registry from disk (or create empty if doesn't exist)
(define (load-registry)
  (if (file-exists? registry-file)
      (read-string-to-hash (read-file-to-string registry-file))
      (hash)))

;; save registry to disk
(define (save-registry! registry)
  ;; ensure directory exists
  (when (not (file-exists? (string-append (getenv "HOME") "/.grainmirror")))
    (command "mkdir -p ~/.grainmirror"))
  
  ;; write registry as edn
  (with-output-to-file registry-file
    (lambda () (displayln (hash->string registry)))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ FILE OPERATIONS                                                         │
;; └────────────────────────────────────────────────────────────────────────┘

;; expand ~ in file paths
(define (expand-path path)
  (if (string-starts-with? path "~")
      (string-append (getenv "HOME") (substring path 1 (string-length path)))
      path))

;; read file content
(define (read-file path)
  (read-file-to-string (expand-path path)))

;; write file content
(define (write-file path content)
  (let ([expanded (expand-path path)])
    ;; ensure parent directory exists
    (let ([parent-dir (dirname expanded)])
      (when (not (file-exists? parent-dir))
        (command (format "mkdir -p ~a" parent-dir))))
    
    ;; write content
    (with-output-to-file expanded
      (lambda () (display content)))))

;; get directory name from path
(define (dirname path)
  (let ([parts (reverse (string-split path "/"))])
    (string-join (reverse (cdr parts)) "/")))

;; compute SHA256 hash of file content
(define (file-hash path)
  (let* ([content (read-file path)]
         [result (command (format "printf '%s' ~s | sha256sum | cut -d' ' -f1" content))])
    (string-trim (hash-ref result :stdout))))

;; check if file exists
(define (file-exists? path)
  (let ([result (command (format "test -f ~a" (expand-path path)))])
    (equal? (hash-ref result :exit-code) 0)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MIRROR REGISTRATION                                                     │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; register a file for mirroring: associate a source with mirror paths

;; register a single mirror path for a source
(define (mirror-add! source-path mirror-path)
  (displayln (format "\n🪞 registering mirror..."))
  (displayln (format "   source: ~a" source-path))
  (displayln (format "   mirror: ~a" mirror-path))
  
  (let* ([registry (load-registry)]
         [expanded-source (expand-path source-path)]
         [expanded-mirror (expand-path mirror-path)])
    
    ;; check if source exists
    (when (not (file-exists? expanded-source))
      (error "source file does not exist:" expanded-source))
    
    ;; get or create entry for this source
    (let* ([entry (hash-try-get registry expanded-source
                                (hash :mirrors '()
                                      :last-sync "never"
                                      :content-hash ""))]
           [mirrors (hash-ref entry :mirrors)]
           [new-mirrors (if (member expanded-mirror mirrors)
                            mirrors  ;; already registered
                            (cons expanded-mirror mirrors))]
           [new-entry (hash-insert entry :mirrors new-mirrors)])
      
      ;; update registry
      (hash-set! registry expanded-source new-entry)
      (save-registry! registry)
      
      (if (member expanded-mirror mirrors)
          (displayln "⚠️  mirror already registered")
          (displayln "✅ mirror registered!"))
      
      (displayln (format "   total mirrors: ~a\n" (length new-mirrors)))
      #t)))

;; register multiple mirror paths for a source
(define (mirror-add-many! source-path mirror-paths)
  (for-each (lambda (mirror-path)
              (mirror-add! source-path mirror-path))
            mirror-paths))

;; remove a mirror path
(define (mirror-remove! source-path mirror-path)
  (displayln (format "\n🗑️  removing mirror..."))
  (displayln (format "   source: ~a" source-path))
  (displayln (format "   mirror: ~a" mirror-path))
  
  (let* ([registry (load-registry)]
         [expanded-source (expand-path source-path)]
         [expanded-mirror (expand-path mirror-path)])
    
    (if (not (hash-contains? registry expanded-source))
        (begin
          (displayln "❌ source not registered")
          #f)
        
        (let* ([entry (hash-ref registry expanded-source)]
               [mirrors (hash-ref entry :mirrors)]
               [new-mirrors (filter (lambda (m) (not (string=? m expanded-mirror))) mirrors)]
               [new-entry (hash-insert entry :mirrors new-mirrors)])
          
          (hash-set! registry expanded-source new-entry)
          (save-registry! registry)
          
          (displayln "✅ mirror removed!")
          (displayln (format "   remaining mirrors: ~a\n" (length new-mirrors)))
          #t))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MIRROR SYNCHRONIZATION                                                  │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; sync: copy source file to all registered mirrors

;; sync a single source file to all its mirrors
(define (mirror-sync-one! source-path)
  (displayln (format "\n🪞 syncing: ~a" source-path))
  
  (let* ([registry (load-registry)]
         [expanded-source (expand-path source-path)])
    
    (if (not (hash-contains? registry expanded-source))
        (begin
          (displayln "❌ source not registered")
          #f)
        
        (let* ([entry (hash-ref registry expanded-source)]
               [mirrors (hash-ref entry :mirrors)]
               [content (read-file expanded-source)]
               [new-hash (file-hash expanded-source)]
               [timestamp (format "~a" (current-time))])
          
          (displayln (format "   mirrors: ~a" (length mirrors)))
          (displayln (format "   hash: ~a" (substring new-hash 0 8)))
          
          ;; copy to each mirror
          (for-each (lambda (mirror-path)
                      (displayln (format "   → ~a" mirror-path))
                      (write-file mirror-path content))
                    mirrors)
          
          ;; update registry
          (let ([new-entry (hash-insert entry
                                        :last-sync timestamp
                                        :content-hash new-hash)])
            (hash-set! registry expanded-source new-entry)
            (save-registry! registry))
          
          (displayln "✅ sync complete!\n")
          #t))))

;; sync all registered sources
(define (mirror-sync-all!)
  (displayln "\n╔════════════════════════════════════════════════╗")
  (displayln "║  GRAINMIRROR SYNC 🪞                           ║")
  (displayln "╚════════════════════════════════════════════════╝\n")
  
  (let* ([registry (load-registry)]
         [sources (hash-keys registry)])
    
    (if (null? sources)
        (begin
          (displayln "⚠️  no mirrors registered yet!")
          (displayln "   use: steel grainmirror.scm add <source> <mirror>\n")
          #f)
        
        (begin
          (displayln (format "syncing ~a source(s)...\n" (length sources)))
          
          (for-each mirror-sync-one! sources)
          
          (displayln "╔════════════════════════════════════════════════╗")
          (displayln "║  ✨ ALL MIRRORS SYNCED! ✨                     ║")
          (displayln "╚════════════════════════════════════════════════╝\n")
          #t))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MIRROR VERIFICATION                                                     │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; verify: check if mirrors match their source (detect drift)

;; verify a single source
(define (mirror-verify-one source-path)
  (let* ([registry (load-registry)]
         [expanded-source (expand-path source-path)]
         [entry (hash-ref registry expanded-source)]
         [mirrors (hash-ref entry :mirrors)]
         [recorded-hash (hash-ref entry :content-hash)]
         [current-hash (file-hash expanded-source)])
    
    (displayln (format "\n🔍 source: ~a" source-path))
    (displayln (format "   mirrors: ~a" (length mirrors)))
    
    ;; check if source has changed since last sync
    (if (not (string=? recorded-hash current-hash))
        (displayln (format "   ⚠️  source changed! (was: ~a, now: ~a)"
                           (substring recorded-hash 0 8)
                           (substring current-hash 0 8)))
        (displayln (format "   ✅ source unchanged (~a)" (substring current-hash 0 8))))
    
    ;; check each mirror
    (let ([all-in-sync #t])
      (for-each (lambda (mirror-path)
                  (if (not (file-exists? mirror-path))
                      (begin
                        (displayln (format "   ❌ missing: ~a" mirror-path))
                        (set! all-in-sync #f))
                      
                      (let ([mirror-hash (file-hash mirror-path)])
                        (if (string=? mirror-hash current-hash)
                            (displayln (format "   ✅ in sync: ~a" mirror-path))
                            (begin
                              (displayln (format "   ❌ drift detected: ~a" mirror-path))
                              (displayln (format "      source: ~a" (substring current-hash 0 8)))
                              (displayln (format "      mirror: ~a" (substring mirror-hash 0 8)))
                              (set! all-in-sync #f))))))
                mirrors)
      
      all-in-sync)))

;; verify all registered sources
(define (mirror-verify-all)
  (displayln "\n╔════════════════════════════════════════════════╗")
  (displayln "║  GRAINMIRROR VERIFY 🔍                         ║")
  (displayln "╚════════════════════════════════════════════════╝")
  
  (let* ([registry (load-registry)]
         [sources (hash-keys registry)])
    
    (if (null? sources)
        (begin
          (displayln "\n⚠️  no mirrors registered yet!\n")
          #t)
        
        (begin
          (let ([all-verified #t])
            (for-each (lambda (source)
                        (when (not (mirror-verify-one source))
                          (set! all-verified #f)))
                      sources)
            
            (displayln "\n╔════════════════════════════════════════════════╗")
            (if all-verified
                (displayln "║  ✅ ALL MIRRORS VERIFIED! ✅                   ║")
                (displayln "║  ⚠️  SOME MIRRORS OUT OF SYNC!                ║"))
            (displayln "╚════════════════════════════════════════════════╝\n")
            
            all-verified)))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MIRROR LISTING                                                          │
;; └────────────────────────────────────────────────────────────────────────┘

;; list all registered mirrors
(define (mirror-list)
  (displayln "\n╔════════════════════════════════════════════════╗")
  (displayln "║  GRAINMIRROR REGISTRY 🪞                       ║")
  (displayln "╚════════════════════════════════════════════════╝\n")
  
  (let* ([registry (load-registry)]
         [sources (hash-keys registry)])
    
    (if (null? sources)
        (displayln "⚠️  no mirrors registered yet!\n")
        
        (begin
          (displayln (format "registered sources: ~a\n" (length sources)))
          
          (for-each (lambda (source)
                      (let* ([entry (hash-ref registry source)]
                             [mirrors (hash-ref entry :mirrors)]
                             [last-sync (hash-ref entry :last-sync)]
                             [content-hash (hash-ref entry :content-hash)])
                        
                        (displayln (format "📄 ~a" source))
                        (displayln (format "   last sync: ~a" last-sync))
                        (displayln (format "   hash: ~a" (if (string=? content-hash "")
                                                             "never synced"
                                                             (substring content-hash 0 16))))
                        (displayln (format "   mirrors (~a):" (length mirrors)))
                        (for-each (lambda (mirror)
                                    (displayln (format "   → ~a" mirror)))
                                  mirrors)
                        (displayln "")))
                    sources)
          
          (displayln "🌾 now == next + 1\n")))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ GRAINORDER REBALANCING                                                  │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; rebalance grainorders in a directory based on timestamps
;; newest file gets smallest grainorder, oldest gets largest

;; require grainorder module
(require "grainorder.scm")

;; parse grainorder and timestamp from filename
;; "xzvbdh-12025-10-28--1315-pdt--readme.md" → {:grainorder "xzvbdh" :timestamp "12025-10-28--1315-pdt" :rest "readme.md"}
(define (parse-grainorder-filename filename)
  (let ([parts (string-split filename "-")])
    (if (< (length parts) 6)
        #f  ;; not a grainorder filename
        (let* ([grainorder (car parts)]
               [year (cadr parts)]
               [month (caddr parts)]
               [day (cadddr parts)]
               [dash-dash (list-ref parts 4)]
               [time (list-ref parts 5)]
               [tz (list-ref parts 6)])
          (if (and (= (string-length grainorder) 6)
                   (string=? dash-dash "")  ;; the -- split creates empty string
                   (= (string-length year) 5)
                   (= (string-length month) 2)
                   (= (string-length day) 2))
              (hash :grainorder grainorder
                    :timestamp (format "~a-~a-~a--~a-~a" year month day time tz)
                    :rest (string-join (drop parts 7) "-")
                    :full-path filename)
              #f)))))

;; convert timestamp to comparable integer (YYYYMMDDHHMM)
(define (timestamp-to-int timestamp)
  ;; "12025-10-28--1315-pdt" → 1202510281315
  (let* ([parts (string-split timestamp "-")]
         [year (car parts)]
         [month (cadr parts)]
         [day (caddr parts)]
         [time-tz (string-split (list-ref parts 3) "-")]
         [time (car time-tz)])
    (string->number (format "~a~a~a~a" year month day time))))

;; rebalance grainorders in a directory
(define (grainorder-rebalance! directory-path)
  (displayln "\n╔════════════════════════════════════════════════╗")
  (displayln "║  GRAINORDER REBALANCE 🔄                       ║")
  (displayln "╚════════════════════════════════════════════════╝\n")
  
  (displayln (format "directory: ~a\n" directory-path))
  
  (let* ([expanded-dir (expand-path directory-path)]
         ;; list all files in directory
         [result (command (format "ls ~a" expanded-dir))]
         [files (string-split (string-trim (hash-ref result :stdout)) "\n")]
         
         ;; parse filenames with grainorder
         [parsed (filter (lambda (p) p)  ;; remove #f entries
                        (map (lambda (f)
                               (let ([p (parse-grainorder-filename f)])
                                 (when p
                                   (hash-set! p :full-path (string-append expanded-dir "/" f)))
                                 p))
                             files))])
    
    (if (null? parsed)
        (begin
          (displayln "❌ no grainorder files found in directory")
          #f)
        
        (begin
          (displayln (format "found ~a grainorder files\n" (length parsed)))
          
          ;; sort by timestamp (newest first = largest timestamp number first)
          (let* ([sorted (sort parsed
                              (lambda (a b)
                                (> (timestamp-to-int (hash-ref a :timestamp))
                                   (timestamp-to-int (hash-ref b :timestamp)))))]
                 
                 ;; generate new grainorders (start from SMALLEST, work forwards)
                 ;; strategy: start at xzvbdg (smallest) for newest files
                 ;;           work forwards up to zxvsnl max (zxvsnm reserved for archives)
                 [first-grainorder "xzvbdg"]  ;; smallest grainorder for newest file
                 [new-grainorders (let loop ([current first-grainorder]
                                             [count (length sorted)]
                                             [result '()])
                                    (if (= count 0)
                                        (reverse result)  ;; reverse to get correct order
                                        (loop (next-grainorder current)
                                              (- count 1)
                                              (cons current result))))])
            
            ;; show rebalancing plan
            (displayln "rebalancing plan (newest → oldest):")
            (displayln "strategy: start from xzvbdg (smallest) for newest, up to zxvsnl max (zxvsnm=archives)\n")
            (for-each (lambda (parsed-file new-grainorder)
                        (let ([old-grainorder (hash-ref parsed-file :grainorder)]
                              [timestamp (hash-ref parsed-file :timestamp)]
                              [rest (hash-ref parsed-file :rest)])
                          (displayln (format "  ~a  ~a → ~a  (~a)"
                                             timestamp
                                             old-grainorder
                                             new-grainorder
                                             rest))))
                      sorted
                      new-grainorders)
            
            ;; prompt for confirmation
            (displayln "\n⚠️  this will rename files! continue? (y/n)")
            (let ([response (read-line)])
              (if (string=? (string-trim response) "y")
                  (begin
                    (displayln "\n🔄 renaming files...\n")
                    
                    ;; rename each file
                    (for-each (lambda (parsed-file new-grainorder)
                                (let* ([old-path (hash-ref parsed-file :full-path)]
                                       [timestamp (hash-ref parsed-file :timestamp)]
                                       [rest (hash-ref parsed-file :rest)]
                                       [new-filename (format "~a-~a--~a" new-grainorder timestamp rest)]
                                       [new-path (string-append expanded-dir "/" new-filename)])
                                  
                                  (displayln (format "  → ~a" new-filename))
                                  (command (format "mv ~s ~s" old-path new-path))))
                              sorted
                              new-grainorders)
                    
                    (displayln "\n✅ rebalancing complete!")
                    (displayln "🌾 now == next + 1\n")
                    #t)
                  
                  (begin
                    (displayln "\n❌ rebalancing cancelled\n")
                    #f)))))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ CLI INTERFACE                                                           │
;; └────────────────────────────────────────────────────────────────────────┘

;; display help
(define (show-help)
  (displayln "\n╔════════════════════════════════════════════════════════════════════╗")
  (displayln "║  GRAINMIRROR - reflect files across repos                          ║")
  (displayln "╚════════════════════════════════════════════════════════════════════╝\n")
  (displayln "usage:")
  (displayln "  steel grainmirror.scm add <source> <mirror>")
  (displayln "  steel grainmirror.scm remove <source> <mirror>")
  (displayln "  steel grainmirror.scm sync [source]")
  (displayln "  steel grainmirror.scm verify")
  (displayln "  steel grainmirror.scm list")
  (displayln "  steel grainmirror.scm rebalance <directory>")
  (displayln "  steel grainmirror.scm help\n")
  (displayln "examples:")
  (displayln "  # register a mirror")
  (displayln "  steel grainmirror.scm add \\")
  (displayln "    ~/github/teamshine05/graintime/readme.md \\")
  (displayln "    ~/github/kae3g/teamkae3gtravel12/readme.md\n")
  (displayln "  # sync all mirrors")
  (displayln "  steel grainmirror.scm sync\n")
  (displayln "  # verify all mirrors")
  (displayln "  steel grainmirror.scm verify\n")
  (displayln "  # list all registered mirrors")
  (displayln "  steel grainmirror.scm list\n")
  (displayln "  # rebalance grainorders by timestamp")
  (displayln "  steel grainmirror.scm rebalance ~/github/kae3g/teamkae3gtravel12\n")
  (displayln "what it does:")
  (displayln "  - tracks which files should be mirrored where")
  (displayln "  - syncs source to all mirrors (hard copies)")
  (displayln "  - verifies mirrors match source (drift detection)")
  (displayln "  - rebalances grainorders (newest=smallest, oldest=largest)")
  (displayln "  - each copy has independent git history")
  (displayln "  - github displays all copies in web UI\n")
  (displayln "why not symlinks?")
  (displayln "  - github doesn't follow symlinks")
  (displayln "  - git doesn't track symlink targets")
  (displayln "  - grainmirror gives you real, tracked copies!\n")
  (displayln "now == next + 1 🌾\n"))

;; main entry point
(define (main args)
  (if (< (length args) 1)
      (show-help)
      
      (let ([command (car args)])
        (cond
          [(equal? command "add")
           (if (< (length args) 3)
               (begin
                 (displayln "❌ error: missing arguments!")
                 (displayln "   usage: steel grainmirror.scm add <source> <mirror>")
                 #f)
               (mirror-add! (cadr args) (caddr args)))]
          
          [(equal? command "remove")
           (if (< (length args) 3)
               (begin
                 (displayln "❌ error: missing arguments!")
                 (displayln "   usage: steel grainmirror.scm remove <source> <mirror>")
                 #f)
               (mirror-remove! (cadr args) (caddr args)))]
          
          [(equal? command "sync")
           (if (< (length args) 2)
               (mirror-sync-all!)
               (mirror-sync-one! (cadr args)))]
          
          [(equal? command "verify")
           (mirror-verify-all)]
          
          [(equal? command "list")
           (mirror-list)]
          
          [(equal? command "rebalance")
           (if (< (length args) 2)
               (begin
                 (displayln "❌ error: missing directory path!")
                 (displayln "   usage: steel grainmirror.scm rebalance <directory>")
                 #f)
               (grainorder-rebalance! (cadr args)))]
          
          [(equal? command "help")
           (show-help)]
          
          [else
           (begin
             (displayln (format "❌ unknown command: ~a" command))
             (displayln "   run 'steel grainmirror.scm help' for usage")
             #f)]))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ mirror registry (tracks source → mirrors mapping)
;; ✅ registration (add/remove mirror paths)
;; ✅ synchronization (copy source to all mirrors)
;; ✅ verification (detect drift/missing mirrors)
;; ✅ listing (show all registered mirrors)
;; ✅ file operations (read/write with directory creation)
;; ✅ content hashing (SHA256 for drift detection)
;; ✅ CLI interface (add/remove/sync/verify/list)
;; ✅ glow g2 teaching comments
;;
;; what's next (phase 2):
;; - auto-sync on file change (watch mode)
;; - git integration (auto-commit after sync)
;; - conflict resolution (what if mirror was edited?)
;; - batch operations (sync subset of mirrors)
;; - mirror groups (sync related files together)
;; - integration with grainorder (mirror by grainorder)
;;
;; does this feel like conscious duplication? ready to reflect? 🪞⚡
;;
;; now == next + 1 🌾

;; run main if executed as script
(when (> (length (command-line-args)) 0)
  (main (command-line-args)))

(displayln "\n╔════════════════════════════════════════════════════════════════════╗")
(displayln "║  GRAINMIRROR PHASE 1: LOADED! 🪞                                   ║")
(displayln "║  reflect files across repos without symlinks                       ║")
(displayln "║  try: steel grainmirror.scm list                                   ║")
(displayln "╚════════════════════════════════════════════════════════════════════╝\n")

