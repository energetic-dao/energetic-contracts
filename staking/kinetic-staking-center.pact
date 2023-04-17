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
    escrow-account:string
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

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.kinetic-admin")
  )

  (defcap PRIVATE:bool ()
    true
  )

  (defcap STAKE:bool (account:string escrow-account:string token-id:string amount:decimal)
    true
  )
  
  (defcap COLLECTION_POOL:bool (pool-id:string) 
    true
  )

  ;;
  ;; Pool
  ;;

  (defun require-POOL:bool (pool-id:string)
    (require-capability (COLLECTION_POOL pool-id))
  )

  (defun create-pool-guard:guard (pool-id:string)
    (create-user-guard (require-POOL pool-id))
  )

  (defun create-escrow-account (pool-id:string)
    (create-principal (create-pool-guard pool-id))
  )
  
  ;;
  ;; Utility Functions
  ;;

  (defun current-time:time ()
    (at 'block-time (chain-data))
  )

  ;;
  ;; Functions
  ;;

  (defun create-collection-pool:string (name:string collection-id:string payout-currency:module{kip.fungible-v2} apy:decimal guard:guard)
    ;(with-capability (GOVERNANCE) @todo figure out why this is failing (Keyset failure (keys-all): 'free.kinetic-admin")
      (let
        (
          (escrow-pool-guard (create-pool-guard collection-id))
          (escrow-account (create-escrow-account collection-id))
        )
        (payout-currency::create-account escrow-account escrow-pool-guard)
        (insert collection-pool-table collection-id
          { 
            'name: name,
            'escrow-account: escrow-account,
            'payout-currency: payout-currency,
            'apy: apy,
            'guard: guard
          }
        )
        { 
          'name: name,
          'escrow-account: escrow-account,
          'payout-currency: payout-currency,
          'apy: apy,
          'guard: guard
        }
      )
    ;)
  )

  (defun stake:string (pool-id:string account:string account-guard:guard token-id:string amount:decimal)
    (enforce (>= amount 0.0) "Amount must be greater than 0")
    (with-read collection-pool-table pool-id
      {
        'escrow-account:= escrow-account
      }

      (let
        (
          (escrow-pool-guard (create-pool-guard pool-id))
        )
        (marmalade.ledger.create-account token-id escrow-account escrow-pool-guard)
        (with-capability (STAKE account escrow-account token-id amount)
          (marmalade.ledger.transfer token-id account escrow-account amount)
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
            true
          )
        )
      )
    )
  )

  ;;
  ;; Getters
  ;;

  (defun get-amount-of-tokens-staked (token-id:string account:string)
    (with-default-read staked-nft-table (format "{}:{}" [token-id account])
      {
        'amount: 0.0,
        'token-id: token-id,
        'locked-since: (current-time)
      }
      {
        'amount := amount
      }
      {
        'amount: amount
      }
    )
  )

  (defun get-pool (pool-id:string)
    (with-read collection-pool-table pool-id
      {
        'name:= name,
        'escrow-account:= escrow-account,
        'payout-currency:= payout-currency,
        'apy:= apy,
        'guard:= guard
      }
      {
        'name: name,
        'escrow-account: escrow-account,
        'payout-currency: payout-currency,
        'apy: apy,
        'guard: guard
      }
    )
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