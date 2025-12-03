# frozen_string_literal: true

module Views
  # View for a single level entity
  class Level
    def initialize(level)
      @level = level
    end

    def entity
      @level
    end

    def text
      @level&.level
    end
  end
end
