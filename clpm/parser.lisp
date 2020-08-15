;;;; Parser

;;; Copyright (c) 2020, Valentine Kiselev

;;; All rights reserved.

;;; Redistribution and use in source and binary forms, with or without modification,
;;; are permitted provided that the following conditions are met:

;;;     * Redistributions of source code must retain the above copyright notice,
;;;       this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright notice,
;;;       this list of conditions and the following disclaimer in the documentation
;;;       and/or other materials provided with the distribution.
;;;     * Neither the name of clpm nor the names of its contributors
;;;       may be used to endorse or promote products derived from this software
;;;       without specific prior written permission.

;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;;; CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :clpm)

;;; Parameters

(defparameter *interpreter* '((:name . :sbcl))
  "Lisp interpreter settings")

(defparameter *scopes* (make-hash-table)
  "The hash table of scoped dependencies")

;;; Parsing code

;;; Set interpreter requirements
;;;
;;; Example:
;;;   (lisp :sbcl >= "1.2.3")
(defmacro lisp (&rest definition)
  `(setf *interpreter* (remove-if #'(lambda (cell) (null (cdr cell)))
                                  (list
                                   (cons :name (first ',definition))
                                   (cons :constraint (second ',definition))
                                   (cons :version (third ',definition))))))

(defun add-system-to-scope (&key scope name git tag)
  (let* ((scope-metadata (gethash scope *scopes*))
         (new-scopep (null scope-metadata))
         (metadata (remove-if #'(lambda (cell) (null (cdr cell)))
                              (list
                               (cons :git git)
                               (cons :tag tag)))))
    (when new-scopep
      (setf scope-metadata (make-hash-table)))
    (setf (gethash name scope-metadata) metadata)
    (when new-scopep
      (setf (gethash scope *scopes*) scope-metadata))))

(defun find-by-key (key list)
  (when list
    (elt list (1+ (position key list :test #'eql)))))

;;; Set dependencies by scope
;;;
;;; Example:
;;;   (scope :development
;;;     (:package-name >= "1.2.3"))
;;;
;;; Note:
;;;   Use keywords for scope and package names
(defmacro scope (key &rest systems)
  (let ((definition (gensym)))
    `(dolist (,definition ',systems)
       (add-system-to-scope :scope ,key
                            :name (first ,definition)
                            :git (find-by-key :git (cdr ,definition))
                            :tag (find-by-key :tag (cdr ,definition))))))

(defun install (&key scope)
  (format t "Installing scope: ~a ~%" scope))
