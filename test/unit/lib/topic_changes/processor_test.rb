require 'test_helper'

class TopicChanges::ProcessorTest < ActiveSupport::TestCase

  setup do
    # stub the edition republishing as we don't need it for most tests
    PublishedSlugRegisterer.any_instance.stubs(:run)
  end

  def build_stub_logger
    stub("Logger").tap {|logger|
      # don't set up expectations about info log messages to keep these tests
      # simpler
      #
      logger.stubs(:info)
    }
  end

  context 'replacing a topic on an edition' do
    should 'retag the additional_topic for an Edition' do
      edition = FactoryGirl.create(:answer_edition, additional_topics: ['tea/yorkshire', 'tea/tetley'], primary_topic: 'tea/pg-tips')
      operations = [
        {
          'slug' => edition.slug,
          'remove_topic' => 'tea/yorkshire',
          'add_topic' => 'tea/lancashire',
        },
      ]
      processor = TopicChanges::Processor.new(operations)

      processor.run
      edition.reload

      assert_equal ['tea/lancashire', 'tea/tetley'], edition.additional_topics

      # check that the primary_topic field is unchanged
      assert_equal 'tea/pg-tips', edition.primary_topic
    end

    should 'retag the primary_topic for an Edition' do
      edition = FactoryGirl.create(:answer_edition, primary_topic: 'tea/yorkshire', additional_topics: ['tea/twinings'])
      operations = [
        {
          'slug' => edition.slug,
          'remove_topic' => 'tea/yorkshire',
          'add_topic' => 'tea/lancashire',
        },
      ]
      processor = TopicChanges::Processor.new(operations)

      processor.run
      edition.reload

      assert_equal 'tea/lancashire', edition.primary_topic

      # check that the additional_topics field is unchanged
      assert_equal ['tea/twinings'], edition.additional_topics
    end
  end

  context 'removing a topic from an edition' do
    should 'remove an additional_topic from an Edition' do
      edition = FactoryGirl.create(:answer_edition, additional_topics: ['tea/yorkshire', 'tea/tetley'], primary_topic: 'tea/pg-tips')
      operations = [
        {
          'slug' => edition.slug,
          'remove_topic' => 'tea/yorkshire',
          'add_topic' => '',
        },
      ]
      processor = TopicChanges::Processor.new(operations)

      processor.run
      edition.reload

      assert_equal ['tea/tetley'], edition.additional_topics

      # check that the primary_topic field is unchanged
      assert_equal 'tea/pg-tips', edition.primary_topic
    end

    should 'remove a primary_topic from an Edition' do
      edition = FactoryGirl.create(:answer_edition, additional_topics: ['tea/yorkshire', 'tea/tetley'], primary_topic: 'tea/pg-tips')
      operations = [
        {
          'slug' => edition.slug,
          'remove_topic' => 'tea/pg-tips',
          'add_topic' => '',
        },
      ]
      processor = TopicChanges::Processor.new(operations)

      processor.run
      edition.reload

      assert_equal nil, edition.primary_topic

      # check that the primary_topic field is unchanged
      assert_equal ['tea/yorkshire', 'tea/tetley'], edition.additional_topics
    end
  end

  should 'skip rows with an empty slug' do
    operations = [
      {
        'slug' => '',
        'remove_topic' => 'tea/yorkshire',
        'add_topic' => 'tea/lancashire',
      },
    ]

    stub_logger = build_stub_logger
    stub_logger.expects(:warn).with(regexp_matches(/no slug/))

    processor = TopicChanges::Processor.new(operations, stub_logger)
    processor.run
  end

  should 'skip rows when the edition does not exist' do
    operations = [
      {
        'slug' => 'does-not-exist',
        'remove_topic' => 'tea/yorkshire',
        'add_topic' => 'tea/lancashire',
      },
    ]

    stub_logger = build_stub_logger
    stub_logger.expects(:warn).with(regexp_matches(/No editions found/))

    processor = TopicChanges::Processor.new(operations, stub_logger)
    processor.run
  end

  should 'retag all non-archived editions for a slug' do
    atts = {
      slug: 'success-for-tea-industry-is-in-the-bag',
      primary_topic: 'tea/yorkshire',
    }

    non_archived_editions = [
      FactoryGirl.create(:edition, atts.merge(state: 'draft')),
      FactoryGirl.create(:edition, atts.merge(state: 'in_review')),
      FactoryGirl.create(:edition, atts.merge(state: 'ready')),
      FactoryGirl.create(:edition, atts.merge(state: 'published')),
    ]
    archived_edition = FactoryGirl.create(:edition, atts.merge(state: 'archived'))

    operations = [
      {
        'slug' => atts[:slug],
        'remove_topic' => atts[:primary_topic],
        'add_topic' => 'tea/lancashire',
      },
    ]

    processor = TopicChanges::Processor.new(operations)
    processor.run

    non_archived_editions.each do |edition|
      edition.reload
      assert_equal 'tea/lancashire', edition.primary_topic
    end

    archived_edition.reload
    assert_equal 'tea/yorkshire', archived_edition.primary_topic
  end

  should 're-publish the edition' do
    edition = FactoryGirl.create(:edition, state: 'published', primary_topic: 'tea/yorkshire')
    operations = [
      {
        'slug' => edition.slug,
        'remove_topic' => edition.primary_topic,
        'add_topic' => 'tea/lancashire',
      },
    ]

    stub_logger = build_stub_logger
    mock_slug_registerer = stub("PublishedSlugRegisterer")
    PublishedSlugRegisterer.stubs(:new)
                           .with(stub_logger, [edition.slug])
                           .returns(mock_slug_registerer)
    mock_slug_registerer.expects(:run).returns(true)

    processor = TopicChanges::Processor.new(operations, stub_logger)
    processor.run
  end

end
