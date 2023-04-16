(namespace (read-msg 'ns ))
(module kinetic-staking-center GOVERNANCE

  ;; @todo
  ;; - add ability to unstake
  ;; - add ability to withdraw
  ;; - add ability to update pool
  ;; - add events

  ;;
  ;; Constants
  ;;

  ;;
  ;; Schemas
  ;;
  (defschema collection-pool-schema
    name:string
    escrow-address:string
    payout-currency:module{kip.fungible-v2}
    apy:decimal
    guard:guard
  )

  (defschema account-staking-schema
    pool-id:string
    account:string
    account-guard:guard
  )

  (defschema staked-nft-schema
    token-id:string
    amount:decimal
    locked-since:time
  )

  (deftable collection-pool-table:{collection-pool-schema})
  (deftable account-staking-table:{account-staking-schema})
  (deftable staked-nft-table:{staked-nft-schema})

  ;;
  ;; Capabilities
  ;;
  (defcap GOVERNANCE ()
    (enforce-keyset "free.kinetic-admin")
  )

  (defcap PRIVATE ()
    true
  )

  (defcap STAKE (account:string escrow-account:string token-id:string amount:decimal)
    true
  )

  ;;
  ;; Utility Functions
  ;;

  (defun create-pool-guard:guard (pool-id:string)
    (with-capability (PRIVATE)
      (create-module-guard pool-id)
    )
  )

  (defun create-escrow-address (pool-id:string)
    (with-capability (PRIVATE)
      (create-principal (create-pool-guard pool-id))
    )
  )

  (defun current-time:time ()
    (at 'block-time (chain-data))
  )

  ;;
  ;; Functions
  ;;

  (defun create-collection-pool:string (name:string collection-id:string payout-currency:module{kip.fungible-v2} apy:decimal guard:guard)
    ;;(with-capability (GOVERNANCE)
      (let
        (
          (escrow-pool-guard (create-pool-guard collection-id))
          (escrow-address (create-escrow-address collection-id))
        )
        (payout-currency::create-account escrow-address escrow-pool-guard)
        ; (marmalade.ledger.create-account token-id escrow-address escrow-pool-guard)
        (insert collection-pool-table collection-id
          { 
            'name: name,
            'escrow-address: escrow-address,
            'payout-currency: payout-currency,
            'apy: apy,
            'guard: guard
          }
        )
      )
    ;;)
  )

  (defun stake:string (pool-id:string account:string account-guard:guard token-id:string amount:decimal)
    (with-capability (GOVERNANCE)
      (enforce (>= amount 0.0) "Amount must be greater than 0")
      (with-read collection-pool-schema pool-id
        {
          'escrow-address:= escrow-address
        }

        (with-capability (STAKE account escrow-address token-id)
          (marmalade.ledger.transfer token-id account escrow-address amount)
          (write account-staking-table (format "{}:{}" [pool-id account])
            {
              'pool-id: pool-id,
              'account: account,
              'account-guard: account-guard
            }
          )
          (bind (get-amount-of-tokens-staked token-id account)
            {
              'amount:= amount-staked
            }
            (if (> amount-staked 0.0)
              (update staked-nft-table (format "{}:{}" [token-id account])
                {
                  'amount: (+ amount (at 'amount (read staked-nft-table (format "{}:{}" [token-id account]))))
                }
              )
              (insert staked-nft-table (format "{}:{}" [token-id account])
                {
                  'token-id: token-id,
                  'amount: amount,
                  'locked-since: (at 'block-time (chain-data))
                }
              )
            )
          )
        )
      )
    )
  )

  ;;
  ;; Getters
  ;;

  (defun get-amount-of-tokens-staked (token-id:string account:string)
    ;;(with-default-read staked-nft-table (format "{}:{}" [token-id account])
    ;;  {
    ;;    'amount: 0.0,
    ;;    'token-id: token-id,
    ;;    'locked-since: (current-time)
    ;;  }
    ;;  {
    ;;    'amount := amount
    ;;  }
    ;;)
    0.0
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  [
    (create-table collection-pool-table)
    (create-table account-staking-table)
    (create-table staked-nft-table)
  ]
)