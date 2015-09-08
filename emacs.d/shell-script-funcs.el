;;; shell-script-funcs --- Utility functions for shell script conversions

;;; Commentary:

;; A collection of functions helpful in attempting to translate shell
;; scripts into Elisp scripts.

(require 'em-glob)

;;; Code:

(defun tb/substring-replace (old-str new-str beg end)
  "Return a new string where a subsection of OLD-STR has been replaced with NEW-STR beginning at position BEG and ending at END."
   (concat (substring old-str 0 beg) new-str (substring old-str end)))


(defun tb/getvar (var-name)
  "Return value of a variable or environment variable specified by VAR-NAME."
  (or (getenv var-name) (eval (read var-name))))

;; (tb/getvar "user-emacs-directory")
;; (tb/getvar "HOME")


(defun tb/substr-variables (str)
  "Replace shell-like '$VAR' and '${variables}' in STR with the equivalent environment variables or Elisp variables. For instance: $HOME/.emacs.d could return /home/tbekolay/.emacs.d -- Keep in mind that this is just a string, it does not do any validation to see if any files exist."

  ;; This function recursively calls this function with more and more
  ;; embedded variables substituted out, until no more variables are
  ;; found, and then it returns the results.
  ;;
  ;; Begin by checking to see if the string starts with ~ ...
  (if (string-prefix-p "~/" str)
      (tb/substr-variables
       (concat (getenv "HOME") (substring str 1)))

    ;; Variables can either be simple $BLAH or ${some-larger}...
    (let ((s (or (string-match "${\\([^ ]*\\)}" str)
                 (string-match "$\\([A-z_]*\\)" str)))
          (e (match-end 0)))
      (if (not s)             ; No $ matches?
          str                 ; Then just return the string.
        (tb/substr-variables  ; Recursively call with first var sub'd
         (tb/substring-replace str (tb/getvar (match-string 1 str)) s e))))))

;; (tb/substr-variables "$HOME/.emacs.d/elisp/*.el")
;; (tb/substr-variables "~/.emacs.d/elisp/*.el")
;; (tb/substr-variables "${user-emacs-directory}elisp/*.el")


(defun tb/get-files (path &optional full)
  "Return list of files that match the glob pattern, PATH. Allowing shell-like variable substitution from the environment, like $HOME, or from variables defined by `setq'. If FULL is specified, return absolute pathnames for each file."
  (let ((subbed-path (tb/substr-variables path)))
    (condition-case nil
        (directory-files (file-name-directory subbed-path)
                         full
                         (eshell-glob-regexp
                          (file-name-nondirectory subbed-path)))
      (error '()))))

;; (tb/get-files "$HOME/.emacs.d/elisp/*.el")
;; => ("init-blog.el" "init-client.el" "init-clojure.el" ...)

;; (tb/get-files "$HOME/.emacs.d/elisp/*.el" t)
;; => ("/home/howard/.emacs.d/elisp/init-blog.el" "/home/howard/.emacs.d/elisp/init-client.el" ...)

;; (tb/get-files "${user-emacs-directory}/elisp/*.el")
;; => ("init-blog.el" "init-client.el" "init-clojure.el" ...)

;; (tb/get-files "/foo/bar/*")  => nil


(defun tb/get-path (path)
  "Return a file specification based on PATH. We should expand this function so that glob patterns work when specifying the parent, but shouldn't worry about matching any particular file."
  (tb/substr-variables path))

;; (tb/get-path "$HOME/.emacs.d/elisp/*.el" t)
;; (tb/get-path "/foo/bar" t)


;; ----------------------------------------------------------------------

;; The following functions are basic "shell" like functions that take
;; a path that refers to files. This allows us to not have to call
;; (tb/get-files) directly.

(defun tb/mkdir (path)
  "Create a directory specified by PATH, which can contain embedded environment variables and Emacs variables, e.g. '$HOME/Work/foobar'."
  (make-directory (tb/get-path path) t))


(defun tb/mksymlink (orig link)
  "Create symbolic line to ORIG. If LINK is an existing link, it is deleted first. LINK could also refer to a directory. Note: Both parameters are strings that can accept embedded environment and Lisp variables, e.g. '$HOME/Work/foo.el' and '${user-emacs-directory}/elisp/bar.el'."
  (let ((orig-file (tb/get-path orig))
        (link-file (tb/get-path link)))

    (if (file-symlink-p link-file)
        (delete-file link-file))
    ;; (message "%s -> %s" orig-file link-file)
    (make-symbolic-link orig-file link-file t)))


(defun tb/mksymlinks (files dest)
  "Create an absolute symbolic link for each file specified in FILES into the directory, DEST (where each link will have the same name). Both parameters can be specified with glob patterns and embedded environment and Emacs variables, e.g. '$HOME/.emacs.d/*.el'."
  (mapc (lambda (file) (tb/mksymlink file dest)) (tb/get-files files t)))


(defun tb/mkdirs (path)
  "Create one or more directories specified by PATH, which can contain embedded environment variables and Emacs variables, e.g. '$HOME/Work/foobar'."
  (mapc (lambda (dir) (make-directory dir t)) (tb/get-files path)))


(provide 'shell-script-funcs)
;;; shell-script-funcs ends here
