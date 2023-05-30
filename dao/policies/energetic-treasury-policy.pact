(namespace (read-msg 'ns))
(module energetic-treasury-policy GOVERNANCE
  (implements kip.token-policy-v2)

  (use marmalade.policy-manager)
  (use marmalade.fungible-quote-policy-v1)
  (use marmalade.fungible-quote-policy-interface-v1 [quote-spec quote-schema])
  (use marmalade.collection-policy-v1 [get-token])
  
  (use kip.token-policy-v2 [token-info QUOTE_POLICY])

  ;;
  ;; Schemas
  ;;

  (defschema treasury-schema
    payout-fungible:module{fungible-v2}
    treasury-operator-guard:guard
    funds:[object{fund-schema}]
  )

  (defschema fund-schema
    treasury-account:string
    rate:decimal
  )

  (deftable treasury-table:{treasury-schema})

  ;;
  ;; Constants
  ;;

  (defconst TREASURY_SPEC "treasury_spec")

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE ()
    (enforce-keyset "free.energetic-admin")
  )

  (defun get-treasury:object{treasury-schema} (collection-id:string)
    (read treasury-table collection-id)
  )

  ;;
  ;; Events
  ;;

  (defcap TREASURY_ROYALTY:bool (sale-id:string collection-id:string payout-amount:decimal fund-account:string)
    @event
    true
  )

  ;;
  ;; Functions
  ;;

  (defun enforce-ledger:bool ()
    (enforce-guard (marmalade.ledger.ledger-guard))
  )

  (defun get-token-collection:string (token-id:string)
    (bind (get-token token-id))
  )

  ;;
  ;; Policy
  ;;

  (defun enforce-init:bool (token:object{token-info})
    (enforce (is-used (at 'policies token) QUOTE_POLICY) "quote policy must be turned on")
    (enforce-ledger)
    true
  )

  (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
    (enforce-ledger)
  )

  (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
    (enforce-ledger)
    (enforce false "Burn prohibited")
  )

  (defun enforce-offer:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )

  (defun enforce-buy:bool (token:object{token-info} seller:string buyer:string buyer-guard:guard amount:decimal sale-id:string)
    (enforce-ledger)
    (enforce-sale-pact sale-id)
    true
  )

  (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
    (enforce-ledger)
    (enforce false "Transfer prohibited")
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    (enforce-ledger)
    (enforce false "Transfer prohibited")
  )

  (defun enforce-withdraw:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )
)

(if (read-msg 'upgrade)
  ["upgrade complete"]
  [ 
    (create-table treasury-table)
  ]
)