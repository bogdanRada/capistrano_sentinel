require_relative './input_stream'
require_relative './output_stream'
require_relative './request_worker'
module CapistranoSentinel
  # class used to handle the rake worker and sets all the hooks before and after running the worker
  class RequestHooks

    def self.job_id
      @@job_id ||= ENV.fetch(CapistranoSentinel::RequestHooks::ENV_KEY_JOB_ID, nil) || SecureRandom.uuid
    end

    def self.socket_client
      @@socket_client ||= CapistranoSentinel::WebsocketClient.new(actor: nil, enable_debug: ENV.fetch('debug_websocket', false), channel: "#{CapistranoSentinel::RequestHooks::SUBSCRIPTION_PREFIX}#{job_id}", log_file_path: ENV.fetch('websocket_log_file_path', nil))
    end

    ENV_KEY_JOB_ID = 'multi_cap_job_id'
    SUBSCRIPTION_PREFIX ="rake_worker_"
    PUBLISHER_PREFIX ="celluloid_worker_"

    attr_accessor :job_id, :task

    def initialize(task = nil)
      @job_id  = CapistranoSentinel::RequestHooks.job_id
      @task = task.respond_to?(:fully_qualified_name) ? task.fully_qualified_name : task
    end

    def automatic_hooks(&block)
      if job_id.present? && @task.present?
        subscribed_already = defined?(@@socket_client)
        actor_start_working(action: 'invoke', subscribed: subscribed_already)
        if CapistranoSentinel.config.wait_execution
          actor.wait_execution until actor.task_approved
        end
        actor_execute_block(&block)
      else
        block.call
      end
    end

    def print_question?(question)
      if CapistranoSentinel.config.hook_stdin_and_stdout && job_id.present?
        actor.user_prompt_needed?(question)
      else
        yield if block_given?
      end
    end


    def show_bundler_progress
      actor_start_working({action: "bundle_install"}) if @task.present? && @task.to_s.size > 2
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

    def actor_execute_block(&block)
      before_hooks if CapistranoSentinel.config.hook_stdin_and_stdout
      block.call
      after_hooks if CapistranoSentinel.config.hook_stdin_and_stdout
    end

    def actor_start_working(additionals = {})
      additionals = additionals.present? ? additionals : {}
      data = {job_id: job_id, task: @task }.merge(additionals)
      data = data.stringify_keys
      actor.work(data)
    end


  end
end
