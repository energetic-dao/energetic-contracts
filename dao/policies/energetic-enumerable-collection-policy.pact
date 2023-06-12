(namespace "free")
(module energetic-enumerable-collection-policy GOVERNANCE

    (implements kip.token-policy-v2)
    (use kip.token-policy-v2 [token-info])
  
    ;;
    ;; Constants
    ;;

    (defconst ADMIN_KEYSET:string "free.energetic-admin")
  
    ;;
    ;; Schema
    ;;
  
    (defschema item-schema
      collection-id:string
      token-id:string
      owner:string
    )

    (defschema owner-item
      token-ids:[string]
    )
  
    (deftable item-table:{item-schema})
  
    ;;
    ;; Capabilities
    ;;
  
    (defcap GOVERNANCE ()
      (enforce-keyset ADMIN_KEYSET)
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
    )
  
    (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
      (enforce-ledger)
      (let
        (
          (token-id:string (at 'id token))
          (collection-id:string (read-msg "collection-id"))
        )
        (insert item-table token-id
          {
            'collection-id: collection-id,
            'token-id: token-id,
            'owner: account
          }  
        )
        (with-default-read owner-item account
          {
            'token-ids: []
          }
          {
            'token-ids := token-ids
          }
          (if (= [])
            [
              (insert owner-item account
                {
                  'token-ids: [token-id]
                }
              )
            ]
            [
              (update owner-item account
                {
                  'token-ids: (+ token-ids [token-id])
                }
              )
            ]
          )
          true
        )
      )
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
      (let
        (
          (token-id:string (at 'id token))
        )
        (update item-table token-id
          {
            'owner: receiver
          }
        )
        (with-default-read owner-item receiver
          {
            'token-ids: []
          }
          {
            'token-ids := token-ids
          }
          (if (= [])
            [
              (insert owner-item receiver
                {
                  'token-ids: [token-id]
                }
              )
            ]
            [
              (update owner-item receiver
                {
                  'token-ids: (+ token-ids [token-id])
                }
              )
            ]
          )
        )
        (with-read owner-item sender
          {
            'token-ids := token-ids
          }
          (update owner-item sender
            {
              'token-ids: (filter (!= token-id) token-ids)
            }
          )
        )
        true
      )
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
  

  )
  
  (create-table item-table)