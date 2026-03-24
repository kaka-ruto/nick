class Uploads::RevisionDiff
  def self.call(previous_units:, next_units:)
    new(previous_units:, next_units:).call
  end

  def initialize(previous_units:, next_units:)
    @previous_units = Array(previous_units).map { |unit| unit.to_h.deep_symbolize_keys }
    @next_units = Array(next_units).map { |unit| unit.to_h.deep_symbolize_keys }
  end

  def call
    previous_by_id = @previous_units.index_by { |unit| unit.fetch(:external_id) }
    next_by_id = @next_units.index_by { |unit| unit.fetch(:external_id) }

    added = next_by_id.keys - previous_by_id.keys
    removed = previous_by_id.keys - next_by_id.keys
    common = previous_by_id.keys & next_by_id.keys

    changed = common.select { |external_id| previous_by_id.fetch(external_id)[:content_sha256] != next_by_id.fetch(external_id)[:content_sha256] }
    unchanged = common - changed

    previous_order = @previous_units.map { |unit| unit.fetch(:external_id) }
    next_order = @next_units.map { |unit| unit.fetch(:external_id) }

    {
      added: added,
      removed: removed,
      changed: changed,
      unchanged_count: unchanged.size,
      order_changed: (previous_order != next_order)
    }
  end
end
