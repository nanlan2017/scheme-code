(module interp (lib "eopl.ss" "eopl")
  (provide (all-defined-out))
  
  (require "0-lang.scm")
  (require "1-store.scm")
  (require "1-data-structures.scm")
  (require "utils.scm")
  ;============================================================ Proc (part 2)
  ; apply-procedure : Proc * [ExpVal] -> ExpVal
  (define (apply-procedure proc arg)
    (cases Procedure proc
      ($procedure (var body env)
                  (value-of body ($extend-env var (newref arg) env)))))

  ;============================================================= result-of
  ; A program is a statement.
  ; A statement does not return a value, but acts by modifying the store and by printing 【所以也不改Env ?】
  ; █████ env 、返回void 的问题 ??
  (define (execute-program prog)
    (initialize-store!)
    (cases program prog
      (a-program (stat)
                 (execute stat (init-env)))))

  ; result-of :: Statement * Env -> ()
  (define (execute STAT env)
    (cases statement STAT
      (assign-stat (var exp)
                   (begin
                     (value-of (assign-exp var exp) env)
                     'void))
      
      (print-stat (exp)
                  (let [(val (value-of exp env))]
                    (begin
                      (eopl:printf "[console]>>>>>>>>>>>> ~s~n" val)
                      'void)))
      
      (seq-stat (stat-s)
                (for-each (lambda (stat) (execute stat env))
                          stat-s))
      
      (if-stat (exp then-stat else-stat)
               (let [(val (value-of exp env))]
                 (if (expval->bool val)
                     (execute then-stat env)
                     (execute else-stat env))))
      
      (while-stat (exp stat)
                  (let [(val (value-of exp env))]
                    (if (expval->bool val)
                        (begin 
                          (execute stat env)
                          (execute STAT env)) ; 再次回到自身
                        'void)))
      
      (block-stat (vars stat)
                  (let [(rv-s (map (lambda (var) (newref 'uninitialized)) vars))]
                    (execute stat (extend-env* vars rv-s env))))
      ))
  
  ;============================================================= value-of
  ; value-of :: expression x Env -> ExpVal
  (define (value-of exp env)
    (cases expression exp
      (const-exp (n)
                 ($num-val n))
      (var-exp (x)
               (deref (apply-env env x)))
      (diff-exp (e1 e2)
                ($num-val (- (expval->num (value-of e1 env))
                             (expval->num (value-of e2 env)))))
      (add-exp (e1 e2)
               ($num-val (+ (expval->num (value-of e1 env))
                            (expval->num (value-of e2 env)))))
      (mult-exp (e1 e2)
                ($num-val (* (expval->num (value-of e1 env))
                             (expval->num (value-of e2 env)))))
      (zero?-exp (e1)
                 (let* [(v1 (value-of e1 env))
                        (v2 (expval->num v1))]
                   ($bool-val (if (= 0 v2) #t #f))))
      (if-exp (e1 e2 e3)
              (let [(v1 (value-of e1 env))]
                (if (expval->bool v1)
                    (value-of e2 env)
                    (value-of e3 env))))
      (not-exp (e1)
               (let [(v1 (value-of e1 env))]
                 ($bool-val (not (expval->bool v1)))))
      (let-exp (var e1 body)
               (let [(v1 (value-of e1 env))]
                 (value-of body ($extend-env var (newref v1) env))))

      ; 1-parameter procedure
      (proc-exp (var body)
                ($proc-val ($procedure var body env)))
      (call-exp (rator rand)
                (let [(f (expval->proc (value-of rator env)))
                      (arg (value-of rand env))]
                  (apply-procedure f arg)))                               
      ; letrec
      (letrec-exp (pid-s bvar-s pbody-s letrec-body)
                  (value-of letrec-body ($extend-env-rec* pid-s bvar-s pbody-s env)))
      ; begin
      (begin-exp (exps)
                 (let [(vals (map (lambda (e) (value-of e env)) exps))]
                   (list-last vals)))
      ; assignment
      (assign-exp (var exp1)
                  (begin
                    (setref! (apply-env env var) (value-of exp1 env))
                    'void))                 
      ))

  ;=============================================================  
  ; interp :: String -> ExpVal
  (define (interp src)
    (execute-program (scan&parse src)))
  (define run interp)

  )
