(namespace (read-msg 'ns ))
(module kinetic-policy GOVERNANCE

  (implements kip.token-policy-v1)
  (use kip.token-policy-v1 [token-info])
  (use free.kinetic-collections [create-token get-collection get-token collection-info])

  ;;
  ;; Schemas
  ;;

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
            (coin.transfer account creator-account price)
            (emit-event (COLLECTION_ITEM_MINTED collection-id current-supply (at 'id token) account))
          )
        )
      )
    )
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
    @doc "Enforce policy on TOKEN initiation."
    (with-capability (ENFORCE_LEDGER)
      (let 
        (
          (token-id:string  (at 'id token))
          (precision:integer (at 'precision token))
          (collection-info:object{collection-info} (read-msg 'collection-info ))
        )
        (enforce (= precision 0) "Invalid precision")
        (create-token token-id (at 'id collection-info) 0.0)
        true
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
    @doc "Buy policy on SALE-ID by SELLER to BUYER AMOUNT of TOKEN."
    false
  )

  (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
    @doc " Enforce rules on transfer of TOKEN AMOUNT from SENDER to RECEIVER. \
            \ Also governs rotate of SENDER (with same RECEIVER and 0.0 AMOUNT). "
    true
  )

  (defun enforce-crosschain:bool (token:object{token-info} sender:string guard:guard receiver:string target-chain:string amount:decimal)
    @doc " Enforce rules on crosschain transfer of TOKEN AMOUNT \
            \ from SENDER to RECEIVER on TARGET-CHAIN."
    false
  )
)