require "test_helper"

class WebsiteChunkTest < ActiveSupport::TestCase
  setup do
    @website = Website.create!(url: "https://example.com", status: "active")
  end

  test "should not save chunk without content" do
    chunk = WebsiteChunk.new(website: @website)
    assert_not chunk.save, "Saved the chunk without content"
  end

  test "should not save chunk without website" do
    chunk = WebsiteChunk.new(content: "Some content")
    assert_not chunk.save, "Saved the chunk without website"
  end

  test "should save chunk with valid attributes" do
    chunk = WebsiteChunk.new(
      website: @website,
      content: "Some content",
      section: "Test Section",
      position: 1
    )
    assert chunk.save, "Could not save chunk with valid attributes"
  end

  test "should belong to website" do
    chunk = WebsiteChunk.create!(
      website: @website,
      content: "Some content"
    )
    assert_equal @website, chunk.website
  end

  test "should be destroyed when website is destroyed" do
    chunk = WebsiteChunk.create!(
      website: @website,
      content: "Some content"
    )
    chunk_id = chunk.id
    @website.destroy
    assert_nil WebsiteChunk.find_by(id: chunk_id)
  end
end
