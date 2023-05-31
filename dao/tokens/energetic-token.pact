(namespace (read-msg "ns"))
(module energetic-token GOVERNANCE
  (implements fungible-v2)
  (implements fungible-xchain-v1)
  
  (use util.fungible-util [check-reserved enforce-reserved])

  ;;
  ;; Schemas
  ;;

  (defschema coin-schema
    @model [
      (invariant (>= balance 0.0))
    ]
    balance:decimal
    guard:guard
  )

  (defschema supply-schema
    total-burned:decimal
    total-minted:decimal
    ; total-locked:decimal @todo TBD where the locking mechanism will be
  )

  ;; Operation per type
  (defschema operation-schema
    guard:guard
  )

  (defschema crosschain-schema
    @doc "Schema for yielded value in cross-chain transfers"
    receiver:string
    receiver-guard:guard
    amount:decimal
    source-chain:string
  )

  (deftable coin-table:{coin-schema})
  (deftable supply-table:{supply-schema})
  (deftable operation-table:{operation-schema})

  ;;
  ;; Constants
  ;;

  (defconst ADMIN_KEYSET (read-keyset "energetic-admin"))
  (defconst OPERATOR_KEYSET (read-keyset "energetic-operator"))

  (defconst COIN_CHARSET CHARSET_LATIN1
    "The default coin contract character set")

  (defconst MINIMUM_PRECISION 12
    "Minimum allowed precision for coin transactions")

  (defconst MINIMUM_ACCOUNT_LENGTH 3
    "Minimum account length admissible for coin accounts")

  (defconst MAXIMUM_ACCOUNT_LENGTH 256
    "Maximum account name length admissible for coin accounts")

  (defconst VALID_CHAIN_IDS (map (int-to-str 10) (enumerate 0 19))
    "List of all valid Chainweb chain ids")

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE ()
    (enforce-keyset ADMIN_KEYSET)
  )

  (defcap OPERATOR:bool ()
    (enforce-keyset OPERATOR_KEYSET)
  )

  (defcap DEBIT (sender:string)
    "Capability for managing debiting operations"
    (enforce-guard (at 'guard (read coin-table sender)))
    (enforce (!= sender "") "valid sender")
  )

  (defcap CREDIT (receiver:string)
    "Capability for managing crediting operations"
    (enforce (!= receiver "") "valid receiver")
  )

  (defcap ROTATE (account:string)
    @doc "Autonomously managed capability for guard rotation"
    @managed
    true
  )

  (defcap TRANSFER:bool (sender:string receiver:string amount:decimal)
    @managed amount TRANSFER-mgr
    (enforce (!= sender receiver) "same sender and receiver")
    (enforce-unit amount)
    (enforce (> amount 0.0) "Positive amount")
    (compose-capability (DEBIT sender))
    (compose-capability (CREDIT receiver))
  )

  (defun TRANSFER-mgr:decimal (managed:decimal requested:decimal)
    (let ((newbal (- managed requested)))
      (enforce (>= newbal 0.0) 
        (format "TRANSFER exceeded for balance {}" [managed]))
      newbal
    )
  )

  (defcap TRANSFER_XCHAIN:bool (sender:string receiver:string amount:decimal target-chain:string)
    @managed amount TRANSFER_XCHAIN-mgr
    (enforce-unit amount)
    (enforce (> amount 0.0) "Cross-chain transfers require a positive amount")
    (compose-capability (DEBIT sender))
  )

  (defun TRANSFER_XCHAIN-mgr:decimal (managed:decimal requested:decimal)
    (enforce (>= managed requested)
      (format "TRANSFER_XCHAIN exceeded for balance {}" [managed]))
    0.0
  )

  ;;
  ;; Events
  ;;
  
  (defcap TRANSFER_XCHAIN_RECD:bool (sender:string receiver:string amount:decimal source-chain:string)
    @event true
  )


  ;;
  ;; Utilities fungible-v2
  ;;

  (defun precision:integer ()
    MINIMUM_PRECISION
  )

  (defun enforce-unit:bool (amount:decimal)
    @doc "Enforce minimum precision allowed for coin transactions"
    (enforce
      (= (floor amount MINIMUM_PRECISION) amount)
      (format "Amount violates minimum precision: {}" [amount])
    )
  )

  (defun validate-account (account:string)
    @doc "Enforce that an account name conforms to the coin contract \
         \minimum and maximum length requirements, as well as the    \
         \latin-1 character set."
    (enforce
      (is-charset COIN_CHARSET account)
      (format
        "Account does not conform to the coin contract charset: {}"
        [account]
      )
    )

    (let 
      (
        (account-length (length account))
      )
      (enforce
        (>= account-length MINIMUM_ACCOUNT_LENGTH)
        (format
          "Account name does not conform to the min length requirement: {}"
          [account]
        )
      )

      (enforce
        (<= account-length MAXIMUM_ACCOUNT_LENGTH)
        (format
          "Account name does not conform to the max length requirement: {}"
          [account]
        )
      )
    )
  )

  ;;
  ;; Functions fungible-v2
  ;;

  (defun create-account:string (account:string guard:guard)
    @model [
      (property (valid-account account))
    ]

    (validate-account account)
    (enforce-reserved account guard)

    (insert coin-table account
      {
        "balance": 0.0,
        "guard": guard
      }
    )
  )

  (defun get-balance:decimal (account:string)
    (with-read coin-table account
      {
        "balance" := balance
      }
      balance
    )
  )

  (defun details:object{fungible-v2.account-details} (account:string)
    (with-read coin-table account
      {
        "balance" := bal,
        "guard" := g
      }
      {
        "account": account,
        "balance": bal,
        "guard": g
      }
    )
  )

  (defun rotate:string (account:string new-guard:guard)
    (with-capability (ROTATE account)
      (with-read coin-table account
        {
          "guard" := old-guard
        }

        (enforce-guard old-guard)

        (update coin-table account
          {
            "guard": new-guard
          }
        )
      )
    )
  )

  (defun transfer:string (sender:string receiver:string amount:decimal)
    @model [
      (property conserves-mass)
      (property (> amount 0.0))
      (property (valid-account sender))
      (property (valid-account receiver))
      (property (!= sender receiver))
    ]

    (enforce (!= sender receiver) "sender cannot be the receiver of a transfer")

    (validate-account sender)
    (validate-account receiver)

    (enforce (> amount 0.0) "transfer amount must be positive")

    (enforce-unit amount)

    (with-capability (TRANSFER sender receiver amount)
      (debit sender amount)
      (with-read coin-table receiver
        {
          "guard" := g
        }
        (credit receiver g amount)
      )
    )
  )

  (defun transfer-create:string (sender:string receiver:string receiver-guard:guard amount:decimal)
    @model [
      (property conserves-mass)
    ]

    (enforce (!= sender receiver)"sender cannot be the receiver of a transfer")

    (validate-account sender)
    (validate-account receiver)

    (enforce (> amount 0.0) "transfer amount must be positive")

    (enforce-unit amount)

    (with-capability (TRANSFER sender receiver amount)
      (debit sender amount)
      (credit receiver receiver-guard amount)
    )
  )

  (defun debit:string (account:string amount:decimal)
    @doc "Debit AMOUNT from ACCOUNT balance"

    @model [
      (property (> amount 0.0))
      (property (valid-account account))
    ]

    (validate-account account)

    (enforce (> amount 0.0) "debit amount must be positive")

    (enforce-unit amount)

    (require-capability (DEBIT account))
    (with-read coin-table account
      {
        "balance" := balance
      }

      (enforce (<= amount balance) "Insufficient funds")

      (update coin-table account
        {
          "balance": (- balance amount)
        }
      )
    )
  )

  (defun credit:string (account:string guard:guard amount:decimal)
    @doc "Credit AMOUNT to ACCOUNT balance"
    @model [
      (property (> amount 0.0))
      (property (valid-account account))
    ]

    (validate-account account)

    (enforce (> amount 0.0) "credit amount must be positive")
    (enforce-unit amount)

    (require-capability (CREDIT account))
    (with-default-read coin-table account
      {
        "balance": -1.0,
        "guard": guard
      }
      {
        "balance" := balance,
        "guard" := retg
      }
      (enforce (= retg guard) "account guards do not match")

      (let
        (
          (is-new
            (if (= balance -1.0)
              (enforce-reserved account guard)
              false
            )
          )
        )

        (write coin-table account
          { "balance": (if is-new amount (+ balance amount))
          , "guard": retg
          }))
    )
  )

  (defpact transfer-crosschain:string (sender:string receiver:string receiver-guard:guard target-chain:string amount:decimal)
    @model [
      (property (> amount 0.0))
      (property (valid-account sender))
      (property (valid-account receiver))
    ]

    (step
      (with-capability (TRANSFER_XCHAIN sender receiver amount target-chain)

        (validate-account sender)
        (validate-account receiver)

        (enforce (!= "" target-chain) "empty target-chain")
        (enforce 
          (!= (at 'chain-id (chain-data)) target-chain)
          "cannot run cross-chain transfers to the same chain"
        )

        (enforce (> amount 0.0) "transfer quantity must be positive")

        (enforce-unit amount)

        (enforce (contains target-chain VALID_CHAIN_IDS) "target chain is not a valid chainweb chain id")

        ;; step 1 - debit delete-account on current chain
        (debit sender amount)
        (emit-event (TRANSFER sender "" amount))

        (let
          (
            (crosschain-details:object{crosschain-schema}
              {
                "receiver": receiver,
                "receiver-guard": receiver-guard,
                "amount": amount,
                "source-chain": (at 'chain-id (chain-data))
              }
            )
          )
          (yield crosschain-details target-chain)
        )
      )
    )

    (step
      (resume
        {
          "receiver" := receiver,
          "receiver-guard" := receiver-guard,
          "amount" := amount,
          "source-chain" := source-chain
        }

        (emit-event (TRANSFER "" receiver amount))
        (emit-event (TRANSFER_XCHAIN_RECD "" receiver amount source-chain))

        ;; step 2 - credit create account on target chain
        (with-capability (CREDIT receiver)
          (credit receiver receiver-guard amount)
        )
      )
    )
  )
)

(if (read-msg "upgrade")
  ["upgrade complete"]
  [
    (create-table coin-table)
    (create-table supply-table)
    (create-table operation-table)
  ]
)
