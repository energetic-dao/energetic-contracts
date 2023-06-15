(namespace "free")
(module energetic-enumerable-collection-policy GOVERNANCE

    (implements kip.token-policy-v2)
    (use kip.token-policy-v2 [token-info])
    (use marmalade.collection-policy-v1 [get-token])
  
    ;;
    ;; Constants
    ;;

    (defconst ADMIN_KEYSET:string "free.energetic-admin")
  
    ;;
    ;; Schema
    ;;

    (defschema token-schema
      collection-id:string
      account:string
      token-ids:[string]
    )
  
    (defschema item-schema
      collection-id:string
      token-id:string
      owner:string
    )
  
    ; V1
    (deftable item-table:{item-schema})

    ; V2
    (deftable tokens:{token-schema})

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

    (defun transfer:bool (token-id:string sender:string receiver:string amount:decimal)
      (enforce false "Transfer prohibited")
      (with-capability (TRANSFER token-id sender receiver amount)
        (let*
          (
            (collection-id:string (get-collection-id token-id))
            (old-sender-tokens:[string] (get-account-token-ids collection-id sender))
            (old-receiver-tokens:[string] (get-account-token-ids collection-id receiver))
            (reduced-sender-tokens:[string] (filter (!= token-id) old-sender-tokens))
          )
          (write tokens (key collection-id sender)
            {
              'collection-id: collection-id,
              'account: sender,
              'token-ids: (+ reduced-sender-tokens (make-list 
                (-
                  (- (length old-sender-tokens) (length reduced-sender-tokens))
                  (round amount)
                ) token-id))
            }
          )

          (write tokens (key collection-id receiver)
            {
              'collection-id: collection-id,
              'account: receiver,
              'token-ids: (+ old-receiver-tokens (make-list (round amount) token-id))
            }
          )
        true
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
      (let*
        (
          (token-id:string (at 'id token))
          (collection-id:string (read-msg "collection-id"))
          (old-tokens:[string] (get-account-token-ids collection-id account))
        )
        (write tokens (key collection-id account)
          {
            'collection-id: collection-id,
            'account: account,
            'token-ids: (+ old-tokens [token-id])
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

    (defun get-collection-id:string (token-id:string)
      (bind (get-token token-id)
        {
          'collection-id := collection-id
        }
        collection-id
      )
    )

    (defun get-account-token-ids:[string] (collection-id:string account:string)
      (with-default-read tokens (key collection-id account)
        {
          'token-ids: []
        }
        {
          'token-ids := token-ids
        }
        token-ids
      )
    )

    (defun get-token-info (token-id:string account:string)
      (if (= account "")
        [
          (marmalade.ledger.get-token-info token-id)
        ]
        [
          (+
            (marmalade.ledger.get-token-info token-id)
            {
              'balance: (marmalade.ledger.get-balance token-id account)
            }
          )
        ]
      )
    )
  
    (defun get-collection-tokens-for-account (collection-id:string account:string)
      (let
        (
          (token-ids:[string] (distinct (get-account-token-ids collection-id account)))
          (map-items (lambda (item-id) (get-token-info item-id account)))
        )
        (map
          (map-items)
          token-ids
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
          (select tokens
            [
              'token-id
            ]
            (where 'collection-id (= collection-id))
          )
        )
      )
    )

    ; v1

    (defun get-item-keys:[string] ()
      (keys item-table)
    )

    (defun get-items:object{item-schema} ()
      (map
        (lambda (key) (read item-table key))
        (get-item-keys)
      )
    )

    ; Migrate
    (defun migrate-v1-object:object{token-schema} (item:object{item-schema})
      (let
        (
          (token-id:string (at 'id item))
          (collection-id:string (at 'collection-id item))
          (account:string (at 'account item))
          (token-ids:[string] (at 'token-ids item))
        )
        (write tokens (key collection-id account)
          {
            'collection-id: collection-id,
            'account: account,
            'token-ids: token-ids
          }
        )
        {
          'collection-id: collection-id,
          'account: account,
          'token-ids: token-ids
        }
      )
    )
  )
  
  (create-table item-table)
  (create-table tokens)