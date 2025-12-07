# frozen_string_literal: true

require_relative 'material'

module Views
  # View for a a list of material entities
  class MaterialsList

    attr_reader :song

    def initialize(materials)
      # @song = materials.song
      @materials = Array(materials).map do |vocab|
        vocab_obj = vocab.is_a?(Hash) ? OpenStruct.new(vocab) : vocab
        vocab_obj.is_a?(Material) ? vocab_obj : Material.new(vocab_obj)
      end
      # @materials = materials.map do |material|
      #   material.is_a?(Material) ? material : Material.new(material)
      # end
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
