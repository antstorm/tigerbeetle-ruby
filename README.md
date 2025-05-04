# Ruby Client for TigerBeetle

[![Gem](https://badge.fury.io/rb/tigerbeetle.svg)](https://rubygems.org/gems/tigerbeetle)
[![CI](https://github.com/antstorm/tigerbeetle-ruby/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/antstorm/tigerbeetle-ruby/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/antstorm/tigerbeetle-ruby.svg)](https://opensource.org/licenses/apache-2-0)

Are you looking to integrate [Tigebeetle](https://tigerbeetle.com/) into your Ruby (or Rails) stack?
You've come to the right place!

TigerBeetle is a high performance financial transaction database (i.e. Ledger) designed to power
the next 30 years of Online Transaction Processing. And this is a feature complete Ruby client for
it that leverages [the native Zig client](https://tigerbeetle.com/blog/2023-02-21-writing-high-performance-clients-for-tigerbeetle/).


## Usage

Start by adding the TigerBeetle gem to your Gemfile:

```ruby
gem 'tigerbeeetle'
```

Ensure TigerBeetle is running ([more on this](https://docs.tigerbeetle.com/start/)):

```bash
$ curl -Lo tigerbeetle.zip https://linux.tigerbeetle.com && unzip tigerbeetle.zip && ./tigerbeetle version
$ ./tigerbeetle format --cluster=0 --replica=0 --replica-count=1 --development 0_0.tigerbeetle
$ ./tigerbeetle start --addresses=3000 --development 0_0.tigerbeetle
```

Connect your Ruby client and start using it:

```ruby
client = TigerBeetle.connect # using default cluster_id (0) and address (127.0.0.1:3000)

# create accounts
client.create_accounts(
  TigerBeetle::Account.new(id: 100, ledger: 1, code: 1),
  TigerBeetle::Account.new(id: 101, ledger: 1, code: 1)
)

# move funds between accounts
client.create_transfers(
  TigerBeetle::Transfer.new(
    id: 100,
    debit_account_id: 100,
    credit_account_id: 101,
    amount: 999,
    ledger: 1,
    code: 10
  )
)

# check balances
account_1, account_2 = client.lookup_accounts(100, 101)
account_1.debits_posted # 999
account_2.credits_posted # 999
```

*More information on the `ledger` and `code` attributes can be found
[here](https://docs.tigerbeetle.com/coding/data-modeling/).*

## IDs

You can choose whatever IDs you want when creating accounts and transfers (as long as they are
unique per cluster). However to leverage the maximum performance TigerBeetle recommends using
strictly increasing decentralized 128-bit IDs. To generate such an ID you can use the provided
`TigerBeetle.id` method.

```ruby
client.create_accounts(
  TigerBeetle::Account.new(id: TigerBeetle.id, ledger: 1, code: 1)
)
```

*More on how to approach this — https://docs.tigerbeetle.com/coding/data-modeling/#id.*


## Contributing

We'd love your help building the TigerBeetle Ruby gem.

- Join the [official Slack](https://slack.tigerbeetle.com/join) for general questions on TigerBeetle
- For any discovered problems or questions about the Ruby client — [open a new issue](https://github.com/antstorm/tigerbeetle-ruby/issues/new)
- For codebase improvements:
  - Fork this repo
  - Implement your changes
  - Ensure the tests pass by running `bundle exec rspec`
  - Open a new pull request


## License

This project is licensed under [Apache 2.0 license](https://github.com/temporalio/temporal/blob/main/LICENSE).
