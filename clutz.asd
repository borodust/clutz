(asdf:defsystem :clutz
  :description "Cross-platform utility toolkit for supporting simple Common Lisp OpenGL applications"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (alexandria trivial-main-thread claw glad-blob bodge-glad glfw-blob bodge-glfw)
  :components ((:file "clutz")))
