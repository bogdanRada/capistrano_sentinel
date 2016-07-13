module CapistranoSentinel
  # class that holds the options that are configurable for this gem
  module Logging
    module_function

    def logging_enabled?
      ENV["WEBSOCKET_LOGGING"].to_s == 'true'
    end

    def logger
      @logger ||= ::Logger.new(ENV["LOG_FILE"] || '/dev/null')
    end

    def error_filtered?(error)
      [SystemExit].find { |class_name| error.is_a?(class_name) }.present?
    end

    def log_error(error, options = {})
      message = format_error(error)
      log_output_error(error, options.fetch(:output, nil), message)
      log_to_file(message, options.merge(log_method: 'fatal'))
    end

    def log_output_error(error, output, message)
      return if message.blank? || error_filtered?(error)
      puts message if output.present?
    end

    def format_error(exception)
      message = "\n#{exception.class} (#{exception.respond_to?(:message) ? exception.message : exception.inspect}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << '  ' << exception.backtrace.join("\n  ") if exception.respond_to?(:backtrace)
      message
    end

    def log_to_file(message, options = {})
      return unless logging_enabled?
      worker_log = options.fetch(:job_id, '').present? ? find_worker_log(options[:job_id]) : logger
      print_to_log_file(worker_log, options.merge(message: message)) if worker_log.present?
    end

    def print_to_log_file(worker_log, options = {})
      worker_log.send(options.fetch(:log_method, 'debug'), "#{options.fetch(:message, '')}\n")
    end

    def find_worker_log(job_id)
      return if job_id.blank?
      FileUtils.mkdir_p(log_directory) unless File.directory?(log_directory)
      filename = File.join(log_directory, "worker_#{job_id}.log")
      setup_filename_logger(filename)
    end

    def setup_filename_logger(filename)
      worker_log = ::Logger.new(filename)
      worker_log.level = ::Logger::Severity::DEBUG
      setup_logger_formatter(worker_log)
      worker_log
    end

    def setup_logger_formatter(logger)
      logger.formatter = proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S')
        "[#{date_format}] #{severity}  (#{progname}): #{msg}\n"
      end
    end

    def execute_with_rescue(output = nil)
      yield if block_given?
    rescue Interrupt
      rescue_interrupt
    rescue => error
      rescue_error(error, output)
    end

    def rescue_error(error, output = nil)
      log_error(error, output: output)
      exit(1)
    end

    def show_warning(message)
      warn message
    end

  end
end
