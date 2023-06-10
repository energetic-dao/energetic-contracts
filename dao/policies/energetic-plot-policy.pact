(namespace "free")
(module energetic-plot-policy GOVERNANCE

  (implements kip.token-policy-v2)
  (use kip.token-policy-v2 [token-info])

  (defschema plot
    id:string
  )

  (deftable plots:{plot})

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.energetic-admin")
  )

  ;;
  ;; Functions
  ;;

  (defun enforce-ledger:bool ()
    (enforce-guard (marmalade.ledger.ledger-guard))
  )

  ;;
  ;; Policy
  ;;

  (defun enforce-init:bool (token:object{token-info})
    (enforce-ledger)
    (let*
      (
        (token-id:string (at 'id token))
        (token-index:string (at 'index (read-msg "token")))
      )
      (insert plots token-index
        {
          'id: token-id
        }  
      )
      true
    )
  )

  (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-offer:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )

  (defun enforce-buy:bool (token:object{token-info} seller:string buyer:string buyer-guard:guard amount:decimal sale-id:string)
    (enforce-ledger)
  )

  (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-withdraw:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )

  ;;
  ;; Getters
  ;;

  (defun get-plot-token-id:string (index:integer)
    (with-read plots (hash index)
      {
        'id:= id
      }
      id
    )
  )
)

(create-table plots)