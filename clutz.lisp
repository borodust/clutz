(cl:defpackage :clutz
  (:use :cl)
  (:export #:run
           #:application
           #:init
           #:destroy
           #:render
           #:window-size
           #:cursor-position
           #:mouse-button-state))
(cl:in-package :clutz)


(defclass application ()
  ((window :initform nil :accessor %window-of)
   (opengl-version :initarg :opengl-version :initform '(3 3))
   (window-title :initarg :window-title :initform "CLUTZ")
   (window-width :initarg :window-width :initform 640)
   (window-height :initarg :window-height :initform 480)
   (v-sync :initarg :v-sync :initform t :reader v-sync-enabled-p)))


(defgeneric render (application)
  (:method (app) (declare (ignore app))))


(defgeneric init (application)
  (:method (app) (declare (ignore app))))


(defgeneric destroy (application)
  (:method (app) (declare (ignore app))))


(defun create-window (application)
  (with-slots (opengl-version window-width window-height window-title) application
    (glfw:with-window-hints ((%glfw:+context-version-major+ (first opengl-version))
                             (%glfw:+context-version-minor+ (second opengl-version))
                             (%glfw:+opengl-profile+ %glfw:+opengl-core-profile+)
                             (%glfw:+opengl-forward-compat+ %glfw:+true+)
                             (%glfw:+depth-bits+ 24)
                             (%glfw:+stencil-bits+ 8))
      (%glfw:create-window window-width window-height window-title nil nil))))


(defun main (application)
  (when (= (%glfw:init) 0)
    (error "Failed to init GLFW"))
  (claw:c-let ((window %glfw:window :from (create-window application)))
    (when (claw:wrapper-null-p window)
      (%glfw:terminate)
      (error "Failed to create GLFW window"))
    (%glfw:make-context-current window)
    (glad:init)
    (when (v-sync-enabled-p application)
      (%glfw:swap-interval 1))
    (setf (%window-of application) window)
    (unwind-protect
         (progn
           (init application)
           (loop while (= (%glfw:window-should-close window) 0) do
             (%glfw:poll-events)
             (render application)
             (%glfw:swap-buffers window)))
      (unwind-protect
           (destroy application)
        (%glfw:destroy-window window)
        (%glfw:terminate)))))


(defun window-size (application &optional (vector (make-array 2 :element-type 'fixnum)))
  (claw:c-with ((height :int)
                (width :int))
    (%glfw:get-window-size (%window-of application) (width &) (height &))
    (setf (aref vector 0) width
          (aref vector 1) height)
    vector))


(defun cursor-position (application &optional (vector (make-array 2 :element-type 'double-float)))
  (claw:c-with ((x :double)
                (y :double))
    (%glfw:get-cursor-pos (%window-of application) (x &) (y &))
    (setf (aref vector 0) x
          (aref vector 1) y)
    vector))


(defun mouse-button-state (application button)
  (let ((button (ecase button
                  (:left %glfw:+mouse-button-left+)
                  (:right %glfw:+mouse-button-right+)
                  (:middle %glfw:+mouse-button-middle+))))
    (alexandria:switch ((%glfw:get-mouse-button (%window-of application) button) :test #'=)
      (%glfw:+press+ :pressed)
      (%glfw:+release+ :released)
      (%glfw:+repeat+ :repeating))))


(defun run (application &key (blocking t))
  (let ((standard-output *standard-output*))
    (flet ((run-masked ()
             (claw:with-float-traps-masked ()
               (handler-bind ((t (lambda (e)
                                   (format standard-output "~&Unhandled error:~&~A" e)
                                   (break "~A" e))))
                 (main application)))))
      (trivial-main-thread:call-in-main-thread #'run-masked :blocking blocking))))
