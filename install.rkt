#lang racket/base
(require (for-syntax racket/base)
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

(define *use-ipython-dir* (make-parameter #f))

;; ----

(define (new-find-executable-path p)
  (find-executable-path (if (eq? (system-type 'os) 'windows)
                            (string-append p ".exe")
                            p)))

(define (ipython-exe)
  (or (new-find-executable-path "ipython")
      (raise-user-error "Cannot find ipython configuration directory; try --ipython-dir")))

(define (ipython-dir)
  (or (*use-ipython-dir*)
      (string-trim
       (with-output-to-string
         (lambda () (system*/exit-code (ipython-exe) "locate"))))))

(define (write-iracket-kernel-json!)
  (define racket-kernel-dir (build-path (ipython-dir) "kernels" "racket"))
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

(module* main #f
  (require racket/cmdline)
  (command-line
   #:program "iracket/install.rkt"
   #:once-any
   [("--ipython-dir") use-ipython-dir
    "Write to given ipython configuration directory"
    (*use-ipython-dir* use-ipython-dir)]
   #:args ()
   (write-iracket-kernel-json!)))

;; ----------------------------------------

;; raco setup hook; doesn't actually do installation, just prints message
(define (post-installer _parent _here _user? _inst?)
  (printf "\n***\n")
  (printf "*** IRacket must register its kernel with jupyter before it can be used.\n")
  (printf "*** Run `racket -l iracket/install` to finish installation.\n")
  (printf "***\n\n"))
(provide post-installer)
