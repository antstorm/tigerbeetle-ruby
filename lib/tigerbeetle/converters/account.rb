require 'tb_client'
require 'tigerbeetle/account'
require 'tigerbeetle/converters/time'
require 'tigerbeetle/converters/uint_128'

module TigerBeetle
  module Converters
    module Account
      def self.native_type
        TBClient::Account
      end

      def self.from_native(ptr)
        c_value = TBClient::Account.new(ptr)

        TigerBeetle::Account.new(
          id: Converters::UInt128.from_native(c_value[:id].to_ptr),
          debits_pending: Converters::UInt128.from_native(c_value[:debits_pending].to_ptr),
          debits_posted: Converters::UInt128.from_native(c_value[:debits_posted].to_ptr),
          credits_pending: Converters::UInt128.from_native(c_value[:credits_pending].to_ptr),
          credits_posted: Converters::UInt128.from_native(c_value[:credits_posted].to_ptr),
          user_data_128: Converters::UInt128.from_native(c_value[:user_data_128].to_ptr),
          user_data_64: c_value[:user_data_64],
          user_data_32: c_value[:user_data_32],
          ledger: c_value[:ledger],
          code: c_value[:code],
          flags: c_value[:flags],
          timestamp: Converters::Time.from_native(ptr + c_value.offset_of(:timestamp))
        )
      end

      def self.to_native(ptr, value)
        TBClient::Account.new(ptr).tap do |result|
          Converters::UInt128.to_native(result[:id].to_ptr, value.id)
          Converters::UInt128.to_native(result[:debits_pending].to_ptr, value.debits_pending)
          Converters::UInt128.to_native(result[:debits_posted].to_ptr, value.debits_posted)
          Converters::UInt128.to_native(result[:credits_pending].to_ptr, value.credits_pending)
          Converters::UInt128.to_native(result[:credits_posted].to_ptr, value.credits_posted)
          Converters::UInt128.to_native(result[:user_data_128].to_ptr, value.user_data_128)
          result[:user_data_64] = value.user_data_64
          result[:user_data_32] = value.user_data_32
          result[:reserved] = 0
          result[:ledger] = value.ledger
          result[:code] = value.code
          result[:flags] = value.flags
          Converters::Time.to_native(ptr + result.offset_of(:timestamp), value.timestamp || 0)
        end
      end
    end
  end
end
