(module energetic-constants GOVERNANCE
  (use marmalade.ledger [create-token-id])
  (use kip.token-policy-v2 [token-policies concrete-policy])
  (use free.energetic-plot-item-policy [metadata])

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
      'immutable-policies: [free.energetic-plot-policy],
      'adjustable-policies: []
    }
  )

  (defconst PLOT_COLLECTION_ID:string "collection:DEulkJ-qDySv_BFKQvJEj315-x5JdnFObku8DXk4iKI")
  (defconst PLOT_ONE_TOKEN_ID:string (create-token-id { 'uri: "plot-1-uri", 'precision: 0, 'policies: PLOT_COLLECTION_POLICIES }))
  (defconst PLOT_STAKING_CENTER_ESCROW_ACCOUNT:string (format "m:free.energetic-plot-staking-center:{}" [PLOT_ONE_TOKEN_ID]))

  ;; Roof Solar Panels
  (defconst PLOT_UPGRADES_COLLECTION:object{concrete-policy}
    { 
      'quote-policy: true,
      'non-fungible-policy: false,
      'royalty-policy: false, ; @todo
      'collection-policy: true
    }
  )

  (defconst PLOT_UPGRADES_COLLECTION_POLICIES:object{token-policies}
    { 
      'concrete-policies: PLOT_UPGRADES_COLLECTION,
      'immutable-policies: [free.energetic-plot-item-policy],
      'adjustable-policies: []
    }
  )

  (defconst PLOT_UPGRADES_COLLECTION_ID:string "collection:db4yAq2OOvKGcC2FAWO6rRcFkyKNw4Ue2F64EW3S13g")
  (defconst ROOF_SOLAR_PANEL_TOKEN_ID:string (create-token-id { 'uri: "roof-solar-panel-upgrade-uri", 'precision: 0, 'policies: PLOT_UPGRADES_COLLECTION_POLICIES }))

  (defconst ROOF_SOLAR_PANEL_METADATA:object{metadata}
    {
      'type: "roof-solar-panel",
      'power-rate: 2.2
    }
  )
)