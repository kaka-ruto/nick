module HumanActions
  class SellerAttentionService
    HUMAN_REQUIRED_ERRORS = [
      "cannot be true for paid books until seller enables paid book sales",
      "cannot be true for paid books until seller completes Stripe Connect onboarding",
      "cannot be true for paid books without a Stripe product"
    ].freeze

    def self.flag_if_needed!(book:, errors:)
      new(book:, errors:).flag_if_needed!
    end

    def initialize(book:, errors:)
      @book = book
      @errors = Array(errors).map(&:to_s)
    end

    def flag_if_needed!
      return unless human_action_required?
      return if @book.seller_user.blank?

      @book.seller_user.update!(
        seller_attention_required: true,
        seller_attention_reason: @errors.first,
        seller_attention_book: @book
      )
    end

    private
      def human_action_required?
        @errors.any? { |message| HUMAN_REQUIRED_ERRORS.any? { |pattern| message.include?(pattern) } }
      end
  end
end
