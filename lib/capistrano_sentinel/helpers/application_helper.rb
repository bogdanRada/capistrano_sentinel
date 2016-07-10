require_relative './logging'
module CapistranoSentinel
  # class that holds the options that are configurable for this gem
  module ApplicationHelper
    include CapistranoSentinel::Logging
    module_function

    # Method that is used to parse a string as JSON , if it fails will return nil
    # @see JSON#parse
    # @param [string] res The string that will be parsed as JSON
    # @return [Hash, nil] Returns Hash object if the json parse succeeds or nil otherwise
    def parse_json(res)
      return if res.blank?
      JSON.parse(res)
    rescue JSON::ParserError
      nil
    end

    def show_warning(message)
      warn message
    end


    def msg_for_stdin?(message)
      message['action'] == 'stdin'
    end

    def message_is_for_stdout?(message)
      message.present? && message.is_a?(Hash) && message['action'].present? && message['job_id'].present? && message['action'] == 'stdout'
    end

    def message_is_about_a_task?(message)
      message.present? && message.is_a?(Hash) && message['action'].present? && message['job_id'].present? && message['task'].present? && message['action'] == 'invoke'
    end

    def message_from_bundler?(message)
      message.present? && message.is_a?(Hash) && message['action'].present? && message['job_id'].present? && message['task'].present? && message['action'] == 'bundle_install'
    end

    def get_question_details(data)
      matches = /(.*)\?*\s*\:*\s*(\([^)]*\))*/m.match(data).captures
      [matches[0], matches[1]]
    end


  end
end
