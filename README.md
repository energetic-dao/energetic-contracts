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

Every contract in Pact represents a module that can be imported into other contracts. 

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
    fungible:module{kip.fungible-v2}
  )
```

### Marmalade Standard

### Policy