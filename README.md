# Kinetic-DAO Contracts

## Kadena

## Pact

[Pact](https://github.com/kadena-io/pact) is an turing-incomplete language for writing smart contracts on the Kadena blockchain.

### Documentation

For more information on Pact, please see the [Pact documentation](https://pact-language.readthedocs.io/en/latest/).

### Installation

#### Linux

Download the latest release for your distro from [here](https://github.com/kadena-io/pact/releases) and enter the following commands:

```bash
  unzip pact-<version>.zip
```

```bash
  sudo mv pact /usr/bin
```

```bash
  pact --version
```

#### Mac

Use [Homebrew](https://brew.sh/) to install Pact:

```bash
  brew update
  brew install kadena-io/pact/pact
```

### Namespaces

It is possible within Pact to use namespaces to organize your code. For example, you can create a namespace called `my-namespace` and then create a module called `my-module` within that namespace. This is done by using the `namespace` keyword. For example:

```js
  (namespace 'my-namespace)
  (module my-module)
```

#### Keysets

When defining a namespace a keyset needs to be passed. The ownership and use of this namespace is controlled by a guard.

```js
  (define-namespace 'my-namespace (read-keyset 'user-ks) (read-keyset 'admin-ks))
```

Within the module it is possible to use keysets as Guard for restricting access to different functions. Inorder to use a keyset as a guard, the keyset needs to be defined within the module. This is done the same way as for namespaces, but using define-keyset.


```js
  (define-keyset "<namespace_name>.<keyset_name>" (read-keyset "<keyset_in_env_data>" ))
```

### Modules

Every contract in Pact represents a module that represents the business logic of the contract. This logic can be used directly or can be used as a library for other contracts. A module can be defined by using the `module` keyword. For example:

```js
  (module my-module)
```

### Interfaces

An interface is like in any other programming language. This can be used to predefine functions that can be used within the module. This not only limits to functions, but also constants, schema's, capabilities, etc. can be predefined. It can also be used to predefine a type that is used in a schema or functionparameter to make sure the module being passed in is of the correct type.

```js
  (interface poly-fungible
    (defun total-supply:decimal (id:string)
      @doc
        " Give total available quantity of ID. If not supported, return 0."
    )
  )
```

```js
  (defschema collection-schema
    supply:decimal
    provenance-hash:string
    tokens:[string]
    creator-account:string
    creator-guard:guard
    price:decimal
    fungible:module{fungible-v2}
  )
```

### Marmalade

Marmalade is the NFT standard on the Kadena blockchain. It is referred as a mintable market place, which makes it possible to handle NFT's in a single ledger contract. Within the contract it is possible to create tokens and do the natural operations on them such as minting, transfering, burning, etc. The basic functionality will be inheirited in a policy contract, which makes it possible to implement custom logic on top of the basic functionality.

### Manifest (Metadata)

The manifest data is used to define the metadata of the token. Within the manifest it is possible to define a `uri` for the metadata which can be a reference to ipfs, another contract, text, json or any other schema. Next up it is possible to define datums within the manifest. This represents the actual metadata of the token. A datum contains a hashed field that is the hash of the `uri` and the `datum` in order to verify the data. with the uri and datum it is possible to create a manifest which is made up of a `uri` and a list of datums. This manifest can later be used to generate a token id for the token which is done via the `create-token-id` function within marmlade.

```ts
  (let*
    (
      (uri:mf-uri (uri "image-file-hash" "https://ipfs"))
      (datum (create-datum (uri "attribute-file-hash" "https://ipfs")
        { 
        "attributes": [
          {
            "property": "id",
            "value": 1
          }
          {
            "property": "name",
            "value": "Collectible #1"
          },
          {
            "property": "description",
            "value": "This is the first collectible in the collection"
          }
        ]
      }))
      (manifest (create-manifest uri [datum]))
      (token-id (create-token-id manifest))
    )
  )
```

With this token it is then possible to create a marmalade token, the only thing that is still missing is the policy of the token.

### Schemas

```ts
  (defschema mf-uri
    scheme:string
    data:string
  )

  (defschema mf-datum
    uri:object{mf-uri}
    hash:string
    datum:object
  )

  (defschema manifest
    uri:object{mf-uri}
    hash:string
    data:[object{mf-datum}]
  )
```


### Policy

A token policy is used to define the extended functionality of the base ledger contract. This can be used to define custom logic on actions like token-init, mint, transfering. These actions will have the `(enforce-guard (marmalade.ledger.ledger-guard))` in there to prevent external execution other than directly from the marmalade legder contract.

In the example below there is the extended enforce-mint function which is triggered when calling:

```ts
  
  // this function triggers the enforce-init function within the policy
  (marmalade.ledger.create-token
    "t:56kzt2L4yM4GdqUvWHvxb9Z5bvrpCA5OaD9bejF1qXI" // token id
    0 // prescision
    manifest // token manifest (uri and datums)
    free.nft-policy // token policy
  )

  (marmalade.ledger.mint
    "t:56kzt2L4yM4GdqUvWHvxb9Z5bvrpCA5OaD9bejF1qXI" // token id
    "k:user" // mint account
    (read-keyset "k:user") // mint accoount guard
    1.0 // amount
  )
```

```ts
  (module nft-policy GOVERNANCE
    (use free.collection-contract [get-token update-token-supply])

    (defcap GOVERNANCE:bool ()
      (enforce-keyset "free.nft-admin")
    )

    (defun enforce-mint:bool (token:object{token-info} account:string guard:guard amount:decimal)
      (enforce-ledger)
      (with-capability (GOVERNANCE)
        (enforce (>= amount 0.0) "Invalid amount")
        (let*
          (
            (token-id:string (at "id" token))
            (token (get-token token-id))
            (supply:decimal (at "supply" token))
            (max-supply:decimal (at "max-supply" token))
            (new-supply:decimal (+ supply amount))
          )
          (enforce (or (<= new-supply max-supply) (= max-supply -1.0)) "max supply exceeded")
          (update-token-supply token-id new-supply)
        )
      )
    )
  )
```

### Marketplace