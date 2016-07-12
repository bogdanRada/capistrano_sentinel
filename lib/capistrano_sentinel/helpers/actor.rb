module CapistranoSentinel
  module AsyncActor
    class << self
      def included(base)
        base.extend(CapistranoSentinel::AsyncActor::ClassMethods)
      end

      def current
        Thread.current[:actor]
      end
    end

    module ClassMethods
      def new(*args)
        CapistranoSentinel::AsyncActor::Proxy.new(super(*args))
      end
    end

    class Proxy
      attr_reader :outbox

      def initialize(target)
        @target = target
        @mailbox = Queue.new
        @outbox = Queue.new
        @mutex = Mutex.new
        @async_proxy = CapistranoSentinel::AsyncActor::AsyncProxy.new(self)

        @thread = Thread.new do
          Thread.current[:actor] = self
          Thread.abort_on_exception = true
          process_inbox
        end
      end

      def await
        @thread.join
      end

      def future
        CapistranoSentinel::AsyncActor::Future.new(self)
      end

      def terminate
        Thread.kill(@thread)
      end

      def alive?
        @thread && @thread.alive?
      end

      def async
        @async_proxy
      end

      def method_missing(sym, *args, &block)
        process_message(sym, *args, &block)
      end

      def send_later(sym, *args, &block)
        @mailbox << [sym, args, block]
      end

      private

      def process_inbox
        while Thread.current.alive?
          sym, args, block = @mailbox.pop
          process_message sym, *args, &block
        end
      rescue Exception => e
        puts "[#{CapistranoSentinel::AsyncActor.current}] Exception! #{e} #{e.backtrace}"
        raise
      end

      def process_message(sym, *args, outbox: nil, &block)
        @mutex.synchronize do
          result = @target.public_send(sym, *args, &block)
          outbox.push(result) if outbox
        end
      end
    end

    class AsyncProxy
      def initialize(actor)
        @actor = actor
      end

      def method_missing(sym, *args, &block)
        @actor.send_later(sym, *args, &block)
      end
    end

    class Future
      def initialize(actor)
        @actor = actor
        @mailbox = Queue.new
      end

      def value
        if @mailbox.empty? && @last_value
          @last_value
        else
          @last_value = @mailbox.pop
        end
      end

      def method_missing(sym, *args, &block)
        @mailbox.clear
        args.push(outbox: @mailbox)
        @actor.send_later(sym, *args, &block)
        self
      end
    end
  end
end
