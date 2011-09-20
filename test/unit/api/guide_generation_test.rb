require 'test_helper'

class GuideGenerationTest < ActiveSupport::TestCase
  def setup
    @updated_time = Time.now
    @guide = Guide.new(slug: 'test_slug', tags: 'tag, other')
    @guide.editions.first.attributes = {version_number: 1, title: 'Test guide', updated_at: @updated_time}
    @edition = @guide.editions.first
    @edition.parts.build(order: 1, title: 'Part 1 title', body: 'Body text', slug: 'part_one', updated_at: @updated_time)
    @edition.parts.build(order: 2, title: 'Part 2 title', body: 'Body text', slug: 'part_two', updated_at: @updated_time)
  end

  def generated
    Api::Generator.edition_to_hash(@guide.editions.first)
  end

  def test_api_hash_generation_has_slug
    assert_equal "test_slug", generated['slug']
  end

  def test_api_hash_generation_has_tags
    assert_equal "tag, other", generated['tags']
  end

  def test_api_hash_generation_has_edition_title
    assert_equal "Test guide", generated['title']
  end

  def test_api_hash_generation_has_parts
    assert_equal 2, generated['parts'].length
  end

  def test_api_hash_generation_has_part_slug
    assert_equal 'part_one', generated['parts'][0]['slug']
  end

  def test_api_hash_generation_has_part_title
    assert_equal 'Part 2 title', generated['parts'][1]['title']
  end

  def test_api_hash_generation_has_part_body
    assert_equal 'Body text', generated['parts'][1]['body']
  end
end