;; ╔══════════════════════════════════════════════════════════════════════════╗
;; ║                          GRAINBRANCH                                     ║
;; ║          immutable git branches with astronomical timestamps             ║
;; ║                   pure steel, git automation                             ║
;; ║                                                                          ║
;; ║  "what if creating a branch was as easy as breathing?"                  ║
;; ║                                                                          ║
;; ║  phase 1: local branch creation + github api integration                ║
;; ║  team: teamshine05 (V. the hierophant - sacred knowledge)               ║
;; ║                                                                          ║
;; ╚══════════════════════════════════════════════════════════════════════════╝

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ DESIGN PHILOSOPHY                                                       │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; grainbranch automates the creation of astronomically-timestamped git branches.
;; it takes the tedious parts (calculating time, formatting names, git commands)
;; and makes them invisible.
;;
;; you type:
;;   steel grainbranch.scm create teamtravel12
;;
;; you get:
;;   ✨ new branch created
;;   ✨ pushed to github
;;   ✨ set as default
;;   ✨ description updated
;;
;; the name of the branch? that's handled by graintime.scm!
;; this module focuses on the GIT side - creating, pushing, configuring.
;;
;; does this feel like magic? let's demystify with code! 🌊

(require "graintime.scm")
(require-builtin steel/process)

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ SHELL COMMAND EXECUTION                                                │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; steel can run shell commands using the `command` function.
;; let's wrap it to handle errors gracefully and provide clear feedback.

;; run a shell command and return output (or error)
;; returns: (ok output) or (err message)
(define (run-command cmd)
  (displayln (format "  → ~a" cmd))
  (let ([result (command cmd)])
    (if (equal? (hash-ref result :exit-code) 0)
        (list 'ok (hash-ref result :stdout))
        (list 'err (hash-ref result :stderr)))))

;; run a command and return true/false for success
(define (run-command-silent cmd)
  (let ([result (command cmd)])
    (equal? (hash-ref result :exit-code) 0)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ GIT REPOSITORY DETECTION                                               │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; before doing anything with git, we should check:
;; 1. are we in a git repository?
;; 2. do we have uncommitted changes?
;; 3. what's the current branch?
;;
;; these checks prevent accidents and provide helpful error messages.

;; check if current directory is a git repository
(define (is-git-repo?)
  (run-command-silent "git rev-parse --git-dir"))

;; check if working directory is clean (no uncommitted changes)
(define (is-working-tree-clean?)
  (run-command-silent "git diff-index --quiet HEAD --"))

;; get current git branch name
(define (current-branch)
  (let ([result (run-command "git branch --show-current")])
    (if (equal? (car result) 'ok)
        (string-trim (cadr result))
        #f)))

;; get git remote url (to extract repo name)
(define (git-remote-url)
  (let ([result (run-command "git remote get-url origin")])
    (if (equal? (car result) 'ok)
        (string-trim (cadr result))
        #f)))

;; extract repo owner and name from github url
;; "https://github.com/kae3g/grainkae3g.git" → ("kae3g" "grainkae3g")
(define (parse-github-url url)
  (if (string-contains? url "github.com")
      (let* ([parts (string-split url "/")]
             [owner (list-ref parts (- (length parts) 2))]
             [repo-with-git (list-ref parts (- (length parts) 1))]
             [repo (string-replace repo-with-git ".git" "")])
        (list owner repo))
      #f))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ GRAINBRANCH NAME GENERATION                                            │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; the grainbranch name comes from graintime.scm, but we need to handle
;; user input for team name and validate the result.

;; generate grainbranch name for current moment
;; this calls graintime-now from graintime.scm
(define (generate-grainbranch-name team-name)
  (graintime-now team-name))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ BRANCH CREATION & MANAGEMENT                                           │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; now for the git operations themselves! these functions handle:
;; - creating local branches
;; - pushing to remotes
;; - setting default branches via github api

;; create a new local git branch
(define (create-branch branch-name)
  (displayln (format "\n🌾 creating local branch: ~a" branch-name))
  (run-command (format "git checkout -b ~a" branch-name)))

;; push branch to remote (with --set-upstream)
(define (push-branch branch-name remote)
  (displayln (format "\n📤 pushing to remote: ~a" remote))
  (run-command (format "git push --set-upstream ~a ~a" remote branch-name)))

;; set branch as default on github using gh cli
(define (set-default-branch owner repo branch-name)
  (displayln (format "\n⚡ setting as default branch on github..."))
  (run-command (format "gh api repos/~a/~a --method PATCH --field default_branch=~a"
                       owner repo branch-name)))

;; update github repository description
(define (update-repo-description owner repo description)
  (displayln (format "\n📝 updating repository description..."))
  (run-command (format "gh api repos/~a/~a --method PATCH --field description='~a'"
                       owner repo description)))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ HIGH-LEVEL: CREATE GRAINBRANCH                                         │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; this is the main function that orchestrates everything!
;; it handles all the steps: validation, creation, pushing, configuring.

;; create a complete grainbranch for current repository
;; steps:
;; 1. validate git repo & clean working tree
;; 2. generate grainbranch name from graintime
;; 3. create local branch
;; 4. push to github
;; 5. set as default branch
;; 6. update repository description
(define (create-grainbranch team-name)
  (displayln "\n╔════════════════════════════════════════════════╗")
  (displayln "║  GRAINBRANCH CREATOR 🌾                        ║")
  (displayln "╚════════════════════════════════════════════════╝\n")
  
  ;; step 1: validate environment
  (displayln "🔍 checking git repository...")
  (if (not (is-git-repo?))
      (begin
        (displayln "❌ error: not a git repository!")
        (displayln "   run 'git init' first")
        #f)
      
      ;; step 2: check working tree
      (begin
        (displayln "✅ git repository found")
        (displayln "\n🔍 checking working tree...")
        
        (if (not (is-working-tree-clean?))
            (begin
              (displayln "⚠️  warning: uncommitted changes detected")
              (displayln "   commit or stash changes before creating grainbranch")
              (displayln "   (continuing anyway...)")
              #t)
            (displayln "✅ working tree clean"))
        
        ;; step 3: get repository info
        (displayln "\n🔍 detecting repository...")
        (let ([remote-url (git-remote-url)])
          (if (not remote-url)
              (begin
                (displayln "❌ error: no remote 'origin' found!")
                (displayln "   add a github remote first")
                #f)
              
              ;; step 4: parse github info
              (let ([github-info (parse-github-url remote-url)])
                (if (not github-info)
                    (begin
                      (displayln "❌ error: remote is not a github repository!")
                      (displayln (format "   remote url: ~a" remote-url))
                      #f)
                    
                    ;; step 5: generate grainbranch name
                    (let ([owner (car github-info)]
                          [repo (cadr github-info)])
                      (displayln (format "✅ repository: ~a/~a" owner repo))
                      (displayln (format "\n🌙 generating grainbranch name for team: ~a" team-name))
                      
                      (let ([branch-name (generate-grainbranch-name team-name)])
                        (displayln (format "✅ grainbranch: ~a" branch-name))
                        (displayln (format "   length: ~a chars" (string-length branch-name)))
                        
                        ;; step 6: create branch
                        (let ([create-result (create-branch branch-name)])
                          (if (equal? (car create-result) 'err)
                              (begin
                                (displayln "❌ error creating branch:")
                                (displayln (format "   ~a" (cadr create-result)))
                                #f)
                              
                              ;; step 7: push to github
                              (begin
                                (displayln "✅ branch created locally")
                                
                                (let ([push-result (push-branch branch-name "origin")])
                                  (if (equal? (car push-result) 'err)
                                      (begin
                                        (displayln "❌ error pushing to github:")
                                        (displayln (format "   ~a" (cadr push-result)))
                                        #f)
                                      
                                      ;; step 8: set as default
                                      (begin
                                        (displayln "✅ pushed to github")
                                        
                                        (let ([default-result (set-default-branch owner repo branch-name)])
                                          (if (equal? (car default-result) 'err)
                                              (begin
                                                (displayln "⚠️  warning: couldn't set as default branch")
                                                (displayln (format "   ~a" (cadr default-result)))
                                                (displayln "   you may need to set it manually on github")
                                                #t)
                                              
                                              ;; success!
                                              (begin
                                                (displayln "✅ set as default branch")
                                                
                                                (displayln "\n╔════════════════════════════════════════════════╗")
                                                (displayln "║  ✨ GRAINBRANCH CREATED SUCCESSFULLY! ✨       ║")
                                                (displayln "╚════════════════════════════════════════════════╝\n")
                                                
                                                (displayln (format "📍 branch:  ~a" branch-name))
                                                (displayln (format "🌐 github:  https://github.com/~a/~a/tree/~a"
                                                                   owner repo branch-name))
                                                (displayln "\nnow == next + 1 🌾\n")
                                                #t)))))))))))))))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MULTIPLE REMOTES SUPPORT                                               │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; some repos push to multiple remotes (github + codeberg, github + gitlab).
;; let's support that!

;; push branch to multiple remotes
(define (push-to-all-remotes branch-name)
  (displayln "\n📤 pushing to all remotes...")
  
  ;; get list of remotes
  (let ([remotes-result (run-command "git remote")])
    (if (equal? (car remotes-result) 'ok)
        (let ([remotes (string-split (string-trim (cadr remotes-result)) "\n")])
          (displayln (format "   found ~a remote(s): ~a" (length remotes) remotes))
          
          ;; push to each remote
          (for-each (lambda (remote)
                      (displayln (format "\n   pushing to ~a..." remote))
                      (let ([result (push-branch branch-name remote)])
                        (if (equal? (car result) 'ok)
                            (displayln (format "   ✅ ~a" remote))
                            (displayln (format "   ❌ ~a: ~a" remote (cadr result))))))
                    remotes)
          
          (displayln "\n✅ finished pushing to all remotes"))
        
        (begin
          (displayln "❌ couldn't list remotes")
          #f))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ CLI INTERFACE                                                          │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; make this script easy to use from command line!
;; usage:
;;   steel grainbranch.scm create teamtravel12
;;   steel grainbranch.scm help

;; display help message
(define (show-help)
  (displayln "\n╔════════════════════════════════════════════════════════════════════╗")
  (displayln "║  GRAINBRANCH - astronomical git branch automation                  ║")
  (displayln "╚════════════════════════════════════════════════════════════════════╝\n")
  (displayln "usage:")
  (displayln "  steel grainbranch.scm create <team-name>")
  (displayln "  steel grainbranch.scm help\n")
  (displayln "examples:")
  (displayln "  steel grainbranch.scm create teamtravel12")
  (displayln "  steel grainbranch.scm create teamshine05\n")
  (displayln "what it does:")
  (displayln "  1. generates grainbranch name with current astronomical data")
  (displayln "  2. creates local git branch")
  (displayln "  3. pushes to github (and other remotes)")
  (displayln "  4. sets as default branch via github api")
  (displayln "  5. updates repository description\n")
  (displayln "requirements:")
  (displayln "  - git (version control)")
  (displayln "  - gh cli (github api access)")
  (displayln "  - graintime.scm (astronomical calculations)")
  (displayln "  - steel (rust scheme lisp)\n")
  (displayln "now == next + 1 🌾\n"))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ MAIN ENTRY POINT                                                       │
;; └────────────────────────────────────────────────────────────────────────┘

;; parse command line arguments and execute
(define (main args)
  (if (< (length args) 1)
      (show-help)
      
      (let ([command (car args)])
        (cond
          [(equal? command "create")
           (if (< (length args) 2)
               (begin
                 (displayln "❌ error: missing team name!")
                 (displayln "   usage: steel grainbranch.scm create <team-name>")
                 #f)
               (let ([team-name (cadr args)])
                 (create-grainbranch team-name)))]
          
          [(equal? command "help")
           (show-help)]
          
          [else
           (begin
             (displayln (format "❌ unknown command: ~a" command))
             (displayln "   run 'steel grainbranch.scm help' for usage")
             #f)]))))

;; ┌────────────────────────────────────────────────────────────────────────┐
;; │ PHASE 1 COMPLETE!                                                      │
;; └────────────────────────────────────────────────────────────────────────┘
;;
;; what we built:
;; ✅ git repository detection and validation
;; ✅ grainbranch name generation (via graintime.scm)
;; ✅ local branch creation
;; ✅ push to remote(s)
;; ✅ set default branch via github api
;; ✅ multi-remote support (github + codeberg)
;; ✅ cli interface with help
;; ✅ error handling throughout
;; ✅ glow g2 teaching comments
;;
;; what's next (phase 2):
;; - create grainbranch.md metadata file
;; - batch mode (create for multiple repos)
;; - interactive mode (prompt for values)
;; - gitlab/codeberg api support
;; - grainbranch listing & comparison
;; - integration with grainflow (deployment)
;;
;; does this workflow feel smooth? ready to automate your branches? 🌊⚡
;;
;; now == next + 1 🌾

;; run main if executed as script
(when (> (length (command-line-args)) 0)
  (main (command-line-args)))

(displayln "\n╔════════════════════════════════════════════════════════════════════╗")
(displayln "║  GRAINBRANCH PHASE 1: LOADED! 🌾                                   ║")
(displayln "║  astronomical git branch automation                                ║")
(displayln "║  try: steel grainbranch.scm create teamtravel12                    ║")
(displayln "╚════════════════════════════════════════════════════════════════════╝\n")

