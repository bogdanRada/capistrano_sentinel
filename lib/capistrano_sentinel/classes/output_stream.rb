module CapistranoSentinel
  # class used to hook into the output stream
  class OutputStream
    def self.hook(stringio)
      $stdout = new($stdout, stringio)
    end

    def self.unhook
      $stdout.finish if $stdout.is_a? CapistranoSentinel::OutputStream
      $stdout = STDOUT
    end

    attr_accessor :real, :stringio

    def initialize(real_stdout, stringio)
      self.real = real_stdout
      self.stringio = stringio
    end

    def write(*args)
      @stringio.write(*args)
      @real.write(*args)
      @real.flush
    end

    def finish
    end

    def method_missing(name, *args, &block)
      @real.send name, *args, &block
    end
  end
end
