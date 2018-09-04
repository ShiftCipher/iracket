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

(define *use-jupyter-dir* (make-parameter #f))

;; ----

(define (get-jupyter-dir)
  (or (*use-jupyter-dir*)
      (let ([jupyter (find-executable-path "jupyter")])
        (and jupyter
             (string-trim
              (with-output-to-string
                (lambda () (system*/exit-code jupyter "--data-dir"))))))))

(define (get-racket-kernel-dir)
  (define jupyter-dir (get-jupyter-dir))
  (and jupyter-dir (build-path jupyter-dir "kernels" "racket")))

(define (write-iracket-kernel-json!)
  (define racket-kernel-dir
    (or (get-racket-kernel-dir)
        (raise-user-error "Cannot find jupyter configuration directory; try --jupypter-dir")))
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
   [("--jupyter-dir") use-jupyter-dir
    "Write to given jupyter configuration directory (normally `jupyter --data-dir`)"
    (*use-jupyter-dir* use-jupyter-dir)]
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
