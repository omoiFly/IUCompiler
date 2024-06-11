#lang racket
(require racket/set racket/stream)
(require racket/fixnum)
(require "interp.rkt")
(require "interp-Lint.rkt")
(require "interp-Lvar.rkt")
(require "interp-Cvar.rkt")
(require "type-check-Lvar.rkt")
(require "type-check-Cvar.rkt")
(require "utilities.rkt")
(provide (all-defined-out))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lint examples
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; The following compiler pass is just a silly one that doesn't change
;; anything important, but is nevertheless an example of a pass. It
;; flips the arguments of +. -Jeremy
(define (flip-exp e)
  (match e
    [(Var x) e]
    [(Prim 'read '()) (Prim 'read '())]
    [(Prim '- (list e1)) (Prim '- (list (flip-exp e1)))]
    [(Prim '+ (list e1 e2)) (Prim '+ (list (flip-exp e2) (flip-exp e1)))]))

(define (flip-Lint e)
  (match e
    [(Program info e) (Program info (flip-exp e))]))


;; Next we have the partial evaluation pass described in the book.
(define (pe-neg r)
  (match r
    [(Int n) (Int (fx- 0 n))]
    [else (Prim '- (list r))]))

(define (pe-add r1 r2)
  (match* (r1 r2)
    [((Int n1) (Int n2)) (Int (fx+ n1 n2))]
    [(_ _) (Prim '+ (list r1 r2))]))

(define (pe-exp e)
  (match e
    [(Int n) (Int n)]
    [(Prim 'read '()) (Prim 'read '())]
    [(Prim '- (list e1)) (pe-neg (pe-exp e1))]
    [(Prim '+ (list e1 e2)) (pe-add (pe-exp e1) (pe-exp e2))]))

(define (pe-Lint p)
  (match p
    [(Program info e) (Program info (pe-exp e))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HW1 Passes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (uniquify-exp env)
  (lambda (e)
    (match e
      [(Var x) (Var (dict-ref env x))]
      [(Int n) (Int n)]
      [(Let x e body)
       (let (
             [k (gensym x)]
             [v ((uniquify-exp env) e)])
         (let (
               [new-env (dict-set env x k)])
           (Let k v ((uniquify-exp new-env) body))))]
      [(Prim op es)
       (Prim op (for/list ([e es]) ((uniquify-exp env) e)))])))

;; uniquify : Lvar -> Lvar
(define (uniquify p)
  (match p
    [(Program info e) (Program info ((uniquify-exp '()) e))]))

;; remove-complex-opera* : Lvar -> Lvar^mon
(define (rco-atom e)
  (match e
    [(Var x) (values (Var x) '())]
    [(Int x) (values (Int x) '())]
    [(Let x rhs body)
     (define new-rhs (rco-exp rhs))
     (define-values (new-body body-ss) (rco-atom body))
     (values new-body (append `((,x . ,new-rhs)) body-ss))]
    [(Prim op es)
     (define-values (new-es sss) (for/lists (l1 l2) ([e es]) (rco-atom e)))
     (define ss (append* sss))
     (define tmp (gensym 'tmp))
     (values (Var tmp) (append ss `((,tmp . ,(Prim op new-es)))))]))

(define (rco-exp e)
  (match e
    [(Var x) (Var x)]
    [(Int n) (Int n)]
    [(Let x e body) (Let x (rco-exp e) (rco-exp body))]
    [(Prim op es)
     (define-values (new-es sss) (for/lists (l1 l2) ([e es]) (rco-atom e)))
     (define ss (append* sss))
     (make-lets ss (Prim op new-es))]))


(define (remove-complex-opera* p)
  (match p
    [(Program info e) (Program info (rco-exp e))]))

;; explicate-control : Lvar^mon -> Cvar
(define (explicate-tail e)
  (match e
    [(Var x) (Return (Var x))]
    [(Int n) (Return (Int n))]
    [(Let x rhs body)
     (Seq
      (Assign (Var x) rhs) ; assume here rhs is already atom, orelse we need extra explicate-assign
      (explicate-tail body))]
    [(Prim op es) (Return (Prim op es))]
    [else (error "explicate_tail unhandled case" e)]))

; (define (explicate-assign e x cont)
;   (match e
;     [(Var x) (Seq (Assign (Var x) (Var )))]
;     [(Int n) (Seq (Assign (Var x) (Int n)) cont)]
;     [(Let y rhs body) ___]
;     [(Prim op es) ___]
;     [else (error "explicate_assign unhandled case" e)]))
(define (explicate-control p)
  (match p
    [(Program info body) (CProgram info `((start . ,(explicate-tail body))))]))

(define (instr-translation ast)
  (match ast 
    [(Seq s t) s]))

;; select-instructions : Cvar -> x86var
(define (select-instructions ast)
  (match ast
    [(CProgram info blocks)
     (define start (dict-ref blocks 'start))
     (instr-translation start)]))

;; assign-homes : x86var -> x86var
(define (assign-homes p)
  (error "TODO: code goes here (assign-homes)"))

;; patch-instructions : x86var -> x86int
(define (patch-instructions p)
  (error "TODO: code goes here (patch-instructions)"))

;; prelude-and-conclusion : x86int -> x86int
(define (prelude-and-conclusion p)
  (error "TODO: code goes here (prelude-and-conclusion)"))

;; Define the compiler passes to be used by interp-tests and the grader
;; Note that your compiler file (the file that defines the passes)
;; must be named "compiler.rkt"
(define compiler-passes
  `(
    ;; Uncomment the following passes as you finish them.
    ("uniquify" ,uniquify ,interp-Lvar ,type-check-Lvar)
    ("remove complex opera*" ,remove-complex-opera* ,interp-Lvar ,type-check-Lvar)
    ("explicate control" ,explicate-control ,interp-Cvar ,type-check-Cvar)
    ("instruction selection" ,select-instructions ,interp-x86-0)
    ;; ("assign homes" ,assign-homes ,interp-x86-0)
    ;; ("patch instructions" ,patch-instructions ,interp-x86-0)
    ;; ("prelude-and-conclusion" ,prelude-and-conclusion ,interp-x86-0)
    ))
