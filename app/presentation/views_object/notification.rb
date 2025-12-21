# frozen_string_literal: true

module Views
  # View model for toast-like notifications
  class Notification
    attr_reader :message, :status

    def initialize(message:, status: :info)
      @message = message.to_s
      @status = status.to_sym
    end

    def success?
      status == :success
    end

    def error?
      status == :error
    end

    def css_modifier
      return 'success' if success?
      return 'error' if error?

      'neutral'
    end
  end
end
