Pay.setup do |config|
  config.application_name = "Chapterwan"
  config.business_name = "Chapterwan"
  config.enabled_processors = [:stripe]
end

Rails.application.config.after_initialize do
  next if defined?(CHAPTERWAN_PAY_WEBHOOKS_CONFIGURED)

  Pay::Webhooks.configure do |events|
    events.subscribe "stripe.checkout.session.completed" do |event|
      session = event.data.object
      next unless session.payment_status == "paid"

      book_id = session.metadata["book_id"]
      user_id = session.metadata["user_id"]
      next if book_id.blank? || user_id.blank?

      book = Book.find_by(id: book_id)
      user = User.find_by(id: user_id)
      next if book.blank? || user.blank?

      book.grant_reader_access(user)
    end

    events.subscribe "stripe.checkout.session.async_payment_succeeded" do |event|
      session = event.data.object

      book_id = session.metadata["book_id"]
      user_id = session.metadata["user_id"]
      next if book_id.blank? || user_id.blank?

      book = Book.find_by(id: book_id)
      user = User.find_by(id: user_id)
      next if book.blank? || user.blank?

      book.grant_reader_access(user)
    end
  end

  CHAPTERWAN_PAY_WEBHOOKS_CONFIGURED = true
end
