require 'test_helper'
require 'whole_edition_translator'

class WholeEditionTranslatorTest < ActiveSupport::TestCase
  setup do
    @author = FactoryGirl.create(:user)
    @editor = FactoryGirl.create(:user)
  end

  def multi_edition_answer
    a = Answer.new(section: 'work', department: 'MOJ', slug: "get-a-criminal-records-bureau-check", panopticon_id: '123')
    edition = a.editions.build(
      assigned_to: @author,
      version_number: 1, title: 'Get a CRB check', 
      body: "##Your employer will give you a paper application form, or they might ask you to get one by calling"
    )
    edition.actions.build(requester: @author, comment: 'Hello!', request_type: 'create', state: 'draft')
    second_edition = a.editions.build(
      assigned_to: @editor,
      version_number: 2,
      title: 'Blah',
      body: "##Your employer will give you a paper application form, or they might ask you to get one by calling"
    )
    second_edition.actions.build(requester: @author, comment: 'Hello!', request_type: 'publish', state: 'draft')
    a.save!
    a
  end
  
  def sample_guide
    g = Guide.new(section: 'work', department: 'MOJ', slug: "get-a-criminal-records-bureau-check", panopticon_id: '123')
    edition = g.editions.build(
      assigned_to: @author,
      version_number: 1, title: 'Get a CRB check', 
    )
    edition.parts.build(
      title: "my TITLE",
      slug: 'my-title',
      body: 'This is part 1',
      order: 1
    )
    edition.parts.build(
      title: "my OTHER TITLE",
      slug: 'my-other-title',
      body: 'This is part 2',
      order: 2
    )
    g.save!
    g
  end
  
  def sample_transaction
    t = Transaction.new(section: 'work', department: 'MOJ', slug: "get-a-criminal-records-bureau-check", panopticon_id: '123')
    edition = t.editions.build(
      assigned_to: @author,
      version_number: 1, title: 'Get a CRB check', 
      introduction: 'Some form of intro',
      will_continue_on: 'a website',
      link: 'http://a.web.site/',
      more_information: 'This is not real',
      alternate_method: 'Blah blah'
    )
    edition.actions.build(requester: @author, comment: 'Hello!', request_type: 'create', state: 'draft')
    t.save!
    t
  end

  test "it builds a whole edition from an answer" do
    answer = multi_edition_answer
    translator = WholeEditionTranslator.new(answer, answer.editions.last)
    new_edition = translator.run

    assert new_edition.valid?
    assert_equal answer.panopticon_id, new_edition.panopticon_id
    assert_equal answer.editions.last.body, new_edition.body
    assert_equal answer.editions.last.version_number, new_edition.version_number
    assert_equal answer.editions.last.title, new_edition.title
    assert_equal answer.editions.last.actions, new_edition.actions
    assert_equal @editor, new_edition.assigned_to
  end

  test "it captures a guide's parts" do
    guide = sample_guide
    translator = WholeEditionTranslator.new(guide, guide.editions.last)
    new_edition = translator.run

    assert new_edition.valid?
    assert_equal guide.editions.last.parts.last.title, new_edition.parts.last.title
    assert_equal guide.editions.last.parts.last.body, new_edition.parts.last.body
    assert_equal guide.editions.last.parts.last.slug, new_edition.parts.last.slug
  end

  test "it captures the introduction for a transaction" do
    t = sample_transaction
    translator = WholeEditionTranslator.new(t, t.editions.last)
    new_edition = translator.run
    assert new_edition.introduction.present?
    assert_equal t.editions.last.introduction, new_edition.introduction
  end

  test "it captures the expectations for a transaction" do
    t = sample_transaction
    t.editions.last.expectation_ids = [1, 2, 3]
    translator = WholeEditionTranslator.new(t, t.editions.last)
    new_edition = translator.run
    assert_equal [1, 2, 3], new_edition.expectation_ids
  end

  test "it handles publications with no panopticon ID" do
    t = sample_transaction
    t.panopticon_id = nil
    translator = WholeEditionTranslator.new(t, t.editions.last)
    new_edition = translator.run
    assert ! new_edition.valid?
  end

  test "it handles LGSL data for local transactions" do
    pending "need to rewrite all local transaction tests for branch"
    # lts = LocalTransactionsSource.create!
    #     
    # lgsl = lts.lgsls.create!(code: "1")
    # lgsl.authorities.create(snac: '00BC')
    # 
    # local_transaction = LocalTransaction.new(lgsl_code: "1", name: "Local Transaction", slug: "slug", panopticon_id: 1243)
    # local_transaction.editions.build(introduction: 'Something local', title: 'A local transaction')
    # assert local_transaction.save
    # 
    # assert ! LocalTransactionsSource.find_current_lgsl('1').nil?
    # translator = WholeEditionTranslator.new(local_transaction, local_transaction.editions.last)
    # new_edition = translator.run
    # 
    # assert new_edition.valid?    
    # assert_equal '1', new_edition.lgsl_code
    # assert_equal '00BC', new_edition.lgsl.authorities.first.snac
  end
end