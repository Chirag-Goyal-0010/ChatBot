require "test_helper"

class WebsiteTest < ActiveSupport::TestCase
  test "should not save website without url" do
    website = Website.new
    assert_not website.save, "Saved the website without a url"
  end

  test "should not save website with invalid url" do
    website = Website.new(url: "invalid-url")
    assert_not website.save, "Saved the website with invalid url"
  end

  test "should save website with valid url" do
    website = Website.new(url: "https://example.com")
    assert website.save, "Could not save website with valid url"
  end

  test "should normalize url without protocol" do
    website = Website.new(url: "example.com")
    website.valid?
    assert_equal "https://example.com", website.url
  end

  test "should not change url with existing protocol" do
    website = Website.new(url: "https://example.com")
    website.valid?
    assert_equal "https://example.com", website.url
  end

  test "should accept valid status values" do
    website = Website.new(url: "https://example.com", status: "active")
    assert website.save, "Could not save website with valid status"
  end

  test "should not accept invalid status values" do
    website = Website.new(url: "https://example.com", status: "invalid")
    assert_not website.save, "Saved website with invalid status"
  end
end
