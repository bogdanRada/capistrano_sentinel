# frozen_string_literal: true
require_relative './input_stream'
require_relative './output_stream'
require_relative './request_worker'
module CapistranoSentinel
  # class used to handle the rake worker and sets all the hooks before and after running the worker
  class RequestHooks
    class << self
      def job_id
        @@job_id ||= ENV.fetch(CapistranoSentinel::RequestHooks::ENV_KEY_JOB_ID, nil) || SecureRandom.uuid
      end

      def socket_client
        @@socket_client ||= CapistranoSentinel::WebsocketClient.new(
          actor:            nil,
          channel:          "#{CapistranoSentinel::RequestHooks::SUBSCRIPTION_PREFIX}#{job_id}",
          auto_pong:        ENV.fetch('WS_AUTO_PONG', nil),
          read_buffer_size: ENV.fetch('WS_READ_BUFFER_SIZE', nil),
          reconnect:        ENV.fetch('WS_RECONNECT', nil),
          retry_time:       ENV.fetch('WS_RETRY_TIME', nil),
          secure:           ENV.fetch('WS_SECURE', nil),
          host:             ENV.fetch('WS_HOST', nil),
          port:             ENV.fetch('WS_PORT', nil),
          path:             ENV.fetch('WS_PATH', nil)
        )
      end
    end

    ENV_KEY_JOB_ID = 'multi_cap_job_id'
    SUBSCRIPTION_PREFIX = 'rake_worker_'
    PUBLISHER_PREFIX = 'celluloid_worker_'

    attr_accessor :job_id, :task

    def initialize(task = nil)
      @job_id = CapistranoSentinel::RequestHooks.job_id
      @task = task.respond_to?(:fully_qualified_name) ? task.fully_qualified_name : task
    end

    def subscribed_already?
      defined?(@@socket_client)
    end

    def automatic_hooks(&block)
      if job_id.present? && @task.present?
        actor_start_working(action: 'invoke', subscribed: subscribed_already?)
        actor_handle_wait
        actor_execute_block(&block)
      elsif block_given?
        yield
      end
    end

    def actor_handle_wait
      if CapistranoSentinel.config.wait_execution
        actor.wait_execution_of_task until actor.task_approved
      elsif !subscribed_already?
        actor.wait_execution_of_task until actor.successfull_subscription
      end
    end

    def print_question?(question)
      if CapistranoSentinel.config.hook_stdin_and_stdout && job_id.present?
        actor.user_prompt_needed?(question)
      elsif block_given?
        yield
      end
    end

    def show_bundler_progress
      actor_start_working(action: 'bundle_install') if @task.present? && @task.to_s.size > 2
      yield if block_given?
    end

  private

    def actor
      @actor ||= CapistranoSentinel::RequestWorker.new
      @actor
    end

    def output_stream
      CapistranoSentinel::OutputStream
    end

    def input_stream
      CapistranoSentinel::InputStream
    end

    def before_hooks
      stringio = StringIO.new
      output = output_stream.hook(stringio)
      input = input_stream.hook(actor, stringio)
      [input, output]
    end

    def after_hooks
      input_stream.unhook
      output_stream.unhook
    end

    def actor_execute_block
      before_hooks if CapistranoSentinel.config.hook_stdin_and_stdout
      yield if block_given?
      after_hooks if CapistranoSentinel.config.hook_stdin_and_stdout
    end

    def actor_start_working(additionals = {})
      additionals = additionals.present? ? additionals : {}
      data = { job_id: job_id, task: @task }.merge(additionals)
      data = data.stringify_keys
      actor.work(data)
    end
  end
end
