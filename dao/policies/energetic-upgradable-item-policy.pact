(namespace (read-msg 'ns ))
(module energetic-upgradable-item-policy GOVERNANCE

  (implements kip.token-policy-v2)
  (use kip.token-policy-v2 [token-info])
  (use kip.token-manifest [manifest])

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.energetic-admin")
  )

  ;;
  ;; Events
  ;;
  
  (defcap ITEM_MINTED:bool (token-id:string current-supply:decimal minter:string)
    @event
    true
  )
  
  (defcap ITEM_CREATED:bool (token-id:string manifest:object{manifest})
    @event
    true
  )

  ;;
  ;; Functions
  ;;

  (defun enforce-ledger:bool ()
    (enforce-guard (marmalade-v2.ledger.ledger-guard))
  )

  ;;
  ;; Policy
  ;;

  (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
    @doc "Burning policy for TOKEN to ACCOUNT for AMOUNT."
    @model [
        (property (!= account ""))
        (property (> amount 0.0))
    ]
    false
  )

  (defun enforce-init:bool (token:object{token-info})
    (enforce-ledger)
  )

  (defun enforce-offer:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
    false
  )

  (defun enforce-buy:bool (token:object{token-info} seller:string buyer:string buyer-guard:guard amount:decimal sale-id:string)
    (enforce-ledger)
    false
  )

  (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
    (enforce-ledger)
    true
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    (enforce-ledger)
    false
  )

  (defun enforce-withdraw:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  []
)
