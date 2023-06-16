(module energetic-plot-item-policy GOVERNANCE

  (implements kip.token-policy-v2)
  (use kip.token-policy-v2 [token-info])

  ;;
  ;; Constants
  ;;

  (defconst METADATA_UPGRADE_GUARD:string "item-metadata-guard")

  ;;
  ;; Schema
  ;;

  (defschema metadata
    power-rate:decimal
    type:string
  )

  (defschema item-metadata-schema
    power-rate:decimal
    type:string
    guard:guard
  )

  (deftable item-metadata-table:{item-metadata-schema})

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE ()
    (enforce-keyset "free.energetic-admin")
  )

  (defcap UPGRADE (token-id:string)
    @managed
    (with-read item-metadata-table token-id 
      {
        'guard := item-guard
      }
      (enforce-guard item-guard)
    )
  )

  ;;
  ;; Functions
  ;;

  (defun enforce-ledger:bool ()
    (enforce-guard (marmalade.ledger.ledger-guard))
    true
  )

  (defun upgrade-power-rate (token-id:string power-rate:decimal)
    (with-capability (UPGRADE token-id)
      (update item-metadata-table token-id
        {
          'power-rate: power-rate
        }
      )
    )
  )

  ;;
  ;; Policy
  ;;

  (defun enforce-init:bool (token:object{token-info})
    (enforce-ledger)
    (let
      (
        (token-id:string (at 'id token))
        (item-metadata:object{metadata} (read-msg "item-metadata"))
        (upgrade-guard:guard (read-keyset METADATA_UPGRADE_GUARD))
      )
      (insert item-metadata-table token-id
        {
          'power-rate: (at 'power-rate item-metadata),
          'type: (at 'type item-metadata),
          'guard: upgrade-guard
        }
      )
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

  (defun enforce-withdraw:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    (enforce-ledger)
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    (enforce-ledger)
    (enforce false "Transfer prohibited")
  )

  ;;
  ;; Getters
  ;;

  (defun get-token-metadata:object{item-metadata-schema} (token-id:string)
    (with-read item-metadata-table token-id 
      {
        'guard := guard,
        'type := type,
        'power-rate := power-rate
      }
      {
        'guard: guard,
        'type: type,
        'data: power-rate
      }
    )
  )
)

(create-table item-metadata-table)