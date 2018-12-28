(module store (lib "eopl.ss" "eopl")
  
  (require "drscheme-init.scm")
  
  (provide initialize-store!
           reference?
           newref
           deref
           setref!
           instrument-newref
           get-store-as-list)
  ; ===========================================================
  ; setting option 
  (define instrument-newref (make-parameter #f))
  
  (define %Store 'uninitialized)

  ;; empty-store : () -> Sto
  (define empty-store
    (lambda () '()))
  
  ;; initialize-store! : () -> Sto
  (define initialize-store!
    (lambda ()
      (set! %Store (empty-store))))

  ;; get-store : () -> Sto
  (define get-store
    (lambda () %Store))

  ;; reference? : SchemeVal -> Bool
  (define reference? integer?)

  ;; newref : ExpVal -> Ref
  (define newref
    (lambda (val)
      (let ((next-ref (length %Store)))
        (set! %Store (append %Store (list val)))
        (when (instrument-newref)
          (eopl:printf  "newref: allocating location ~s with initial contents ~s~%" next-ref val))                     
        next-ref)))                     

  ;; deref : Ref -> ExpVal
  (define deref 
    (lambda (ref)
      (list-ref %Store ref)))

  ;; setref! : Ref * ExpVal -> Unspecified
  (define setref!                       
    (lambda (ref val)
      (set! %Store
            (letrec
                ((setref-inner  ;; returns a list like store1, except that position ref1 contains val.                   
                  (lambda (store1 ref1)
                    (cond
                      ((null? store1) (report-invalid-reference ref %Store))
                      ((zero? ref1) (cons val (cdr store1)))
                      (else (cons (car store1)
                                  (setref-inner (cdr store1) (- ref1 1))))))))
              (setref-inner %Store ref)))))

  (define report-invalid-reference
    (lambda (ref the-store)
      (eopl:error 'setref
                  "illegal reference ~s in store ~s"
                  ref the-store)))

  ;; get-store-as-list : () -> Listof(List(Ref,Expval))
  ;; (get-store-as-list '(foo bar baz)) = ((0 foo)(1 bar) (2 baz)) where foo, bar, and baz are expvals.
  (define get-store-as-list
    (lambda ()
      (letrec
          ((inner-loop
            ;; convert sto to list as if its car was location n
            (lambda (sto n)
              (if (null? sto)
                  '()
                  (cons (list n (car sto))
                        (inner-loop (cdr sto) (+ n 1)))))))
        (inner-loop %Store 0))))



  )