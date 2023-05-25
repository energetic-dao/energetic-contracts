(module energetic-constants GOVERNANCE
  (use marmalade.ledger [create-token-id])
  (use kip.token-policy-v2 [token-policies concrete-policy])
  (use kip.token-manifest [manifest create-manifest create-datum uri])

  (defcap GOVERNANCE () true)
  
  (defconst PLOT_COLLECTION:object{concrete-policy}
    { 
      'quote-policy: true,
      'non-fungible-policy: true,
      'royalty-policy: false, ; @todo
      'collection-policy: true
    }
  )

  (defconst PLOT_COLLECTION_POLICIES:object{token-policies}
    { 
      'concrete-policies: PLOT_COLLECTION,
      'immutable-policies: [test.energetic-upgradable-item-policy, test.energetic-manifest-policy],
      'adjustable-policies: []
    }
  )

  (defconst PLOT_COLLECTION_ID:string "collection:DEulkJ-qDySv_BFKQvJEj315-x5JdnFObku8DXk4iKI")
  (defconst PLOT_ONE_TOKEN_ID:string (create-token-id { 'uri: "plot-1-uri", 'precision: 0, 'policies: PLOT_COLLECTION_POLICIES }))

  (defconst PLOT_MANIFEST:object{manifest}
    (kip.token-manifest.create-manifest (kip.token-manifest.uri "text" "@todo") [
      (kip.token-manifest.create-datum (kip.token-manifest.uri "text" "json")
        {
          'attributes: [
            {
              'trait_type: "Plot",
              'value: "normal"
            },
            {
              'trait_type: "Size",
              'value: "large"
            },
            {
              'trait_type: "Effect",
              'value: "floating"
            },
            {
              'trait_type: "Panels",
              'value: 0
            },
            {
              'trait_type: "Wind-Turbines",
              'value: 0
            }
            {
              'trait_type: "Batteries",
              'value: 0
            }
          ]
        }
      )
    ])
    )
)