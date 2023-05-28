(namespace (read-msg 'ns))
(module energetic-plot-staking-center GOVERNANCE

  (use free.energetic-manifest-policy)

  ;;
  ;; Schema
  ;;

  (defschema plot-schema
    escrow-account:string
    escrow-guard:guard
    original-owner:string
    account-guard:guard
    locked-since:time
  )

  (defschema plot-staking-schema
    item-id:string
    plot-id:string
    amount:decimal
    type:string
    locked-since:time
    account:string
    account-guard:guard
  )

  (defschema plot-slot-constant-schema
    type:string
    max:decimal
  )

  (deftable plot-table:{plot-schema})
  (deftable plot-staking-table:{plot-staking-schema})
  (deftable plot-slot-constant-table:{plot-slot-constant-schema})

  ;;
  ;; Constants
  ;;

  (defconst ADMIN_KEYSET (read-keyset "energetic-admin"))
  (defconst OPERATOR_KEYSET (read-keyset "energetic-operator"))

  (defconst SLOT_TYPE_ROOF_SOLAR_PANEL:string "roof-solar-panels")
  (defconst SLOT_TYPE_STANDING_SOLAR_PANEL:string "standing-solar-panel")
  (defconst SLOT_TYPE_WALL_BATTERY:string "wall-battery")
  (defconst SLOT_TYPE_WIND_TURBINE:string "wind-turbine")

  (defconst SLOT_TYPES:[string] [SLOT_TYPE_ROOF_SOLAR_PANEL SLOT_TYPE_WALL_BATTERY SLOT_TYPE_STANDING_SOLAR_PANEL SLOT_TYPE_WIND_TURBINE])

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset ADMIN_KEYSET)
  )

  (defcap OPERATOR:bool ()
    (enforce-keyset OPERATOR_KEYSET)
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

  (defcap UNSTAKE:bool (plot-id:string account:string)
    (with-read plot-table plot-id
      {
        "account-guard" := guard
      }
      (enforce-guard guard)
    )
  )

  (defcap UPGRADE_PLOT:bool (plot-id:string item-id:string account:string account-guard:guard)
    (with-read plot-table plot-id
      {
        "account-guard" := guard,
        "original-owner" := original-owner
      }
      (enforce (= guard account-guard) "Invalid account")
      (enforce (= original-owner account) "Plot is not staked by owner")
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
  ;; Utilities
  ;;

  (defun key:string (plot-id:string token-id:string)
    (hash (format "{}_{}" [plot-id token-id]))
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
        (marmalade.ledger.transfer-create plot-id account escrow-account escrow-plot-guard amount)
        ; (coin::create-account escrow-account escrow-plot-guard) ; @todo change to energetic-coin
        (write plot-table plot-id
          {
            'escrow-account: escrow-account,
            'escrow-guard: escrow-plot-guard,
            'original-owner: account,
            'account-guard: account-guard,
            'locked-since: (at 'block-time (chain-data))
          }
        )
        {
          'escrow-account: escrow-account,
          'original-owner: account,
          'account-guard: account-guard,
          'locked-since: (at 'block-time (chain-data))
        }
      )
    )
  )

  (defun unlock-plot:bool (plot-id:string amount:decimal account:string)
    (enforce (= amount 1.0) "Amount can only be 1")
    (with-capability (UNSTAKE plot-id account)
      (bind (get-plot plot-id)
        {
          'escrow-account := escrow-account
        }
        (let
          (
            (staked-plot-items:[object{plot-staking-schema}] (get-staked-items-on-plot plot-id))
            (transfer-staked-item
              (lambda (staked-item:object)
                (install-capability (marmalade.ledger.TRANSFER (at 'item-id staked-item) escrow-account account (at 'amount staked-item)))
                (marmalade.ledger.transfer (at 'item-id staked-item) escrow-account account (at 'amount staked-item))
              )
            )
          )
          (map transfer-staked-item staked-plot-items)
          (install-capability (marmalade.ledger.TRANSFER plot-id escrow-account account amount))
          (marmalade.ledger.transfer plot-id escrow-account account amount)
          ; @todo add claim for energetic-coin rewards

          (update plot-table plot-id
            {
              'original-owner: ""
            }
          )
          true
        )
      )
    )
  )

  (defun upgrade-plot:bool (plot-id:string item-id:string amount:decimal account:string account-guard:guard)
    (with-capability (UPGRADE_PLOT plot-id item-id account account-guard)
      (bind (get-token-manifest item-id)
        {
          'type := type
        }
        (bind (get-plot plot-id)
          {
            'escrow-account := escrow-account,
            'escrow-guard := escrow-plot-guard
          }
          (install-capability (marmalade.ledger.TRANSFER item-id account escrow-account amount))
          (marmalade.ledger.transfer-create item-id account escrow-account escrow-plot-guard amount)
          (let*
            (
              (item-has-policy-active:bool (item-has-policy-active item-id 'immutable-policies free.energetic-upgradable-item-policy))
              (item-max-amount:decimal (get-slot-type-max type))
              (current-staked-amount:decimal (marmalade.ledger.get-balance item-id escrow-account))
            )
            (enforce item-has-policy-active "Invalid item upgrade")
            (enforce (<= current-staked-amount item-max-amount) (format "Amount can max be {}" [item-max-amount]))

            (write plot-staking-table (key plot-id item-id)
              {
                'plot-id: plot-id,
                'item-id: item-id,
                'amount: current-staked-amount,
                'account: account,
                'type: type,
                'account-guard: account-guard,
                'locked-since: (at 'block-time (chain-data))
              }
            )
            true
          )
        )
      )
    )
  )

  ;;
  ;; Setters
  ;;

  (defun set-slot-type-max (type:string max:decimal)
    (with-capability (OPERATOR)
      (let
        (
          (type-hash (hash type))
          (has-valid-slot-type (contains type SLOT_TYPES))
        )
        (enforce has-valid-slot-type "Invalid slot type")
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

  (defun get-plot:object{plot-schema} (plot-id:string)
    (with-read plot-table plot-id
      {
        'escrow-account := escrow-account,
        'escrow-guard := escrow-guard,
        'original-owner := original-owner,
        'account-guard := account-guard
      }
      {
        'escrow-account: escrow-account,
        'escrow-guard: escrow-guard,
        'original-owner: original-owner,
        'account-guard: account-guard
      }
    )
  )

  (defun get-slot-type-max:decimal (type:string)
    (with-read plot-slot-constant-table (hash type)
      {
        'max := max
      }
      max
    )
  )

  (defun item-has-policy-active:bool (token-id:string policy-type:string policy:module{kip.token-policy-v2})
    (contains policy (at policy-type (at 'policies (marmalade.ledger.get-token-info token-id))))
  )

  (defun get-staked-items-on-plot:object{plot-staking-schema} (plot-id:string)
    (select plot-staking-table
      [
        'plot-id,
        'item-id,
        'amount,
        'type,
        'account,
        'locked-since
      ]
      (where 'plot-id (= plot-id))
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