require_relative './websocket/errors'
require_relative '../helpers/application_helper'
module CapistranoSentinel
  class WebsocketClient
    include CapistranoSentinel::ApplicationHelper

    attr_reader :socket, :read_thread,  :protocol_version, :actor, :read_buffer_size, :reconnect, :retry_time
    attr_accessor :auto_pong, :on_ping, :on_error, :on_message, :actor, :read_buffer_size, :reconnect, :retry_time

    ##
    # +host+:: Host of request. Required if no :url param was provided.
    # +path+:: Path of request. Should start with '/'. Default: '/'
    # +query+:: Query for request. Should be in format "aaa=bbb&ccc=ddd"
    # +secure+:: Defines protocol to use. If true then wss://, otherwise ws://. This option will not change default port - it should be handled by programmer.
    # +port+:: Port of request. Default: nil
    # +opts+:: Additional options:
    #   :reconnect - if true, it will try to reconnect
    #   :retry_time - how often should retries happen when reconnecting [default = 1s]
    # Alternatively it can be called with a single hash where key names as symbols are the same as param names
    def initialize(opts)

      # Initializing with a single hash
      @options = opts.symbolize_keys

      @auto_pong   = @options.fetch(:auto_pong, nil) || CapistranoSentinel.config.auto_pong
      @read_buffer_size = @options.fetch(:read_buffer_size, nil) ||  CapistranoSentinel.config.read_buffer_size
      @reconnect = @options.fetch(:reconnect, nil) ||  CapistranoSentinel.config.reconnect
      @retry_time = @options.fetch(:retry_time, nil) ||  CapistranoSentinel.config.retry_time


      @secure  = @options.fetch(:secure, nil) || CapistranoSentinel.config.secure

      @host    = @options.fetch(:host, nil) || CapistranoSentinel.config.host
      @port    = @secure ? 443 : (@options.fetch(:port, nil) ||  CapistranoSentinel.config.port)
      @path    = @options.fetch(:path, nil) ||  CapistranoSentinel.config.path
      @query   = @options.fetch(:query, nil)

      @actor ||=  @options.fetch(:actor, nil)
      @channel ||= @options.fetch(:channel, nil)


      @closed      = false
      @opened      = false

      @on_open    = lambda {
        log_to_file("native websocket client  websocket connection opened")
        subscribe(@channel) if @channel.present?
      }

      @on_close   = lambda { |message|
        log_to_file("#{@actor.class} client received on_close  #{message.inspect}")
        if @actor.present? && @actor.respond_to?(:on_close)
          if @actor.respond_to?(:async)
            @actor.async.on_close(message)
          else
            @actor.on_close(message)
          end
        end
      }

      @on_ping    = lambda { |message|
        log_to_file("#{@actor.class} client received PING  #{message.inspect}")
        if @actor.present? && @actor.respond_to?(:on_ping)
          if @actor.respond_to?(:async)
            @actor.async.on_ping(message)
          else
            @actor.on_ping(message)
          end
        end
      }

      @on_error   = lambda { |error|
        log_to_file("#{@actor.class} received ERROR  #{error.inspect} #{error.backtrace}")
        if @actor.present? && @actor.respond_to?(:on_error)
          if @actor.respond_to?(:async)
            @actor.async.on_error(error)
          else
            @actor.on_error(error)
          end
        end
      }

      @on_message = lambda { |message|
        message = parse_json(message)
        log_to_file("#{@actor.class} websocket client received JSON  #{message}")
        if @actor.present? && @actor.respond_to?(:async)
          @actor.async.on_message(message)
        else
          @actor.on_message(message)
        end
      }
      connect
    end

    def is_windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    end

    # subscribes to a channel . need to be used inside the connect block passed to the actor
    #
    # @param [string] channel
    #
    # @return [void]
    #
    # @api public
    def subscribe(channel, data = {})
      log_to_file("#{self.class} tries to subscribe to channel  #{channel}")
      send_action('subscribe', channel, data)
    end

    # publishes to a channel some data (can be anything)
    #
    # @param [string] channel
    # @param [#to_s] data
    #
    # @return [void]
    #
    # @api public
    def publish(channel, data)
      send_action('publish', channel, data)
    end

    # unsubscribes current client from a channel
    #
    # @param [string] channel
    #
    # @return [void]
    #
    # @api public
    def unsubscribe(channel)
      send_action('unsubscribe', channel)
    end

    # unsubscribes all clients subscribed to a channel
    #
    # @param [string] channel
    #
    # @return [void]
    #
    # @api public
    def unsubscribe_clients(channel)
      send_action('unsubscribe_clients', channel)
    end

    # unsubscribes all clients from all channels
    #
    # @return [void]
    #
    # @api public
    def unsubscribe_all
      send_action('unsubscribe_all')
    end


    protected

    def send_action(action, channel = nil, data = {})
      data = data.is_a?(Hash) ? data : {}
      publishing_data = { 'client_action' => action, 'channel' => channel, 'data' => data }.reject { |_key, value| value.blank? }
      chat(publishing_data)
    end

    # method used to send messages to the webserver
    # checks too see if the message is a hash and if it is it will transform it to JSON and send it to the webser
    # otherwise will construct a JSON object that will have the key action with the value 'message" and the key message witth the parameter's value
    #
    # @param [Hash] message
    #
    # @return [void]
    #
    # @api private
    def chat(message)
      final_message = nil
      if message.is_a?(Hash)
        final_message = message.to_json
      else
        final_message = JSON.dump(action: 'message', message: message)
      end
      log_to_file("#{self.class} sends JSON #{final_message}")
      send_data(final_message)
    end

    ##
    #Send the data given by the data param
    #if running on a posix system this uses Ruby's fork method to send
    #if on windows fork won't be attempted.
    #+data+:: the data to send
    #+type+:: :text or :binary, defaults to :text
    def send_data(data, type = :text)
      pid = Thread.new do
        log_to_file("#{@actor.class} calls send: #{data}")
        do_send(data, type)
      end
    end

    def connect
      tcp_socket = ::TCPSocket.new(@host, @port)
      tcp_socket.setsockopt(::Socket::SOL_SOCKET, ::Socket::SO_KEEPALIVE, true)
      tcp_socket.setsockopt(::Socket::SOL_TCP, ::Socket::TCP_KEEPIDLE, 50)
      tcp_socket.setsockopt(::Socket::SOL_TCP, ::Socket::TCP_KEEPINTVL, 50)
      tcp_socket.setsockopt(::Socket::SOL_TCP, ::Socket::TCP_KEEPCNT, 10)

      if @secure
        @socket = ::OpenSSL::SSL::SSLSocket.new(tcp_socket)
        @socket.connect
      else
        @socket = tcp_socket
      end
      perform_handshake
    end

    def reconnect
      @closed = false
      @opened = false

      until @opened
        begin
          connect
        rescue ::Errno::ECONNREFUSED => e
          log_to_file("#{self.class} got ECONNREFUSED #{e.inspect} ")
          sleep @retry_time
        rescue => e
          fire_on_error e
        end
      end
    end



    def perform_handshake
      handshake = ::WebSocket::Handshake::Client.new({
        :host   => @host,
        :port   => @port,
        :secure => @secure,
        :path   => @path,
        :query  => @query
        })

        @socket.write handshake.to_s
        buf = ''

        loop do
          begin
            if handshake.finished?
              @protocol_version = handshake.version
              @active = true
              @opened = true
              log_to_file("#{self.class} got handshake finished ")
              init_messaging
              fire_on_open
              break
            else
              # do non blocking reads on headers - 1 byte at a time
              buf.concat(@socket.read_nonblock(1))
              # \r\n\r\n i.e. a blank line, separates headers from body
              if idx = buf.index(/\r\n\r\n/m)
                handshake << buf # parse headers

                if handshake.finished? && !handshake.valid?
                  fire_on_error(CapistranoSentinel::ConnectError.new('Server responded with an invalid handshake'))
                  fire_on_close #close if handshake is not valid
                  break
                end
              end
            end
          rescue ::IO::WaitReadable => e
            #log_to_file("#{self.class} got WaitReadable #{e.inspect}")
          rescue ::IO::WaitWritable => e
            #log_to_file("#{self.class} got WaitWritable #{e.inspect}")
            # ignored
          end
        end
      end

      # Use one thread to perform blocking read on the socket
      def init_messaging
        @read_thread = Thread.new { read_loop }
      end

      def read_loop
        frame = ::WebSocket::Frame::Incoming::Client.new(:version => @protocol_version)
        loop do
          begin
            frame << @socket.readpartial(@read_buffer_size)
            while message = frame.next
              #"text", "binary", "ping", "pong" and "close" (according to websocket/base.rb)
              determine_message_type(message)
            end
            fire_on_error CapistranoSentinel::WsProtocolError.new(frame.error) if frame.error?
          rescue => e
            log_to_file("#{self.class} crashed with #{e.inspect} #{e.backtrace}")
            fire_on_error(e)
            if @socket.closed? || @socket.eof?
              @read_thread = nil
              fire_on_close
              break
            end
          end
        end
      end

      def determine_message_type(message)
        log_to_file("#{self.class} tries to dispatch message #{message.inspect}")
        case message.type
        when :binary, :text
          fire_on_message(message.data)
        when :ping
          send_data(message.data, :pong) if @auto_pong
          fire_on_ping(message)
        when :pong
          fire_on_error(CapistranoSentinel::WsProtocolError.new('Invalid type pong received'))
        when :close
          fire_on_close(message)
        else
          fire_on_error(CapistranoSentinel::BadMessageTypeError.new("An unknown message type was received #{message.inspect}"))
        end
      end

      def do_send(data, type=:text)
        frame = ::WebSocket::Frame::Outgoing::Client.new(:version => @protocol_version, :data => data, :type => type)
        begin
          @socket.write_nonblock frame
          @socket.flush
        rescue ::Errno::EPIPE => ce
          fire_on_error(ce)
          fire_on_close
        rescue => e
          fire_on_error(e)
        end
      end

      def fire_on_ping(message)
        log_to_file("#{self.class} tries to ping #{message.inspect}")
        @on_ping.call(message) if @on_ping
      end

      def fire_on_message(message)
        log_to_file("#{self.class} tries to fire_on_message #{message.inspect}")
        @on_message.call(message) if @on_message
      end

      def fire_on_open
        log_to_file("#{self.class} tries to on_open ")
        @on_open.call() if @on_open
      end

      def fire_on_error(error)
        log_to_file("#{self.class} tries to on_error with #{error.inspect} ")
        @on_error.call(error) if @on_error
      end

      def fire_on_close(message = nil)
        log_to_file("#{self.class} tries to fire_on_close with #{message.inspect} ")
        @active = false
        @closed = true
        @on_close.call(message) if @on_close
        @socket.close unless @socket.closed?

        reconnect if @reconnect
      end

    end # class
  end # module
