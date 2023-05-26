(namespace (read-msg 'ns))
(module energetic-plot-staking-center GOVERNANCE

  ;;
  ;; Schema
  ;;

  (defschema plot-schema
    escrow-account:string
    original-owner:string
    guard:guard
    ;locked-since:time
  )

  (defschema plot-staking-schema
    token-id:string
    plot-id:string
    escrow-account:string
    original-owner:string
    amount:decimal
    locked-since:time
    account:string
    account-guard:guard
  )

  (deftable plot-table:{plot-schema})
  (deftable plot-staking-table:{plot-staking-schema})

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.energetic-admin")
  )

  (defcap STAKE:bool (account:string escrow-account:string token-id:string amount:decimal)
    true
  )

  (defcap UNSTAKE (plot-id:string account:string)
    (with-read plot-table plot-id
      {
        "guard" := guard 
      }
      (enforce-guard guard)
    )
  )

  (defcap PRIVATE:bool ()
    true
  )

  (defcap PLOT:bool (plot-id:string)
    ; @todo validate if type is plot
    true
  )

  ;;
  ;; Escrow Utilities
  ;; @todo install the capability
  ;;

  (defun require-PLOT:bool (plot-id:string)
    (require-capability (PLOT plot-id))
  )

  (defun create-plot-guard:guard (plot-id:string)
    (create-module-guard plot-id)
  )

  (defun create-escrow-account (plot-id:string)
    (create-principal (create-plot-guard plot-id))
  )

  ;;
  ;; Functions
  ;;

  (defun lock-plot (plot-id:string amount:decimal account:string account-guard:guard)
    (enforce (= amount 1.0) "Amount can only be 1")

    (let
      (
        (escrow-plot-guard (create-plot-guard plot-id))
        (escrow-account (create-escrow-account plot-id))
      )
      (marmalade.ledger.create-account plot-id escrow-account escrow-plot-guard)
      (marmalade.ledger.transfer plot-id account escrow-account amount)
      ; (coin::create-account escrow-account escrow-plot-guard) ; @todo change to energetic-coin
      (insert plot-table plot-id
        {
          'escrow-account: escrow-account,
          'original-owner: account,
          'guard: account-guard
          ;'locked-since: (at 'block-time (chain-data))
        }
      )
      {
        'escrow-account: escrow-account,
        'original-owner: account,
        'guard: account-guard
        ;'locked-since:= (at 'block-time (chain-data))
      }
    )
  )

  (defun unlock-plot (plot-id:string amount:decimal account:string)
    (enforce (= amount 1.0) "Amount can only be 1")
    (with-capability (UNSTAKE plot-id account)
      ; @todo read from plot-staking-table to unstake upgraded nfts

      (with-read plot-table plot-id
        {
          'escrow-account := escrow-account,
          'guard := guard
        }

        (install-capability (marmalade.ledger.TRANSFER plot-id escrow-account account amount))
        (marmalade.ledger.transfer plot-id escrow-account account amount)
        ; @todo add claim for energetic-coin rewards  
      )
    )
  )

  (defun upgrade-plot:bool (plot-id:string account:string account-guard:guard token-id:string amount:decimal)
      true
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  [
    (create-table plot-table)
    (create-table plot-staking-table)
  ]
)