require_relative '../spec_helper'
require_relative '../fixtures/classes'

describe 'Socket.tcp_server_loop' do
  describe 'when no connections are available' do
    it 'blocks the caller' do
      lambda { Socket.tcp_server_loop('127.0.0.1', 0) }.should block_caller
    end
  end

  describe 'when a connection is available' do
    before do
      @client = Socket.new(:INET, :STREAM)
      SocketSpecs::ServerLoopPortFinder.cleanup
    end

    after do
      @sock.close if @sock
      @client.close
    end

    it 'yields a Socket and an Addrinfo' do
      @sock, addr = nil

      thread = Thread.new do
        SocketSpecs::ServerLoopPortFinder.tcp_server_loop('127.0.0.1', 0) do |socket, addrinfo|
          @sock = socket
          addr = addrinfo

          break
        end
      end

      port = SocketSpecs::ServerLoopPortFinder.port

      SocketSpecs.loop_with_timeout do
        begin
          @client.connect(Socket.sockaddr_in(port, '127.0.0.1'))
        rescue SystemCallError
          sleep 0.01
          :retry
        end
      end

      # At this point the connection has been set up but the thread may not yet
      # have returned, thus we'll need to wait a little longer for it to
      # complete.
      thread.join(2)

      @sock.should be_an_instance_of(Socket)
      addr.should be_an_instance_of(Addrinfo)
    end
  end
end
