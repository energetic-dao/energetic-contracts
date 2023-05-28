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
      'immutable-policies: [free.energetic-manifest-policy],
      'adjustable-policies: []
    }
  )

  (defconst PLOT_COLLECTION_ID:string "collection:DEulkJ-qDySv_BFKQvJEj315-x5JdnFObku8DXk4iKI")
  (defconst PLOT_ONE_TOKEN_ID:string (create-token-id { 'uri: "plot-1-uri", 'precision: 0, 'policies: PLOT_COLLECTION_POLICIES }))
  (defconst PLOT_STAKING_CENTER_ESCROW_ACCOUNT:string (format "m:free.energetic-plot-staking-center:{}" [PLOT_ONE_TOKEN_ID]))

  (defconst PLOT_MANIFEST:object{manifest}
    (kip.token-manifest.create-manifest (kip.token-manifest.uri "text" "@todo") [
      (kip.token-manifest.create-datum (kip.token-manifest.uri "text" "json")
        {
          'attributes: [
            {
              'trait_type: "name",
              'value: "Plot #1"
            },
            {
              'trait_type: "description",
              'value: "A plot of land in the energetic ecosystem."
            },
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
              'trait_type: "Color",
              'value: "lightblue"
            }
          ]
        }
      )
    ])
  )

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
      'immutable-policies: [free.energetic-upgradable-item-policy free.energetic-manifest-policy],
      'adjustable-policies: []
    }
  )

  (defconst PLOT_UPGRADES_COLLECTION_ID:string "collection:db4yAq2OOvKGcC2FAWO6rRcFkyKNw4Ue2F64EW3S13g")
  (defconst ROOF_SOLAR_PANEL_TOKEN_ID:string (create-token-id { 'uri: "roof-solar-panel-upgrade-uri", 'precision: 0, 'policies: PLOT_UPGRADES_COLLECTION_POLICIES }))

  (defconst ROOF_SOLAR_PANEL_MANIFEST:object{manifest}
    (kip.token-manifest.create-manifest (kip.token-manifest.uri "text" "@todo") [
      (kip.token-manifest.create-datum (kip.token-manifest.uri "text" "json")
        {
          'attributes: [
            {
              'trait_type: "name",
              'value: "Roof Solar Panel"
            },
            {
              'trait_type: "description",
              'value: "A solar panel that can be placed on a roof."
            },
            {
              'trait_type: "type",
              'value: "solar-panel"
            },
            {
              'trait_type: "power",
              'value: 2.0
            }
          ]
        }
      )
    ])
  )
)