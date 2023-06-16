(namespace (read-msg "ns"))
(module energetic-gas-station GOVERNANCE
  (implements gas-payer-v1)
  (use coin)

  ;;
  ;; Constants
  ;;


  (defconst GAS_STATION "energetic-gas-station")
  (defconst MAX_GAS_PRICE:decimal 0.000001)

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE ()
    (enforce-keyset (read-keyset "free.energetic-gas-admin"))
  )

  (defun chain-gas-price ()
    (at 'gas-price (chain-data))
  )

  (defcap GAS_PAYER:bool (user:string limit:integer price:decimal)
    (enforce (= "exec" (at "tx-type" (read-msg))) "Inside an exec")
    (enforce (= 1 (length (at "exec-code" (read-msg)))) "Tx of only one pact function")
    (enforce-ns)
    (compose-capability (ALLOW_GAS))
  )

  (defcap ALLOW_GAS () true)

  ;;
  ;; Functions
  ;;

  (defun enforce-ns ()
    (enforce (= "(free.energetic-" (take 16 (at 0 (at "exec-code" (read-msg))))) "only free.energetic- namespace")
  )

  (defun create-gas-payer-guard:guard ()
    (create-user-guard (gas-payer-guard))
  )

  (defun gas-payer-guard ()
    (require-capability (GAS))
    (require-capability (ALLOW_GAS))
  )

  (defun init ()
    (coin.create-account GAS_STATION (create-gas-payer-guard))
  )
)

(if (read-msg 'upgrade)
  ["upgrade"]
  [
    (init)
  ]
)