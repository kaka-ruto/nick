module Book::Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :sync_slug_with_title
  end

  def sync_slug_with_title
    self.slug = title.to_s.parameterize.presence || "-"
  end
end
