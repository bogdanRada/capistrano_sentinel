# frozen_string_literal: true
module CapistranoSentinel
  # class used to hook into the input stream
  class InputStream
    def self.hook(actor, stringio)
      $stdin = new($stdin, actor, stringio)
    end

    def self.unhook
      $stdin.finish if $stdin.is_a? CapistranoSentinel::InputStream
      $stdin = STDIN
    end

    attr_accessor :real, :actor, :stringio

    def initialize(real_stdin, actor, stringio)
      self.real = real_stdin
      self.actor = actor
      self.stringio = stringio
    end

    def gets(*_args)
      @stringio.rewind
      data = @stringio.read
      @actor.user_prompt_needed?(data)
    end

    def finish
    end

    def method_missing(name, *args, &block)
      @real.send(name, *args, &block) || super
    end

    def respond_to_missing?(method_name, include_private = nil)
      include_private = include_private.blank? ? true : include_private
      @real.public_methods.include?(method_name) || super(method_name, include_private)
    end
  end
end
