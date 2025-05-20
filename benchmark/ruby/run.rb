#!/usr/bin/env ruby

require 'tigerbeetle'

LEDGER = 999
CODE = 1

def prepare_accounts(client)
  accounts = [
    TigerBeetle::Account.new(id: TigerBeetle.id, ledger: LEDGER, code: CODE),
    TigerBeetle::Account.new(id: TigerBeetle.id, ledger: LEDGER, code: CODE)
  ]
  client.create_accounts(*accounts)

  accounts.map(&:id)
end

def create_transfer(debit_id, credit_id)
  TigerBeetle::Transfer.new(
    id: TigerBeetle.id,
    debit_account_id: debit_id,
    credit_account_id: credit_id,
    amount: 10,
    ledger: LEDGER,
    code: CODE,
  )
end

def measure
  start = Time.now
  yield
  ((Time.now - start) * 1000).round
end

def run_test(client, total, batch_size, from, to)
  min = Float::INFINITY
  max = 0
  iterations = (total.to_f / batch_size).ceil
  
  iterations.times do |i|
    transfers = []
    [batch_size, total].min.times { transfers << create_transfer(from, to) }
    elapsed = measure { client.create_transfers(*transfers) }
    
    max = elapsed if elapsed > max
    min = elapsed if elapsed < min
    total -= batch_size
  end

  [min, max]
end

client = TigerBeetle.connect
from, to = prepare_accounts(client)

n = ENV.fetch('N', 10_000).to_i
b = ENV.fetch('B', 1_000).to_i

min, max = 0
elapsed = measure { min, max = run_test(client, n, b, from, to) }

puts "Total time: #{elapsed} ms"
puts "Avg: #{elapsed.to_f / n} ms"
puts "Min batch time: #{min} ms"
puts "Max batch time: #{max} ms"

