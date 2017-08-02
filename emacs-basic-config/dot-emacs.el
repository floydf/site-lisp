(setq load-path (append (list "~/.emacs.d/6.945-config") load-path))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         MIT-scheme config                        ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This is the place where you have installed scheme. Be sure to set
;; this to an appropriate value!!!
(setq scheme-root "/mit/6.945")

(setq scheme-program-name
      (concat
       scheme-root "/bin/mit-scheme "
       "--library " scheme-root "/lib/mit-scheme-x86-64 "
       "--band " scheme-root "/lib/mit-scheme-x86-64/all.com "
       "-heap 10000"))

;; Mac OS X: Uncomment the following versions of scheme-root and
;; scheme-program-name if you installed the pre-compiled Mac binary
;;
;; (setq scheme-root "/Applications/MIT-Scheme.app/Contents/Resources")
;;
;; (setq scheme-program-name
;;       (concat
;;        scheme-root "/mit-scheme "
;;        "--library " scheme-root " "
;;        "--band " scheme-root "/all.com "
;;        "-heap 10000"))

;; Use the Edwin-like MIT/Scheme interpreter:
(load "xscheme")

;; generic scheme completion
(require 'scheme-complete)
(autoload 'scheme-smart-complete "scheme-complete" nil t)
(autoload 'scheme-get-current-symbol-info "scheme-complete" nil t)
(setq lisp-indent-function 'scheme-smart-indent-function)

;; mit-scheme documentation
(require 'mit-scheme-doc)

;; Special keys in scheme mode. Use <tab> to indent scheme code to the
;; proper level, and use M-. to view mit-scheme-documentation for any
;; symbol.
(eval-after-load
 'scheme
 '(define-key scheme-mode-map "\t" 'scheme-complete-or-indent))

(eval-after-load
 'cmuscheme
 '(define-key inferior-scheme-mode-map "\t" 'scheme-complete-or-indent))

(eval-after-load
 'xscheme
 '(define-key scheme-interaction-mode-map "\t" 'scheme-complete-or-indent))

(eval-after-load
 'scheme
 '(define-key scheme-mode-map (kbd "M-.") 'mit-scheme-doc-lookup))

(eval-after-load
 'cmuscheme
 '(define-key inferior-scheme-mode-map (kbd "M-.")
    'mit-scheme-doc-lookup))

(eval-after-load
 'xscheme
 '(define-key scheme-interaction-mode-map (kbd "M-.")
    'mit-scheme-doc-lookup))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         Flash Paren Mode                         ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load "flash-paren")
(flash-paren-mode 1)
(setq flash-paren-delay 0.1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         Firefox Style Font Resizing              ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar rlm-default-font-size 160)
(defvar rlm-font-size
  rlm-default-font-size)

(defun change-font-size (num)
  (setq rlm-font-size (+ rlm-font-size num))
  (message (number-to-string rlm-font-size))
  (set-face-attribute 'default nil
		      :height rlm-font-size))

(defun font-increase ()
  (interactive)
  (change-font-size 3))

(defun font-decrease ()
  (interactive)
  (change-font-size -3))

(defun font-restore ()
  (interactive)
  (setq rlm-font-size rlm-default-font-size)
  (change-font-size 0))

;; Same bindings as Firefox
(global-set-key (kbd "C-+") 'font-increase)
(global-set-key (kbd "C--") 'font-decrease)
(global-set-key (kbd "C-=") 'font-restore)

(change-font-size 0)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         Firefox Style Fullscreen                 ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  From http://www.emacswiki.org/emacs/FullScreen
(defun toggle-fullscreen (&optional f)
  (interactive)
  (let ((current-value (frame-parameter nil 'fullscreen)))
    (set-frame-parameter
     nil 'fullscreen
     (if (equal 'fullboth current-value)
	 (if (boundp 'old-fullscreen) old-fullscreen nil)
       (progn (setq old-fullscreen current-value)
	      'fullboth)))))
;; again, same bindings as firefox
(global-set-key [f11] 'toggle-fullscreen)

;; start in fullscreen mode
;; (toggle-fullscreen)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         Print a Buffer to PDF  (C-c C-p)         ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun print-to-pdf ()
  (interactive)
  (ps-spool-buffer-with-faces)
  (switch-to-buffer "*PostScript*")
  (write-file "/tmp/tmp.ps")
  (kill-buffer "tmp.ps")
  (setq pdf-target-name (concat "/tmp/" (buffer-name) ".pdf"))
  (setq cmd (concat "ps2pdf14 /tmp/tmp.ps " "\"" pdf-target-name "\""))
  (shell-command cmd)
  (shell-command "rm /tmp/tmp.ps")
  (message (concat "Saved to:  " pdf-target-name)))

(global-set-key (kbd "C-c C-p") 'print-to-pdf)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;         Miscellaneous Settings                   ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq x-select-enable-clipboard 't)
(setq auto-mode-alist (cons '("README" . text-mode) auto-mode-alist))
;; activate auto-fill-mode for various other modes
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'scheme-mode-hook 'turn-on-auto-fill)
(defadvice save-buffers-kill-emacs (around no-query-kill-emacs activate)
  "Prevent annoying \"Active processes exist\" query when you quit Emacs."
  (flet ((process-list ())) ad-do-it))
(setq-default ispell-program-name "aspell")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Patch for xscheme - Fixing evaluate-expression in debugger ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun xscheme-prompt-for-expression-exit ()
  (interactive)
  (let (
	;; In Emacs 21+, during a minibuffer read the minibuffer
	;; contains the prompt as buffer text and that text is
	;; read only.  So we can no longer assume that (point-min)
	;; is where the user-entered text starts and we must avoid
	;; modifying that prompt text.  The value we want instead
	;; of (point-min) is (minibuffer-prompt-end).
	(point-min (if (fboundp 'minibuffer-prompt-end)
		              (minibuffer-prompt-end)
		            (point-min))))
    (if (eq (xscheme-region-expression-p point-min (point-max)) 'one)
        (exit-minibuffer)
      (error "input must be a single, complete expression"))))