(namespace (read-msg 'ns ))
(module kinetic-collections GOVERNANCE

  ;;
  ;; Schemas
  ;;

  (defschema collection-schema
    supply:decimal
    provenance-hash:string
    creator-account:string
    creator-guard:guard
    price:decimal
    fungible:module{kip.fungible-v2}
  )

  (defschema token-schema
    collection-id:string
    supply:decimal
  )

  (deftable tokens:{token-schema})
  (deftable collections:{collection-schema})

  (defschema collection-info
    id:string
  )

  ;;
  ;; Capabilities
  ;;

  (defcap GOVERNANCE:bool ()
    (enforce-keyset "free.kinetic-admin")
  )

  ;;
  ;; Events
  ;;

  (defcap COLLECTION_CREATED:bool (id:string supply:decimal provenance-hash:string creator:string price:decimal)
    @event
    true
  )

  ;;
  ;; Functions
  ;;

  (defun create-collection:bool (id:string supply:decimal provenance-hash:string creator:string creator-guard:guard price:decimal fungible:module{kip.fungible-v2})
    (with-capability (GOVERNANCE)
      (insert collections id
        {
          'supply: supply,
          'provenance-hash: provenance-hash,
          'creator-account: creator,
          'creator-guard: creator-guard,
          'price: price,
          'fungible: fungible
        }
      )
      (emit-event (COLLECTION_CREATED id supply provenance-hash creator price))
      true
    )
  )

  (defun create-token (token-id:string collection-id:string supply:decimal)
    (with-capability (GOVERNANCE)
      (insert tokens token-id
        {
          'collection-id: collection-id,
          'supply: supply
        }
      )
    )
  )

  ;;
  ;; Getters
  ;;

  (defun get-collection:object{collection-schema} (id:string)
    (with-read collections id
      {
        'supply := supply,
        'provenance-hash := provenance-hash,
        'creator-account := creator-account,
        'creator-guard := creator-guard,
        'price := price,
        'fungible := fungible
      }
      {
        'supply: supply,
        'provenance-hash: provenance-hash,
        'creator-account: creator-account,
        'creator-guard: creator-guard,
        'price: price,
        'fungible: fungible
      }
    )
  )

  (defun get-token (id:string)
    (with-read tokens id
      {
        'collection-id := collection-id,
        'supply := supply
      }
      {
        'collection-id: collection-id,
        'supply: supply
      }
    )
  )
)

(if (read-msg 'upgrade )
  ["upgrade complete"]
  [
    (create-table tokens)
    (create-table collections)
  ]
)