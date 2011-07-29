require 'test_helper'

class GuideClientTest < ActiveSupport::TestCase
  def setup
    @guide_client = Api::Client::Guide.from_hash('slug' => 'test_slug', 'tags' => 'tag, other', 'title' => 'Test guide', 'parts' => [
      {'number' => 1, 'title' => 'Part 1 title', 'body' => 'Body text', 'slug' => 'part_one'},
      {'number' => 1, 'title' => 'Part 2 title', 'body' => 'Body text', 'slug' => 'part_two'}
    ])
  end

  def test_api_client_has_slug
    assert_equal "test_slug", @guide_client.slug
  end

  def test_api_client_has_tags
    assert_equal "tag, other", @guide_client.tags
  end

  def test_api_client_has_edition_title
    assert_equal "Test guide", @guide_client.title
  end

  def test_api_client_has_parts
    assert_equal 2, @guide_client.parts.length
  end

  def test_api_client_has_part_slug
    assert_equal 'part_one', @guide_client.parts[0].slug
  end

  def test_api_client_has_part_number
    assert_equal 1, @guide_client.parts[0].number
  end

  def test_api_client_has_part_title
    assert_equal 'Part 2 title', @guide_client.parts[1].title
  end

  def test_api_client_has_part_body
    assert_equal 'Body text', @guide_client.parts[1].body
  end

  def test_api_client_can_find_part_from_slug
    assert_equal @guide_client.parts[1], @guide_client.find_part('part_two')
  end

  def test_api_client_can_retrieve_next_part
    assert_equal @guide_client.parts[1], @guide_client.part_after(@guide_client.parts[0])
  end

  def test_api_client_returns_nil_when_asked_to_retrieve_part_after_last
    assert_nil @guide_client.part_after(@guide_client.parts[1])
  end

  def test_api_client_can_reports_that_theres_a_next_part
    assert @guide_client.has_next_part?(@guide_client.parts[0])
  end

  def test_api_client_can_reports_that_theres_no_next_part
    assert !@guide_client.has_next_part?(@guide_client.parts[1])
  end

  def test_api_client_can_retrieve_previous_part
    assert_equal @guide_client.parts[0], @guide_client.part_before(@guide_client.parts[1])
  end

  def test_api_client_returns_nil_when_asked_to_retrieve_part_before_first
    assert_nil @guide_client.part_before(@guide_client.parts[0])
  end

  def test_api_client_can_reports_that_theres_a_previous_part
    assert @guide_client.has_previous_part?(@guide_client.parts[1])
  end

  def test_api_client_can_reports_that_theres_no_previous_part
    assert !@guide_client.has_previous_part?(@guide_client.parts[0])
  end
end