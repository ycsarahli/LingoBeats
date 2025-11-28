# frozen_string_literal: true

require_relative 'material'

module Views
  # View for a a list of material entities
  class MaterialsList
    def initialize(materials)
      @materials = materials.map do |material|
        material.is_a?(Material) ? material : Material.new(material)
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
