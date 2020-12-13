;;; nix-spacemacs.el --- summary -*- lexical-binding: t -*-

;; Author: timor
;; Maintainer: timor
;; Version: 1.0
;; Package-Requires:


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Support code for building a snapshotable spacemacs+packages bundle using nix.

;;; Code:

;; This code is adapted from
;; https://github.com/puffnfresh/nix-files/blob/28a959cde7cbb2ad2ec1e73291c50247e947c219/spacemacs/spacemacs2nix.el

(defgroup nix-spacemacs nil
  "Rebuild Spacemacs using nix.")

(defcustom nix-spacemacs-nix-expression "<nixpkgs>"
  "Shell argument passed to nix-env -f.  Will be single-quoted on invocation.")

(defcustom nix-spacemacs-custom-source nil
  "If set, override the src attribute of the spacemacs derication during rebuild.")

(defcustom nix-spacemacs-use-emacs-overlay t
  "If set (default), use the nix-community/emacs-overlay.")

(defun nix-spacemacs-packages ()
  "Return list of packages to install based on currently loaded layers."
  (cl-loop for sym in configuration-layer--used-packages
           for pkg = (configuration-layer/get-package sym)
           when (and (not (package-built-in-p sym))
                     (cfgl-package-toggled-p pkg)
                     (eq (oref pkg :location) 'elpa))
           collect pkg))

(defun nix-spacemacs-generate-expression (outfile)
  "Generate nix expression for packages.

Using the currently loaded configuration-layer, return a nix
expression that can be passed to emacsWithPackages, write that to
OUTFILE."
  (message "Writing to %s" outfile)
  (with-temp-file outfile
    (insert "
# Generated by spacemacs2nix.el
let inherit ((import <nixpkgs> {}).lib) warn; in
p:
let checked = n:
  let
    p' = p.${n} or null;
    in
    if (p' == null) then
      warn \"Package '${n}' not found, not including.\" null
    else if (p'.meta.broken or false) then
      warn \"Package '${p'.name}' marked as broken, not including.\" null
    else if (p'.name == \"org\") then p.org-plus-contrib
    else p';
in [\n")
    (insert (with-output-to-string
              (let ((packages (if (boundp 'nix-build-spacemacs-packages)
                                  (configuration-layer//filter-distant-packages
                                   nix-build-spacemacs-packages nil) ; set by packages-from-dotfile.nix
                                (mapcar (lambda (x) (oref x :name)) (nix-spacemacs-packages)))))
                (dolist (pkg packages)
                 (princ (format "    (checked \"%s\") \n" pkg))))))
    (insert "]\n")))

(defun nix-spacemacs-update-nix-env ()
  "Build a spacemacs with fixed dotfile and package set based on currently loaded configuration"
  (interactive)
  (let* ((buffer (get-buffer-create "*Nix-Spacemacs-Update-Env*"))
         (expr-file (make-temp-file "spacemacs-emacs-packages" nil ".nix"))
         (result-link (expand-file-name (make-temp-name "nix-spacemacs-update-env-result")
                                        temporary-file-directory))
         (pkgs-extend (if nix-spacemacs-use-emacs-overlay
                          ".extend(import (builtins.fetchTarball { url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz; }))"
                        ""))
         (commands (list "nix-build" "-E"
                         (format "with (import %s {})%s; (spacemacs.override{dotfile = %s;}).overrideAttrs (oa: %s)"
                                 nix-spacemacs-nix-expression
                                 pkgs-extend
                                 (dotspacemacs/location)
                                 ;; expr-file
                                 (if nix-spacemacs-custom-source
                                     (format "{src=%s;}" nix-spacemacs-custom-source)
                                   "{}"))
                         "-o" result-link)))
    (display-buffer buffer)
    (with-current-buffer buffer
      (erase-buffer)
      (insert "Running command list:\n" (format "%s" commands) "\n"))
    (nix-spacemacs-generate-expression expr-file)
    (make-process
     :name "nix-spacemacs-update-env"
     :buffer buffer
     :command commands
     :sentinel (lambda (p event)
                 (let* ((nix-env-cmd (format "nix-env -i '%s'" result-link))
                        (new-invocation-dir (file-truename (expand-file-name "bin" result-link)))
                        (invocation-directory new-invocation-dir))
                   (if (and (eq 'exit (process-status p))
                            (= 0 (process-exit-status p))
                            (progn
                              (with-current-buffer buffer
                                (insert "\nInvocation directory of newly built Spacemacs: " new-invocation-dir "\n")
                                (goto-char (point-max)))
                              (y-or-n-p "Building Spacemacs successful.  Install into current profile?")))
                       (progn (with-current-buffer buffer
                                (insert (format "Running '%s'" nix-env-cmd) "\n"))
                              (if (= 0 (call-process-shell-command nix-env-cmd nil buffer t))
                                  (progn
                                    (delete-file result-link)
                                    (when (y-or-n-p "Restart Spacemacs?")
                                      (spacemacs/restart-emacs)))
                                (message "Error during nix-env profile installation.")))
                     (internal-default-process-sentinel p event)))
                 (unless (process-live-p p)
                   (delete-file result-link))))))

(provide 'nix-spacemacs)

;;; nix.el ends here