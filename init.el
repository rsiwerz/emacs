;; Initialize package utilities  -*- lexical-binding: t; -*-
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load-file custom-file))

(defun require-package (package)
  "Installs the PACKAGE and returns non-nil if successful"
  (unless (package-installed-p package)
    (unless (assq package package-archive-contents)
      (package-refresh-contents))
    (package-install package))
  (package-installed-p package))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; macOS GUI Emacs doesn't inherit shell PATH; pull it in so mvn/rg/git resolve.
(when (and (memq window-system '(mac ns x))
           (require-package 'exec-path-from-shell))
  (exec-path-from-shell-initialize))

;; Languages??
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))

;; Looks & feels
;; Pulse
(require 'pulse)
(setq pulse-delay 0.05)
(defun rosi/pulse-current-line (&rest _)
  (pulse-momentary-highlight-one-line (point)))
(add-hook 'window-selection-change-functions 'rosi/pulse-current-line)

(dolist (cmd '(pop-to-mark-command
               pop-global-mark
               recenter-top-bottom
               exchange-point-and-mark))
  (advice-add cmd :after 'rosi/pulse-current-line))

(add-hook 'after-init-hook (lambda ()
			     (setq make-backup-files nil)
			     (setq auto-save-default nil)
			     (setq visible-bell t)
			     (menu-bar-mode -1)
			     (global-hl-line-mode)
			     (tool-bar-mode -1)
			     (scroll-bar-mode -1)
			     (global-auto-revert-mode t)
			     (set-frame-font "Hack 16")))

(add-hook 'prog-mode-hook 'display-line-numbers-mode)

;; (when (require-package 'modus-themes)
;;   (load-theme 'modus-vivendi-tinted t))

(when (require-package 'gruvbox-theme)
  (load-theme 'gruvbox-dark-hard t))

;; Magit
(when (require-package 'magit)
  (keymap-global-set "C-x g" 'magit-status)
  (setq magit-save-repository-buffers 'dontask))

;; Projectile
(when (require-package 'projectile)
  (projectile-global-mode)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

;; Vertico
(when (require-package 'vertico)
  (vertico-mode t))

;; Orderless: substring/space-separated matching for vertico+consult.
;; Without this, completion only matches prefixes — consult-line finds nothing
;; mid-line because buffer lines start with whitespace/code.
(when (require-package 'orderless)
  (setq completion-styles '(orderless basic)
        completion-category-overrides
        '((file (styles basic partial-completion)))))

;; Consult: search & navigation on top of vertico. Requires `rg` on PATH.
(when (require-package 'consult)
  (keymap-global-set "C-s"   'consult-line)
  (keymap-global-set "C-x b" 'consult-buffer)
  (keymap-global-set "M-g i" 'consult-imenu)
  (keymap-global-set "M-g I" 'consult-imenu-multi)
  (with-eval-after-load 'projectile
    (define-key projectile-command-map (kbd "s") 'consult-ripgrep))
  (setq xref-show-xrefs-function       'consult-xref
        xref-show-definitions-function 'consult-xref))

;; Compilation
(with-eval-after-load 'compile
  (setq compilation-ask-about-save nil)
  (setq compilation-always-kill t)
  (setq compilation-scroll-output t)
  ;; Make Maven/Java stacktrace lines clickable in *compilation*.
  (add-to-list 'compilation-error-regexp-alist
               '("\\s-+at .*(\\([A-Za-z0-9_]+\\.java\\):\\([0-9]+\\))" 1 2)))

;; Always show *compilation* as a full-width strip at the bottom,
;; regardless of how the main area is split.
(add-to-list 'display-buffer-alist
             '("\\*compilation\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.3)
               (preserve-size . (nil . t))))

(keymap-global-set "<f5>" 'compile)
(keymap-global-set "<f6>" 'recompile)

(keymap-global-set "M-n" 'next-error)
(keymap-global-set "M-p" 'previous-error)

(defun rosi/quit-compilation-window ()
  "Close the *compilation* window in place, restoring the prior layout."
  (interactive)
  (quit-windows-on "*compilation*"))
(keymap-global-set "<f7>" 'rosi/quit-compilation-window)

;; Buffer-based completion only. No LSP, no popups.
(keymap-global-set "M-/" 'hippie-expand)
(setq hippie-expand-try-functions-list
      '(try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-complete-file-name-partially
        try-complete-file-name))

;; Treesit
(when (treesit-available-p)
  (let ((treesit-install-directory (expand-file-name "tree-sitter" user-emacs-directory)))
    (make-directory treesit-install-directory t)
    (add-to-list 'treesit-extra-load-path treesit-install-directory))

  (setq treesit-font-lock-level 4)
  
  (setq treesit-language-source-alist
	'((java "https://github.com/tree-sitter/tree-sitter-java")
	  (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	  (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")))

  (unless (eq system-type 'windows-nt)
    (dolist (entry treesit-language-source-alist)
      (let ((lang (car entry)))
	(unless (treesit-language-available-p lang)
	  (treesit-install-language-grammar lang)))))
  
  (setq major-mode-remap-alist
	'((java-mode . java-ts-mode)
	  (c++-mode . c++-ts-mode)
	  (c-mode . c-ts-mode)
	  (typescript-mode . typescript-ts-mode))))

(with-eval-after-load 'java-ts-mode
  (define-key java-ts-mode-map (kbd "C-c c") 'project-compile))

(when (require-package 'apheleia)
  (with-eval-after-load 'apheleia
    (setf (alist-get 'java-ts-mode       apheleia-mode-alist) 'google-java-format
          (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier-typescript
          (alist-get 'tsx-ts-mode        apheleia-mode-alist) 'prettier-typescript)
    (setq apheleia-formatters-respect-indent-level nil))
  (add-hook 'typescript-ts-mode-hook 'apheleia-mode)
  (add-hook 'tsx-ts-mode-hook        'apheleia-mode))

(defun rosi/java-ts-google-continuation-indent ()
  "Override java-ts-mode continuation indent to match Google Java Style (+4).
java-ts-mode otherwise reuses the +2 block offset, which fights apheleia
on save inside argument lists, parameter lists, etc."
  (let ((rules (copy-alist treesit-simple-indent-rules)))
    (setf (alist-get 'java rules)
          (append '(((parent-is "argument_list")           parent-bol 4)
                    ((parent-is "formal_parameters")       parent-bol 4)
                    ((parent-is "array_initializer")       parent-bol 4)
                    ((parent-is "annotation_argument_list") parent-bol 4))
                  (alist-get 'java rules)))
    (setq-local treesit-simple-indent-rules rules)))

(add-hook 'java-ts-mode-hook
          (lambda ()
            (setq-local java-ts-mode-indent-offset 2)
            (setq-local indent-tabs-mode nil)
            (setq-local fill-column 100)
            (setq-local compile-command "mvn -B -q compile ")
            (rosi/java-ts-google-continuation-indent)
            (display-fill-column-indicator-mode 1)
            (subword-mode 1)
            (electric-pair-local-mode 1)
            (apheleia-mode 1)))

(add-hook 'c++-ts-mode-hook
	  (lambda ()
	    (setq-local indent-tabs-mode nil)
	    (setq-local fill-column 100)
	    (setq-local compile-command "build")
	    (setq-local c-ts-mode-indent-offset 4)
	    (display-fill-column-indicator-mode 1)
	    (electric-pair-local-mode 1)))

