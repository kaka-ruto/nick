class Uploads::ProjectUnits
  def self.call(book:, units:)
    new(book:, units:).call
  end

  def initialize(book:, units:)
    @book = book
    @units = Array(units).map { |unit| unit.to_h.deep_symbolize_keys }
  end

  def call
    seen_external_ids = []

    @units.each_with_index do |unit, index|
      external_id = unit.fetch(:external_id)
      seen_external_ids << external_id

      mapping = @book.book_units.find_by(external_id: external_id)
      if mapping&.content_sha256 == unit[:content_sha256]
        mapping.update!(position: index)
        next
      end

      leaf = upsert_leaf_for(mapping:, unit:)
      attrs = { leaf_id: leaf.id, position: index, content_sha256: unit.fetch(:content_sha256) }
      mapping ? mapping.update!(attrs) : @book.book_units.create!(attrs.merge(external_id: external_id))
    end

    @book.book_units.where.not(external_id: seen_external_ids).find_each do |mapping|
      mapping.leaf.trashed!
      mapping.destroy!
    end
  end

  private
    def upsert_leaf_for(mapping:, unit:)
      if mapping && compatible_leaf?(mapping.leaf, unit)
        mapping.leaf.tap do |existing_leaf|
          existing_leaf.edit(leaf_params: { title: unit.fetch(:title) }, leafable_params: leafable_params_for(unit))
        end
      else
        mapping&.leaf&.trashed!
        @book.press(new_leafable_for(unit), title: unit.fetch(:title))
      end
    end

    def compatible_leaf?(leaf, unit)
      expected_type = unit[:kind] == "section" ? "Section" : "Page"
      leaf.leafable_type == expected_type
    end

    def new_leafable_for(unit)
      if unit[:kind] == "section"
        Section.new(body: unit[:body], theme: unit[:theme])
      else
        Page.new(body: unit[:body])
      end
    end

    def leafable_params_for(unit)
      if unit[:kind] == "section"
        { body: unit[:body], theme: unit[:theme] }
      else
        { body: unit[:body] }
      end
    end
end
