require 'ffi'
require 'tb_client'
require 'tigerbeetle/converters'
require 'tigerbeetle/account'
require 'tigerbeetle/account_balance'
require 'tigerbeetle/account_filter'
require 'tigerbeetle/atomic_counter'
require 'tigerbeetle/error'
require 'tigerbeetle/query_filter'
require 'tigerbeetle/request'
require 'tigerbeetle/transfer'

module TigerBeetle
  class Client
    def self.next_id
      @counter ||= AtomicCounter.new
      @counter.increment
    end

    def initialize(cluster_id = 0, address = '3000')
      @inflight_requests = {}
      # Keep a pointer to prevent proc from getting GCed
      @callback = Proc.new { |*args| callback(*args) }
      @client_id = self.class.next_id
      @client = TBClient::Client.new

      # FFI::MemoryPointer.new(:pointer, 1) # **void
      cluster_id_ptr = serialize([cluster_id], Converters::UInt128)

      status = TBClient.tb_client_init(
        @client,
        cluster_id_ptr,
        address,
        address.length,
        @client_id,
        &@callback
      )
      raise ClientError, "Unable to initialize native client: #{status}" unless status == :SUCCESS

      # Make sure to deinitialize all clients when the process terminates
      at_exit { deinit }
    end

    def logger=(logger)
      @logger = logger
      @log_callback = @logger ? Proc.new { |*args| log_callback(*args) } : nil

      status = TBClient.tb_client_register_log_callback(@log_callback, true)
      raise ClientError, "Unable to register logger: #{status}" unless status == :SUCCESS
    end

    def create_accounts(*accounts, &block)
      submit_request(
        :CREATE_ACCOUNTS,
        accounts,
        Converters::Account,
        Converters::CreateAccountsResult,
        &block
      )
    end

    def create_transfers(*transfers, &block)
      submit_request(
        :CREATE_TRANSFERS,
        transfers,
        Converters::Transfer,
        Converters::CreateTransfersResult,
        &block
      )
    end

    def lookup_accounts(*account_ids, &block)
      submit_request(
        :LOOKUP_ACCOUNTS,
        account_ids,
        Converters::UInt128,
        Converters::Account,
        &block
      )
    end

    def lookup_transfers(*transfer_ids, &block)
      submit_request(
        :LOOKUP_TRANSFERS,
        transfer_ids,
        Converters::UInt128,
        Converters::Transfer,
        &block
      )
    end

    def get_account_transfers(filter, &block)
      submit_request(
        :GET_ACCOUNT_TRANSFERS,
        [filter],
        Converters::AccountFilter,
        Converters::Transfer,
        &block
      )
    end

    def get_account_balances(filter, &block)
      submit_request(
        :GET_ACCOUNT_BALANCES,
        [filter],
        Converters::AccountFilter,
        Converters::AccountBalance,
        &block
      )
    end

    def query_accounts(filter, &block)
      submit_request(
        :QUERY_ACCOUNTS,
        [filter],
        Converters::QueryFilter,
        Converters::Account,
        &block
      )
    end

    def query_transfers(filter, &block)
      submit_request(
        :QUERY_TRANSFERS,
        [filter],
        Converters::QueryFilter,
        Converters::Transfer,
        &block
      )
    end

    def deinit
      return unless client
      return unless inflight_requests.empty?

      TBClient.tb_client_deinit(client)
      @client = nil
    end

    private

    attr_reader :context, :client, :inflight_requests, :logger

    def log_callback(level, ptr, length)
      message = ptr.read_string(length).force_encoding('UTF-8')
      case level
      when :ERR then logger.error(message)
      when :WARN then logger.warn(message)
      when :INFO then logger.info(message)
      when :DEBUG then logger.debug(message)
      end
    end

    def callback(client_id, packet, timestamp, result_ptr, result_len)
      request_id = packet[:user_data].read_uint64
      request = inflight_requests.delete(request_id)
      result = deserialize(result_ptr, request.converter, result_len)
      request.block.call(result)
    end

    def submit_request(operation, request, request_converter, response_converter, &block)
      raise ClientError, 'Client is not connected' unless client

      request_id = self.class.next_id
      user_data_ptr = FFI::MemoryPointer.new(:uint64, 1)
      user_data_ptr.write_uint64(request_id)

      data_ptr = serialize(request, request_converter)

      packet = TBClient::Packet.new
      packet[:user_data] = user_data_ptr
      packet[:operation] = operation
      packet[:status] = :OK
      packet[:data_size] = data_ptr.size
      packet[:data] = data_ptr

      queue = Queue.new
      inflight_requests[request_id] = Request.new(packet, response_converter) do |response|
        if block
          block.call(response)
        else
          queue << response
        end
      end

      status = TBClient.tb_client_submit(client, packet)
      raise ClientError, "Unable to submit request: #{status}" unless status == :OK

      # block until the client return a response
      queue.pop unless block
    end

    def serialize(data, converter)
      data_ptr = FFI::MemoryPointer.new(converter.native_type, data.length, true)
      data.each_with_index do |value, i|
        # initialize type at the memory address and write value over it
        converter.to_native(data_ptr[i], value)
      end

      data_ptr
    end

    def deserialize(ptr, converter, length)
      type = converter.native_type
      # copy the memory own to retain the data after tb_client has freed its memory
      own_ptr = FFI::MemoryPointer.new(:char, type.size * length)
      own_ptr.put_bytes(0, ptr.read_bytes(type.size * length))

      Array.new(length / type.size) do |i|
        converter.from_native(own_ptr + i * type.size)
      end
    end
  end
end
