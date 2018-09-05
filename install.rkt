#lang racket/base
(require (for-syntax racket/base)
         racket/cmdline
         raco/command-name
         racket/match
         racket/string
         racket/file
         racket/port
         racket/system
         racket/runtime-path)

;; Script for configuring iracket.

;; TODO:
;; - add c3 support installation
;; - uninstallation?

(define-runtime-path iracket-dir ".")
(define-runtime-path kernel-path "static/kernel.json")
(define-runtime-path-list js-paths (list "static/custom.js" "static/c3.js"))

(define *use-jupyter-exe* (make-parameter #f string->path))

(define (get-jupyter-exe [fail-ok? #f])
  (or (*use-jupyter-exe*)
      (find-executable-path "jupyter")
      (if fail-ok? #f (raise-user-error "Cannot find jupyter executable."))))

(define (get-jupyter-dir [fail-ok? #f])
  (let ([jupyter (get-jupyter-exe fail-ok?)])
    (cond [jupyter
           (string->path
            (string-trim
             (with-output-to-string
               (lambda ()
                 (define s (system*/exit-code jupyter "--data-dir"))
                 (unless (zero? s)
                   (raise-user-error "Received non-zero exit code from jupyter command."))))))]
          [fail-ok? #f]
          [else (raise-user-error "Cannot find jupyter data directory.")])))

(define (get-racket-kernel-dir [fail-ok? #f])
  (define jupyter-dir (get-jupyter-dir fail-ok?))
  (and jupyter-dir (build-path jupyter-dir "kernels" "racket")))

;; ============================================================
;; Commands

;; ----------------------------------------
;; Check status

(define (cmd:check args)
  (command-line
   #:program (short-program+command-name)
   #:argv args
   #:once-any
   [("--jupyter-exe") jupyter
    "Use given jupyter executable"
    (*use-jupyter-exe* jupyter)]
   #:args ()
   (check-iracket-kernel)))

(define (check-iracket-kernel)
  (with-handlers ([exn:fail:user?
                   (lambda (e) (printf "~a\n" (exn-message e)))])
    (define jupyter (get-jupyter-exe))
    (printf "Jupyter executable: ~v\n" (path->string jupyter))
    (define jupyter-dir (get-jupyter-dir))
    (printf "Jupyter data directory: ~v\n" (path->string jupyter-dir))
    (define kernel-dir (get-racket-kernel-dir))
    (define kernel-path (build-path kernel-dir "kernel.json"))
    (printf "Racket kernel path: ~v\n" (path->string kernel-path))
    (printf "Racket kernel exists?: ~a\n" (if (file-exists? kernel-path) "yes" "no"))
    (void))
  (void))

;; ----------------------------------------
;; Install kernel

(define (cmd:install args)
  (command-line
   #:program (short-program+command-name)
   #:argv args
   #:once-any
   [("--jupyter-exe") jupyter
    "Use given jupyter executable"
    (*use-jupyter-exe* jupyter)]
   #:args ()
   (write-iracket-kernel-json!)))

(define (write-iracket-kernel-json!)
  (define racket-kernel-dir (get-racket-kernel-dir))
  (make-directory* racket-kernel-dir)
  (define kernel-json
    (regexp-replace* (regexp-quote "IRACKET_SRC_DIR")
                     (file->string kernel-path)
                     (path->string iracket-dir)))
  (define dest-file (build-path racket-kernel-dir "kernel.json"))
  (when (file-exists? dest-file)
    (printf "Replacing old ~s\n" (path->string dest-file)))
  (with-output-to-file dest-file #:exists 'truncate/replace
    (lambda () (write-string kernel-json)))
  (printf "Kernel json file copied to ~s\n" (path->string dest-file)))

;; ----------------------------------------
;; Help

(define (cmd:help _args)
  (printf "Usage: ~a <command> <option> ... <arg> ...\n\n"
          (short-program+command-name))
  (printf "Commands:\n")
  (define command-field-width
    (+ 4 (apply max 12 (map string-length (map car subcommand-handlers)))))
  (for ([subcommand (in-list subcommand-handlers)])
    (match-define (list command _ help-text) subcommand)
    (define pad (make-string (- command-field-width (string-length command)) #\space))
    (printf "  ~a~a~a\n" command pad help-text)))

;; ============================================================
;; Main (command dispatch)

(define subcommand-handlers
  `(("help"    ,cmd:help     "show help")
    ("check"   ,cmd:check    "check IRacket configuration")
    ("install" ,cmd:install  "register IRacket kernel with Jupyter")))

(define (call-subcommand handler name args)
  (parameterize ((current-command-name
                  (cond [(current-command-name)
                         => (lambda (prefix) (format "~a ~a" prefix name))]
                        [else #f])))
    (handler args)))

(module+ raco
  (define args (vector->list (current-command-line-arguments)))
  (cond [(and (pair? args) (assoc (car args) subcommand-handlers))
         => (lambda (p) (call-subcommand (cadr p) (car args) (cdr args)))]
        [else (cmd:help args)]))

;; ============================================================
;; raco setup hook

(provide installer)

(define (installer _parent _here _user? _inst?)
  (define kernel-dir (get-racket-kernel-dir #t))
  (define kernel-path (and kernel-dir (build-path kernel-dir "kernel.json")))
  (cond [(not kernel-path)
         (void)]
        [(and kernel-path (file-exists? kernel-path))
         (when #f
           (printf "IRacket kernel found in ~a.\n" (path->string kernel-dir)))]
        [else
         (printf "\n***\n")
         (printf "*** IRacket must register its kernel with jupyter before it can be used.\n")
         (printf "*** Run `raco iracket install` to finish installation.\n")
         (printf "***\n\n")]))
