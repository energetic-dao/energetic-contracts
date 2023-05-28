(namespace (read-msg 'ns))
(module energetic-plot-staking-center GOVERNANCE

  (use free.energetic-manifest-policy)

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
    amount:decimal
    locked-since:time
    account:string
    account-guard:guard
  )

  (defschema plot-slot-constant-schema
    type:string
    max:integer
  )

  (deftable plot-table:{plot-schema})
  (deftable plot-staking-table:{plot-staking-schema})
  (deftable plot-slot-constant-table:{plot-slot-constant-schema})

  ;;
  ;; Constants
  ;;

  (defconst SLOT_TYPE_ROOF_SOLAR_PANEL:string "roof-solar-panels")
  (defconst SLOT_TYPE_STANDING_SOLAR_PANEL:string "standing-solar-panel")
  (defconst SLOT_TYPE_WALL_BATTERY:string "wall-battery")
  (defconst SLOT_TYPE_WIND_TURBINE:string "wind-turbine")

  (defconst SLOT_TYPES:[string] [SLOT_TYPE_ROOF_SOLAR_PANEL SLOT_TYPE_WALL_BATTERY SLOT_TYPE_STANDING_SOLAR_PANEL SLOT_TYPE_WIND_TURBINE])

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset (read-keyset "test.energetic-admin"))
  )

  (defcap OPERATOR:bool ()
    (enforce-guard (read-keyset "dao"))
  )

  (defcap STAKE:bool (plot-id:string account:string account-guard:guard)
    (bind (get-token-manifest plot-id)
      {
        'type := type
      }
      (enforce-guard account-guard)
      (enforce (= type "plot") "Requires plot type")
    )
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
    true
  )

  ;;
  ;; Escrow Utilities
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
      (with-capability (STAKE plot-id account account-guard)
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
    (enforce (= amount 1.0) "Amount can only be 1")
    (let
      (
        (escrow-plot-guard (create-plot-guard plot-id))
        (escrow-account (create-escrow-account plot-id))
      )
      true
    )
  )

  ;;
  ;; Setters
  ;;

  (defun set-slot-type-max (type:string max:integer)
    (with-capability (OPERATOR)
      (let
        (
          (type-hash (hash type))
          (slot-type-count (length (filter (= type) SLOT_TYPES)))
        )
        (enforce (= slot-type-count 1) "Invalid slot type")
        (write plot-slot-constant-table type-hash
          {
            'type: type,
            'max: max
          }
        )
        {
          'type: type,
          'max: max
        }
      )
    )
  )

  ;;
  ;; Getters
  ;;

  (defun get-slot-type-max:integer (type:string)
    (with-read plot-slot-constant-table (hash type)
      {
        'max := max
      }
      max
    )
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  [
    (create-table plot-table)
    (create-table plot-staking-table)
    (create-table plot-slot-constant-table)
  ]
)