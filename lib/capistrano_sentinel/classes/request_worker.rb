require_relative './websocket_client'
require_relative '../helpers/application_helper'
module CapistranoSentinel
  # class that handles the rake task and waits for approval from the celluloid worker
  class RequestWorker
    include CapistranoSentinel::ApplicationHelper

    attr_reader :client, :job_id, :action, :task,
    :task_approved, :stdin_result, :executor


    def work(options = {})
      @options = options.stringify_keys
      default_settings
      socket_client.actor = self
      publish_to_worker(task_data) if options['subscribed'].present?
    end

    def wait_execution(name = task_name, time = 0.1)
      #    info "Before waiting #{name}"
      wait_for(name, time)
      #  info "After waiting #{name}"
    end

    def wait_for(_name, time)
      # info "waiting for #{time} seconds on #{name}"
      sleep time
      # info "done waiting on #{name} "
    end

    def socket_client
      @socket_client = CapistranoSentinel::RequestHooks.socket_client
    end

    def default_settings
      @stdin_result = nil
      @job_id = @options['job_id']
      @task_approved = false
      @action = @options['action'].present? ? @options['action'] : 'invoke'
      @task = @options['task']
    end

    def task_name
      @task.respond_to?(:name) ? @task.name : @task
    end

    def task_data
      {
        action: @action,
        task: task_name,
        job_id: @job_id
      }
    end

    def publish_to_worker(data)
      log_to_file("RakeWorker #{@job_id} tries to publish #{data.inspect}")
      socket_client.publish("#{CapistranoSentinel::RequestHooks::PUBLISHER_PREFIX}#{@job_id}", data)
    end

    def on_error(message)
      log_to_file("RakeWorker #{@job_id} websocket connection error: #{message.inspect}")
    end

    def on_message(message)
      return if message.blank? || !message.is_a?(Hash)
      message = message.stringify_keys
      log_to_file("RakeWorker #{@job_id} received after on message: #{message.inspect}")
      if message['client_action'] == 'successful_subscription'
        publish_subscription_successfull(message)
      elsif message_is_about_a_task?(message)
        task_approval(message)
      elsif msg_for_stdin?(message)
        stdin_approval(message)
      else
        show_warning "unknown message: #{message.inspect}"
      end
    end


    def publish_subscription_successfull(message)
      return unless message['client_action'] == 'successful_subscription'
      log_to_file("Rake worker #{@job_id} received after publish_subscription_successfull: #{message}")
      @successfull_subscription = true
      publish_to_worker(task_data)
    end

    def wait_for_stdin_input
      wait_execution until @stdin_result.present?
      output = @stdin_result.clone
      @stdin_result = nil
      output
    end

    def stdin_approval(message)
      return unless msg_for_stdin?(message)
      if @job_id == message['job_id']
        @stdin_result = message.fetch('result', '')
      else
        show_warning "unknown stdin_approval #{message.inspect}"
      end
    end

    def task_approval(message)
      return if !message_is_about_a_task?(message)
      log_to_file("RakeWorker #{@job_id} #{task_name} task_approval : #{message.inspect}")
      if @job_id.to_s == message['job_id'].to_s && message['task'].to_s == task_name.to_s && message['approved'] == 'yes'
        @task_approved = true
      else
        show_warning "#{self.inspect} got unknown task_approval #{message} #{task_data}"
      end
    end

    def on_close(message)
      log_to_file("RakeWorker #{@job_id} websocket connection closed: #{message.inspect}")
    end

    def user_prompt_needed?(data)
      question, default = get_question_details(data)
      log_to_file("RakeWorker #{@job_id} tries to determine question #{data.inspect} #{question.inspect} #{default.inspect}")
      return if question.blank? || @action != 'invoke'
      publish_to_worker(action: 'stdout',
      question: question,
      default: default.present? ? default.delete('()') : '',
      job_id: @job_id)
      wait_for_stdin_input
    end
  end
end
