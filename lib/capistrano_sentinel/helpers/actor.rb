require_relative './application_helper'
module CapistranoSentinel
  module AsyncActor
    include CapistranoSentinel::ApplicationHelper

    Context = Struct.new(:method, :args, :block)

    Async = Struct.new(:instance, :mailbox) do
      extend Forwardable
      def_delegator :instance, :respond_to?

      private :instance
      private :mailbox

      def initialize(instance, mailbox)
        super(instance, mailbox)
        run!
      end

      def method_missing(method, *args, &block)
        mailbox << CapistranoSentinel::AsyncActor::Context.new(method, args, block)
        nil
      end
    end

      private

      def run!
        Thread.new do
          loop do
            break if mailbox.empty?
            begin
              mailbox.synchronize do
                ctx = mailbox.pop
                instance.public_send(ctx.method, *ctx.args, &ctx.block)
              end
            rescue => e
              log_to_file("crashed with #{e.inspect} #{e.backtrace}")
            end
          end
        end
      end

      def async_queue
        @async_queue ||= Queue.new.extend(MonitorMixin)
      end

      def async
        @async ||= CapistranoSentinel::AsyncActor::Async.new(self, async_queue)
      end
    end
  end
