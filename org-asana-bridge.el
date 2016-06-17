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

(defcustom org-asana-bridge-access-token "*TOKEN*"
  "Asana API personal access token.

Personal access tokens provide individuals with a low friction
means to access the Asana API when writing scripts, working with
command line utilities, or prototyping applications."
  :type 'string
  :group 'org-asana-bridge)

(defcustom org-asana-bridge-api-base-uri "https://app.asana.com/api/1.0"
  "Base uri for Asana API Access.

You should probably not change this. This should probably not be
a custom variable."
  :type 'string
  :group 'org-asana-bridge)

(defun org-asana-bridge-request-headers ()
  "Request headers for Asana API access.

These are generated for each call rather than being static incase
you've changed your access token for some reason."
  `(("Content-type" . "application/json")
    ("Authorization" . ,(format "Bearer %s" org-asana-bridge-access-token))))

(defcustom org-asana-bridge-cache-dir
  (expand-file-name ".org-asana-bridge" "~")
  "Parent directory for the `org-asana-bridge' file cache.

This is used to store fetched data for caching and processing to
speed up exection time."
  :type 'string
  :group 'org-asana-bridge)

(defmacro org-asana-bridge--assocdr (key alist)
  "Internal macro for `org-asana-bridge'.

Returns cdr of an assoc. I got tired of writing it."
  `(cdr (assoc ,key ,alist)))

(defun org-asana-bridge--url (&rest args)
  "Internal function for `org-asana-bridge'.

Generates an Asana API url."
  (mapconcat 'identity (cons org-asana-bridge-api-base-uri args) "/"))

(cl-defun org-asana-bridge--request
    (url &key callback (type "GET") data params (sync t))
  "Internal function for `org-asana-bridge'.

Send request against the Asana API. See their documentation for
more informaiton"
  (request
   url
   :headers (org-asana-bridge-request-headers)
   :data data
   :params params
   :parser '(lambda ()
              (org-asana-bridge--assocdr 'data (json-read)))
   :error (cl-function
           (lambda (&rest args)
             (message "%s" args)))
   :success callback
   :sync sync))

(defun org-asana-bridge--serialize (data path)
  "Internal function for `org-asana-bridge'.

Serialize the s-expr DATA into file at PATH."
  (let ((dir (file-name-directory path)))
    (if (not (file-directory-p dir))
        (mkdir dir t))
    (with-temp-buffer
      (insert
       ";; -*- mode: lisp; coding: utf-8 -*-\n"
       ";; org-asana-bridge-version: " org-asana-bridge-version "\n"
       "\n"
       (prin1-to-string data))
      (write-file path nil))
    ))

(defun org-asana-bridge--deserialize (file)
  "Internal function for `org-asana-bridge'.

Deserialize the file at PATH into an s-expr."
  (if (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (read (current-buffer)))
    '()))

(defun org-asana-bridge--cache-file (label)
  "Internal function for `org-asana-bridge'.

Generate a cache path for a given key value. If you are writing
to or reading from the data-cache you should be using this
function to locate the file."
  (expand-file-name
   (format "%s.list" label) org-asana-bridge-cache-dir))


(cl-defun org-asana-bridge--fetch-data
    (url-components path &key params)
  "Internal function for `org-asana-bridge'.

Fetch data from the Asana API and serialize into PATH"
  (org-asana-bridge--request
   (apply 'org-asana-bridge--url url-components)
   :params params
   :callback (cl-function
              (lambda (&key data &allow-other-keys)
                (org-asana-bridge--serialize data path)))
   ))

(defcustom org-asana-bridge-user-cache-file
  (org-asana-bridge--cache-file "user")
  "`org-asana-bridge' user cache file.")

(defun org-asana-bridge-fetch-user-data ()
  "Fetch and cache user data from the Asana API."
  (org-asana-bridge--fetch-data
   '("users" "me") org-asana-bridge-user-cache-file))

(defun org-asana-bridge-fetch-workspace-tasks-data (id)
  "Fetch and cache workspace tasks from the Asana API."
  (org-asana-bridge--fetch-data
   '("tasks")
   (org-asana-bridge--cache-file id)
   :params `(("assignee" . "me")
             ("workspace" . ,(prin1-to-string id))
             ("opt_fields" . "name,notes,completed_at,completed,due_on,due_at,created_at,modified_at,tags.name"))
   ))

(defun org-asana-bridge--load-data (file fetcher)
  "Internal function for `org-asana-bridge'."
  (or (file-exists-p file) (funcall fetcher))
  (org-asana-bridge--deserialize file))

(defun org-asana-bridge-load-user-data ()
  ""
  (org-asana-bridge--load-data
   org-asana-bridge-user-cache-file
   'org-asana-bridge-fetch-user-data))

(defun org-asana-bridge-load-workspace-tasks-data (id)
  ""
  (org-asana-bridge--load-data
   (org-asana-bridge--cache-file id)
   (apply-partially
    'org-asana-bridge-fetch-workspace-tasks-data id)))

(defun org-asana-bridge-load-asana-data ()
  ""
  (let* ((user-data (org-asana-bridge-load-user-data)))
    (cl-loop
     for workspace across (org-asana-bridge--assocdr 'workspaces user-data)
     for workspace-id = (org-asana-bridge--assocdr 'id workspace)
     collect (cons workspace-id
                   (org-asana-bridge-load-workspace-tasks-data workspace-id)))
    ))

(defun* org-asana-bridge--asana-datestamp-to-org-sexpr
    (datestamp &optional (type 'active))
  ""
  (cl-destructuring-bind
      (sec min hour day mon year dow dst tz)
      (parse-time-string
       (replace-regexp-in-string "[TZ]" " " datestamp))
    (list
     'timestamp
     (list
      :type type
      :year-start year
      :month-start mon
      :day-start day
      :hour-start hour
      :minute-start min
      :pre-blank 0
      :post-blank 0))))

(defun org-asana-bridge--task-asana-sexpr-to-org-sexpr (task)
  ""
  (let* ((due-datestamp
          (or (org-asana-bridge--assocdr 'due_at task)
              (org-asana-bridge--assocdr 'due_on task)))
         (due-date
          (and due-datestamp
               (org-asana-bridge--asana-datestamp-to-org-sexpr due-datestamp)))
         (completed-datestamp
          (org-asana-bridge--assocdr 'completed_at task))
         (completed-date
          (and completed-datestamp
               (org-asana-bridge--asana-datestamp-to-org-sexpr
                completed-datestamp 'inactive)))
         (tags
          (mapcar (lambda (tag)
                    (org-asana-bridge--assocdr 'name tag))
                  (org-asana-bridge--assocdr 'tags task)))
         (todo-keyword
          (if (eq :json-false (org-asana-bridge--assocdr 'completed task))
              "TODO" "DONE"))
         (todo-type (intern (downcase todo-keyword))))
    (list
     'headline
     (list
      :closed completed-date
      :deadline due-date
      :level 3
      :pre-blank 0
      :post-blank 1
      :tags tags
      :title (org-asana-bridge--assocdr 'name task)
      :todo-keyword todo-keyword
      :todo-type todo-type)
     `(section
       nil
       (planning
        (:closed ,completed-date
                 :deadline ,due-date))
       (property-drawer
        (:post-blank 1)
        ,@(mapcar
           (lambda (key)
             `(node-property
               (:key ,(upcase (format "%s" key))
                :value ,(org-asana-bridge--assocdr key task))))
           ;; '(id created_at due_on due_at modified_at)
           '(id modified_at)))))
    ))

(defun org-asana-bridge--asana-sexpr-to-org-sexpr (data)
  ""
  `(headline
    (:title
     "org-asana-bridge: generated task list"
     :level 1
     :pre-blank 0
     :post-blank 0)
    (section
     nil
     ,(cl-loop
       for workspace in data
       for workspace-id = (car workspace)
       for workspace-data = (cdr workspace)
       collect
       `(headline
         (:title
          ,(format "workspace: %d" workspace-id)
          :level 2
          :pre-blank 0
          :post-blank 0)
         ,(cl-loop
           for task across workspace-data
           collect (org-asana-bridge--task-asana-sexpr-to-org-sexpr task)))
       ))
    ))

(defun org-asana-bridge--org-sexpr-to-asana-datestamp (date)
  ""
  (format
   "%04d-%02d-%02dT%02d:%02d:00.000Z"
   (org-element-property :year-start date)
   (org-element-property :month-start date)
   (org-element-property :day-start date)
   (org-element-property :hour-start date)
   (org-element-property :minute-start date)
   (org-element-property :minute-start date)))

(defun org-asana-bridge--task-org-sexpr-to-asana-sexpr (task)
  ""
  )

(defun org-asana-bridge--org-sexpr-to-asana-sexpr (data)
  ""
  )

;; (save-current-buffer
;;   (set-buffer (get-buffer-create "*org-asana-bridge-file-cache*"))
;;   (erase-buffer)
;;   (insert
;;    (org-element-interpret-data
;;     (org-asana-bridge--asana-sexpr-to-org-sexpr
;;      (org-asana-bridge-load-asana-data)))))

;;; org-asana-bridge.el ends here
