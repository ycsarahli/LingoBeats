# frozen_string_literal: true

require_relative 'vocab'

module Views
  # View for a a list of material entities
  class MaterialsList
    attr_reader :song

    def initialize(materials)
      @materials = Array(materials).map do |vocab|
        vocab_obj = vocab.is_a?(Hash) ? OpenStruct.new(vocab) : vocab
        vocab_obj.is_a?(Vocab) ? vocab_obj : Vocab.new(vocab_obj)
      end
    end

    def each(&show)
      @materials.each do |material|
        show.call material
      end
    end

    def any?
      @materials.any?
    end
  end
end
