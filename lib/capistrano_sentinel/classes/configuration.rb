module CapistranoSentinel
  class Configuration
    SETTINGS = [:host, :port, :path, :secure, :auto_pong, :read_buffer_size,:reconnect, :retry_time, :wait_execution]

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
    end

    def update(settings_hash)
      settings_hash.each do |setting, value|
        unless SETTINGS.include? setting.to_sym
          raise ArgumentError, "invalid setting: #{setting}"
        end

        self.public_send "#{setting}=", value
      end
    end
  end
end
