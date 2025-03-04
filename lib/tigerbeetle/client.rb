require 'ffi'
require 'tb_client'
require 'tigerbeetle/account'
require 'tigerbeetle/account_balance'
require 'tigerbeetle/account_filter'
require 'tigerbeetle/query_filter'
require 'tigerbeetle/request'
require 'tigerbeetle/transfer'

module TigerBeetle
  class Client
    # TODO: Make this counter atomic
    @counter = 0

    def self.next_id
      @counter += 1
    end

    def initialize(cluster_id = 0, address = '3000')
      @inflight_requests = {}
      # Keep a pointer to prevent proc from getting GCed
      @callback = Proc.new { |*args| callback(*args) }
      @client_id = self.class.next_id
      @client_ptr = FFI::MemoryPointer.new(:pointer, 1) # **void
      cluster_id_ptr = serialize([cluster_id], TBClient::UInt128)

      status = TBClient.tb_client_init(
        @client_ptr,
        cluster_id_ptr,
        address,
        address.length,
        @client_id,
        &@callback
      )

      raise "Error while initializing client: #{status}" unless status == :SUCCESS
    end

    def create_accounts(*accounts, &block)
      submit_request(
        :CREATE_ACCOUNTS,
        accounts,
        TBClient::Account,
        TBClient::CreateAccountsResult,
        &block
      )
    end

    def create_transfers(*transfers, &block)
      submit_request(
        :CREATE_TRANSFERS,
        transfers,
        TBClient::Transfer,
        TBClient::CreateTransfersResult,
        &block
      )
    end

    def lookup_accounts(*account_ids, &block)
      submit_request(
        :LOOKUP_ACCOUNTS,
        account_ids,
        TBClient::UInt128,
        TBClient::Account,
        &block
      )
    end

    def lookup_transfers(*transfer_ids, &block)
      submit_request(
        :LOOKUP_TRANSFERS,
        transfer_ids,
        TBClient::UInt128,
        TBClient::Transfer,
        &block
      )
    end

    def get_account_transfers(filter, &block)
      submit_request(
        :GET_ACCOUNT_TRANSFERS,
        [filter],
        TBClient::AccountFilter,
        TBClient::Transfer,
        &block
      )
    end

    def get_account_balances(filter, &block)
      submit_request(
        :GET_ACCOUNT_BALANCES,
        [filter],
        TBClient::AccountFilter,
        TBClient::AccountBalance,
        &block
      )
    end

    def query_accounts(filter, &block)
      submit_request(
        :QUERY_ACCOUNTS,
        [filter],
        TBClient::QueryFilter,
        TBClient::Account,
        &block
      )
    end

    def query_transfers(filter, &block)
      submit_request(
        :QUERY_TRANSFERS,
        [filter],
        TBClient::QueryFilter,
        TBClient::Transfer,
        &block
      )
    end

    def deinit
      TBClient.tb_client_deinit(client_ptr.read(:pointer))
      @client_ptr = nil
    end

    private

    attr_reader :context, :client_ptr, :inflight_requests

    def callback(client_id, client, packet, timestamp, result_ptr, result_len)
      request_id = packet[:user_data].read_uint64
      request = inflight_requests[request_id]
      result = deserialize(result_ptr, request.response_type, result_len)
      request.block.call(result)
    end

    def submit_request(operation, request, request_type, response_type, &block)
      request_id = self.class.next_id
      user_data_ptr = FFI::MemoryPointer.new(:uint64, 1)
      user_data_ptr.write_uint64(request_id)

      data_ptr = serialize(request, request_type)

      packet = TBClient::Packet.new
      packet[:user_data] = user_data_ptr
      packet[:operation] = operation
      packet[:status] = :OK
      packet[:data_size] = data_ptr.size
      packet[:data] = data_ptr

      queue = Queue.new
      inflight_requests[request_id] = Request.new(packet, response_type) do |response|
        if block
          block.call(response)
        else
          queue << response
        end
      end

      TBClient.tb_client_submit(client_ptr.read(:pointer), packet)

      # block until the client return a response
      queue.pop unless block
    end

    def serialize(data, type)
      data_ptr = FFI::MemoryPointer.new(type, data.length, true)
      data.each_with_index do |value, i|
        # initialize type at the memory address and write value over it
        type.new(data_ptr[i]).from(value)
      end

      data_ptr
    end

    def deserialize(ptr, type, length)
      # copy the memory own to retain the data after tb_client has freed its memory
      own_ptr = FFI::MemoryPointer.new(:char, type.size * length)
      own_ptr.put_bytes(0, ptr.read_bytes(type.size * length))

      Array.new(length / type.size) do |i|
        type.new(own_ptr + i * type.size)
      end
    end
  end
end
