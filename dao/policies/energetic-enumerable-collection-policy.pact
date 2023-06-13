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
  
    (deftable item-table:{item-schema})

    ;;
    ;; Capabilities
    ;;
  
    (defcap GOVERNANCE ()
      (enforce-keyset ADMIN_KEYSET)
    )

    (defcap TRANSFER (token-id:string sender:string receiver:string amount:decimal)
      @managed
      (enforce-ledger)
      true
    )

    ;;
    ;; Utils
    ;;

    (defun key:string (token-id:string account:string)
      (format "{}:{}" [token-id account])
    )
  
    ;;
    ;; Functions
    ;;
  
    (defun enforce-ledger:bool ()
      (enforce-guard (marmalade.ledger.ledger-guard))
    )

    (defun transfer (token-id:string sender:string receiver:string amount:decimal)
      (with-capability (TRANSFER token-id sender receiver amount)
        (with-read item-table (key token-id sender)
          {
            'collection-id := collection-id
          }
          (write item-table (key token-id receiver)
            {
              'token-id: token-id,
              'collection-id: collection-id,
              'owner: sender
            }
          )
        )
      )
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
        (write item-table (key token-id account)
          {
            'collection-id: collection-id,
            'token-id: token-id,
            'owner: account
          }
        )
        true
      )
    )
  
    (defun enforce-burn:bool (token:object{token-info} account:string amount:decimal)
      (enforce-ledger)
    )
  
    (defun enforce-offer:bool (token:object{token-info} seller:string amount:decimal sale-id:string)
      (enforce-ledger)
    )
  
    (defun enforce-buy:bool (token:object{token-info} seller:string buyer:string buyer-guard:guard amount:decimal sale-id:string)
      (transfer (at 'id token) seller buyer amount)
    )
  
    (defun enforce-transfer:bool (token:object{token-info} sender:string guard:guard receiver:string amount:decimal)
      (transfer (at 'id token) sender receiver amount)
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

    (defun get-token-info (item:object owner:string)
      (if (= owner "")
        {
          'info: (marmalade.ledger.get-token-info (at 'token-id item))
        }
        {
          'info: (marmalade.ledger.get-token-info (at 'token-id item)),
          'balance: (marmalade.ledger.get-balance (at 'token-id item) owner)
        }
      )
    )
  
    (defun get-collection-tokens-for-account (collection-id:string owner:string)
      (let
        (
          (map-items (lambda (item) (get-token-info item owner)))
        )
        (filter (where 'balance (!= 0.0)) 
          (map
            (map-items)
            (select item-table
              [
                'token-id
              ]
              (and?
                (where 'collection-id (= collection-id))
                (where 'owner (= owner))
              )
            )
          )
        )
      )
    )

    (defun get-collection-tokens (collection-id:string)
      (let
        (
          (map-items (lambda (item) (get-token-info item "")))
        )
        (map
          (map-items)
          (select item-table
            [
              'token-id
            ]
            (where 'collection-id (= collection-id))
          )
        )
      )
    )

    (defun get-tokens-for-account (owner:string)
      (let
        (
          (map-items (lambda (item) (get-token-info item owner)))
        )
        (filter (where 'balance (!= 0.0)) 
          (map
            (map-items)
            (select item-table
              [
                'token-id
              ]
              (where 'owner (= owner))
            )
          )
        )
      )
    )
  )
  
  (create-table item-table)