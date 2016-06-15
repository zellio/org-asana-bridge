;;; org-asana-bridge.el --- Bridge between org-mode and Asana tasks

;; Copyright (C) 2016 Zachary Elliott
;;
;; Authors: Zachary Elliott <contact@zell.io>
;; Maintainer: Zachary Elliott <contact@zell.io>
;; URL: http://github.com/zellio/org-asana-bridge
;; Created: 2016-06-14
;; Version: 0.3.0
;; Keywords: org-mode, elisp, project
;; Package-Requires: ((cl-lib "0.4") (request "0.2.0"0))

;; This file is not part of GNU Emacs.

;;; Commentary:

;;

;;; License:

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3 of the License, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
;; USA.

;;; Code:

(require 'cl-lib)
(require 'request)

(defconst org-asana-bridge-version "0.3.0"
  "`org-asana-bridge' version.")

(defgroup org-asana-bridge nil
  "`org-asana-bridge' application group."
  :group 'applications
  :link '(url-link :tag "Website for org-asana-bridge"
                   "https://github.com/zellio/org-asana-bridge"))

;;; org-asana-bridge.el ends here
