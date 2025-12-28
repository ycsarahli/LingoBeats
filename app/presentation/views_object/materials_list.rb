# frozen_string_literal: true

require_relative 'vocab'

module Views
  # View for a a list of material entities
  class MaterialsList
    include Enumerable

    def initialize(materials)
      @materials = Array(materials).map do |vocab|
        vocab_obj = vocab.is_a?(Hash) ? OpenStruct.new(vocab) : vocab
        vocab_obj.is_a?(Vocab) ? vocab_obj : Vocab.new(vocab_obj)
      end
    end

    def each(&)
      return enum_for(:each) unless block_given?

      @materials.each(&)
    end

    def any?
      @materials.any?
    end

    def length
      @materials.length
    end

    def to_a
      @materials.dup
    end
  end
end
