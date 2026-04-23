;; Initialize package utilities

(defun require-package (package)
  "Installs the PACKAGE and returns non-nil if successful"
  (unless (package-installed-p package)
    (when (not package-archive-contents)
      (package-refresh-contents))
    (package-install package))
  (package-installed-p package))

(require 'package)
(package-initialize)

;; Looks & feels
(add-hook 'after-init-hook (lambda ()
			     (setq make-backup-files nil)
			     (menu-bar-mode -1)
			     (tool-bar-mode -1)
			     (scroll-bar-mode -1)
			     (set-frame-font "Iosevka 16")))

(when (require-package 'modus-themes)
  (load-theme 'modus-vivendi-tinted t))

;; Magit
(require-package 'magit)

(when (require-package 'magit)
  (keymap-global-set "C-x g" 'magit-status))


;; TODO(robert): remove this?
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
