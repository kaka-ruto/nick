require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "slug is generated from title" do
    book = Book.create!(title: "Hello, World!")
    assert_equal "hello-world", book.slug
  end

  test "slug updates when title changes" do
    book = books(:manual)
    book.update!(title: "Renamed Manual")

    assert_equal "renamed-manual", book.slug
  end

  test "press a leafable" do
    leaf = books(:manual).press Page.new(body: "Important words"), title: "Introduction"

    assert leaf.page?
    assert_equal "Important words", leaf.page.body.content.to_s
    assert_equal "Introduction", leaf.title
  end

  test "paid published book requires stripe product" do
    book = books(:handbook)
    book.assign_attributes(pricing_type: :paid, price_cents: 1000, published: true, stripe_product_id: nil, seller_user: users(:david))

    assert_not book.valid?
    assert_includes book.errors[:published], "cannot be true for paid books without a Stripe product"
  end

  test "paid book requires seller user" do
    book = books(:handbook)
    book.assign_attributes(pricing_type: :paid, price_cents: 1000, seller_user: nil)

    assert_not book.valid?
    assert_includes book.errors[:seller_user], "must be present for paid books"
  end

  test "paid unpublished book is valid without seller Stripe setup" do
    seller = users(:david)
    seller.update!(sell_paid_books: false)

    book = books(:handbook)
    book.assign_attributes(pricing_type: :paid, price_cents: 1000, seller_user: seller, published: false)

    assert book.valid?
  end

  test "paid published book requires seller preference and stripe readiness" do
    seller = users(:david)
    seller.update!(sell_paid_books: false)

    book = books(:handbook)
    book.assign_attributes(pricing_type: :paid, price_cents: 1000, seller_user: seller, published: true, stripe_product_id: "prod_123")

    assert_not book.valid?
    assert_includes book.errors[:published], "cannot be true for paid books until seller enables paid book sales"

    seller.update!(sell_paid_books: true)
    seller.set_merchant_processor(:stripe, processor_id: "acct_not_ready", onboarding_complete: false)
    assert_not book.valid?
    assert_includes book.errors[:published], "cannot be true for paid books until seller completes Stripe Connect onboarding"

    seller.merchant_processor.update!(onboarding_complete: true)
    assert book.valid?
  end

  test "free published book remains valid" do
    book = books(:handbook)
    book.assign_attributes(pricing_type: :free, published: true)

    assert book.valid?
  end

  test "assign tags keeps maximum five" do
    book = books(:handbook)
    book.assign_tags!(%w[one two three four five six seven])

    assert_equal 5, book.tags.size
  end
end
