(namespace (read-msg 'ns ))
(module kinetic-policy GOVERNANCE

  (implements kip.token-policy-v1)
  (use kip.token-policy-v1 [token-info])
  (use kip.token-manifest [manifest])
  (use free.kinetic-collections [create-token get-collection get-token collection-info])

  ;;
  ;; Schemas
  ;;

  (defschema watt-status-schema
    for-sale:bool
    staked:bool
  )

  (deftable watt-status-table:{watt-status-schema})

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.kinetic-admin")
  )

  (defcap ENFORCE_LEDGER:bool ()
    (enforce-guard (marmalade.ledger.ledger-guard))
  )

  ;;
  ;; Events
  ;;
  
  (defcap COLLECTION_ITEM_MINTED:bool (collection-id:string current-supply:decimal token-id:string minter:string)
    @event
    true
  )
  
  (defcap COLLECTION_ITEM_CREATED:bool (collection-id:string token-id:string manifest:object{manifest})
    @event
    true
  )

  (defcap COLLECTION_ITEM_TRANSFERED:bool (collection-id:string token-id:string sender:string receiver:string amount:decimal)
    @event
    true
  )

  ;;
  ;; Functions
  ;;

  ;;
  ;; Policy
  ;;

  (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
    (with-capability (ENFORCE_LEDGER)
      (enforce (= amount 1.0) "Invalid amount")
      (bind (get-token (at 'id token))
        {
          'collection-id := collection-id
        }
        (bind (get-collection collection-id)
          {
            'supply := max-supply,
            'fungible := coin,
            'creator-account := creator-account,
            'price := price
          }
          (let 
            (
              (current-supply:decimal (+ amount (at 'supply token)))
            )
            (enforce (<= current-supply max-supply) "max-supply exceeded")
            (insert watt-status-table (at 'id token) 
              { 
                'for-sale: false,
                'staked: false 
              }
            )
            (coin.transfer account creator-account price)
            (emit-event (COLLECTION_ITEM_MINTED collection-id current-supply (at 'id token) account))
          )
        )
      )
    )
  )

  (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
    @model [
        (property (!= account ""))
        (property (> amount 0.0))
    ]
    (with-capability (ENFORCE_LEDGER)
      false
    )
  )

  (defun enforce-init:bool (token:object{token-info})
    (with-capability (ENFORCE_LEDGER)
      (let 
        (
          (token-id:string  (at 'id token))
          (precision:integer (at 'precision token))
          (collection-info:object{collection-info} (read-msg 'collection-info ))
        )
        (enforce (= precision 0) "Invalid precision")
        (create-token token-id (at 'id collection-info) 0.0)
        (emit-event (COLLECTION_ITEM_CREATED (at 'id collection-info) token-id (at 'manifest token)))
      )
    )
  )

  (defun enforce-offer:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
    @doc "Offer policy of sale SALE-ID by SELLER of AMOUNT of TOKEN."
    (with-capability (ENFORCE_LEDGER)
      false
    )
  )

  (defun enforce-buy:bool (token:object{token-info} seller:string buyer:string buyer-guard:guard amount:decimal sale-id:string)
    (with-capability (ENFORCE_LEDGER)
      false
    )
  )

  (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
    (with-capability (ENFORCE_LEDGER)
      (with-read watt-status-table (at 'id token)
        {
          'for-sale := for-sale,
          'staked := staked
        }
        (enforce (= for-sale false) "The token is currently for sale")
        (enforce (= staked false) "The token is currently staked")
        (bind (get-token (at 'id token))
          {
            'collection-id := collection-id
          }
          (emit-event (COLLECTION_ITEM_TRANSFERED collection-id (at 'id token) sender receiver amount))
        )
      )
    )
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    (with-capability (ENFORCE_LEDGER)
      false
    )
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  [
    (create-table watt-status-table)
  ]
)