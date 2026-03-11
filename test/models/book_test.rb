require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "slug is generated from title" do
    book = Book.create!(title: "Hello, World!")
    assert_equal "hello-world", book.slug
  end

  test "press a leafable" do
    leaf = books(:manual).press Page.new(body: "Important words"), title: "Introduction"

    assert leaf.page?
    assert_equal "Important words", leaf.page.body.content.to_s
    assert_equal "Introduction", leaf.title
  end

  test "paid published book requires stripe product" do
    book = books(:handbook)
    book.assign_attributes(pricing_type: :paid, price_cents: 1000, published: true, stripe_product_id: nil)

    assert_not book.valid?
    assert_includes book.errors[:published], "cannot be true for paid books without a Stripe product"
  end

  test "free published book remains valid" do
    book = books(:handbook)
    book.assign_attributes(pricing_type: :free, published: true)

    assert book.valid?
  end
end
