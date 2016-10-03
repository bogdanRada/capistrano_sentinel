module CapistranoSentinel
  class Configuration

    SETTINGS = [
      :secure,
      :host,
      :port,
      :path,
      :auto_pong,
      :read_buffer_size,
      :reconnect,
      :retry_time,
      :wait_execution,
      :hook_stdin_and_stdout,
      :max_frame_size,
      :should_raise
    ]

    SETTINGS.each do |setting|
      attr_reader setting
      attr_accessor setting
    end

    def initialize
      @secure  = false
      @host    = '0.0.0.0'
      @port    = 1234
      @path    = '/ws'
      @auto_pong = true
      @read_buffer_size = 2048
      @reconnect = false
      @retry_time = 0
      @wait_execution = true
      @hook_stdin_and_stdout = true
      @max_frame_size = ::Websocket.max_frame_size
      @should_raise = ::Websocket.should_raise
    end


    def max_frame_size=(val)
      ::Websocket.max_frame_size = @max_frame_size = val
    end

    def should_raise=(val)
      ::Websocket.should_raise = @should_raise = val
    end


  end
end
