(namespace (read-msg 'ns))
(module energetic-manifest-policy GOVERNANCE

  (implements kip.token-policy-v2)

  (use kip.token-manifest)
  (use kip.token-policy-v2 [token-info])

  ;;
  ;; Schema
  ;;

  (defschema item-manifest
    manifest:object{manifest}
    type:string
    guard:guard
  )

  (deftable manifest-table:{item-manifest})

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE ()
    (enforce-guard (keyset-ref-guard "free.energetic-admin"))
  )

  (defcap UPGRADE (token-id:string)
    @managed
    (with-read manifest-table token-id 
      {
        'guard := manifest-guard
      }
      (enforce-guard manifest-guard)
    )
  )

  ;;
  ;; Functions
  ;;

  (defun enforce-ledger:bool ()
     (enforce-guard (marmalade.ledger.ledger-guard))
  )

  (defun get-manifest:object{manifest} (token-id:string)
    (with-read manifest-table token-id 
      {
        'manifest := manifest
      }
      manifest
    )
  )

  (defun upgrade-manifest (token-id:string manifest:object{manifest})
    (with-capability (UPGRADE token-id)
      (enforce-verify-manifest manifest)
      (update manifest-table token-id
        {
          'manifest: manifest
        }
      )
    )
  )

  (defun upgrade-type (token-id:string type:string)
    (with-capability (UPGRADE token-id)
      (update manifest-table token-id
        {
          'type: type
        }
      )
    )
  )

  ;;
  ;; Policy
  ;;

  (defun enforce-init:bool (token:object{token-info})
    (enforce-ledger)
    (let*
      (
        (token-id:string (at 'id token))
        (item-manifest:object{item-manifest} (read-msg "item-manifest"))
        (manifest:object{manifest} (at 'manifest item-manifest))
      )
      (enforce-verify-manifest manifest)
      (insert manifest-table token-id item-manifest)
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

  (defun get-token-manifest (token-id:string)
    (with-read manifest-table token-id 
      {
        'manifest := manifest,
        'type := type
      }
      {
        'manifest: manifest,
        'type: type
      }
    )
  )
)

(if (read-msg 'upgrade)
  ["upgrade complete"]
  [
    (create-table manifest-table)
  ]
)
