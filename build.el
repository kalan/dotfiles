#!/usr/bin/env emacs
;;; build -- Set up all the dotfiles

;;; Commentary:

;; Simple Emacs script used to build/tangle all my support
;; environmental dotfiles.
;;
;; This is stolen from the super impressive dotfiles of Howard Abrams
;; at https://github.com/howardabrams/dotfiles.

;;; Code:

(require 'org)         ;; The org-mode goodness
(require 'ob)          ;; org-mode export system
(require 'ob-tangle)   ;; org-mode tangling process
(add-to-list 'load-path "emacs.d")
(require 'shell-script-funcs)    ;; Special functions for doing scripts

;; Need to get the directory to my 'dotfiles' source code. While
;; developing, we just evaluate this buffer, so 'buffer-file-name' is
;; our friend. If we load this file instead, we need to use
;; 'load-file-name':
(defconst dotfiles-src (if load-file-name
                           (file-name-directory load-file-name)
                           (file-name-directory (buffer-file-name))))

;; Where all of the .el files will live and play:
(defconst dest-elisp-dir (tb/get-path "${user-emacs-directory}/elisp"))

;; The Script Part ... here we do all the building and compilation work.

(defun tb/build-dotfiles ()
  "Takes all the dotfiles in this directory and deploys a new
environment (or updates an existing system)."
  (interactive)

  ;; Initially create some of the destination directories
  (tb/mkdir "${user-emacs-directory}/elisp")
  (tb/mkdir "${HOME}/bin")

  ;; Tangle .org files
  (tb/tangle-files "${dotfiles-src}/*.org")

  ;; Some Elisp files are just symlinked instead of tangled
  (tb/mksymlinks "${dotfiles-src}/emacs.d/*.el"
                 "${user-emacs-directory}/elisp")

  ;; Also symlink scripts in bin directory
  (tb/mksymlinks "${dotfiles-src}/bin/[a-z]*"
                 "${HOME}/bin")

  ;; All of the .el files I've either tangled or linked should be comp'd:
  (mapc 'byte-compile-file
        (tb/get-files "${user-emacs-directory}/elisp/*.el" t))

  (message "Finished building dotfiles. Restart Emacs."))


(defun tb/tangle-file (file)
  "Given an 'org-mode' FILE, tangle the source code."
  (interactive "Org File: ")
  (find-file file)
  (org-babel-tangle)
  (kill-buffer))


(defun tb/tangle-files (path)
  "Given a directory, PATH, of 'org-mode' files, tangle the source
code out of all literate programming files."
  (interactive "D")
  (mapc 'tb/tangle-file (tb/get-files path)))


(defun tb/get-dotfiles ()
  "Pulls and builds the latest from the Github repository.  We
then load the resulting Lisp code."
  (interactive)
  (let ((git-results
         (shell-command (concat "cd " dotfiles-src "; git pull"))))
    (if (not (= git-results 0))
        (message "Can't pull the goodness. Pull from git by hand.")
      (load-file (concat dotfiles-src "/emacs.d/shell-script-funcs.el"))
      (load-file (concat dotfiles-src "/build.el"))
      (require 'init-main))))

(tb/build-dotfiles)  ;; Do it

(provide 'dotfiles)
;;; build.el ends here
