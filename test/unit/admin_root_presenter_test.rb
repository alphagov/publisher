require 'test_helper'

class AdminRootPresenterTest < ActiveSupport::TestCase

  setup do
    json = JSON.dump("name" => "Childcare", "slug" => "childcare")
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
      to_return(:status => 200, :body => json, :headers => {})
  end

  test "should filter by draft state" do
    presenter = AdminRootPresenter.new(:all)
    
    a = Guide.create
    a.editions.first.update_attribute(:state,'draft')
    assert a.has_draft?

    b = Guide.create
    b.editions.first.update_attribute(:state,'published')
    b.save
    b.reload
    assert !b.has_draft?

    assert_equal [a], presenter.draft.to_a
  end

  test "should filter by published state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create
    assert !a.has_published?

    b = Guide.create                                      
    b.editions.first.update_attribute(:state, 'published')
    b.reload
    assert b.has_published?

    assert_equal [b], presenter.published.to_a
  end

  test "should filter by archived state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create
    assert !a.archived?

    b = Guide.create
    b.editions.create!(state: 'archived')
    assert b.has_archived?

    assert_equal [b], presenter.archived.to_a
  end

  test "should filter by in_review state" do
    presenter = AdminRootPresenter.new(:all)
    user = User.create

    a = Guide.create
    assert !a.has_in_review?

    b = Guide.create
    b.editions.first.update_attribute(:state, 'in_review')
    b.reload
    assert b.has_in_review?

    assert_equal [b], presenter.in_review.to_a
  end

  test "should filter by fact checking state" do
    presenter = AdminRootPresenter.new(:all)
    user = User.create

    a = Guide.create
    assert !a.has_fact_check?

    b = Guide.create
    b.editions.first.update_attribute(:state, 'fact_check')
    b.reload
    assert b.has_fact_check?

    assert_equal [b], presenter.fact_check.to_a
  end

  test "should filter by lined up state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create 
    a.editions.first.update_attribute(:state, "lined_up")
    assert a.has_lined_up?

    b = Guide.create  
    b.editions.first.update_attribute(:state, "draft")
    b.reload
    assert !b.has_lined_up?

    assert_equal [a], presenter.lined_up.to_a
  end

  test "should select publications assigned to a user" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    assert_nil a.editions.first.assigned_to
    assert a.has_lined_up?

    b = Guide.create
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_lined_up?

    presenter = AdminRootPresenter.new(bob)
    assert_equal [b], presenter.lined_up.to_a
  end

  test "should select publications assigned to nobody" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    assert_nil a.editions.first.assigned_to
    assert a.has_lined_up?

    b = Guide.create
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_lined_up?

    presenter = AdminRootPresenter.new(:nobody)
    assert_equal [a], presenter.lined_up.to_a
  end

  test "should select all publications" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    assert_nil a.editions.first.assigned_to
    assert a.has_lined_up?

    b = Guide.create
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_lined_up?

    presenter = AdminRootPresenter.new(:all)
    assert_equal [b, a].collect { |i| i.id.to_s }.sort, presenter.lined_up.to_a.collect { |i| i.id.to_s }.sort
  end

  test "should select and filter" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    assert_nil a.editions.first.assigned_to
    assert a.has_lined_up?

    b = Guide.create
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_lined_up?

    c = Guide.create
    c.editions.first.update_attribute :state, 'published'
    alice.assign(c.editions.first, bob)
    assert_equal bob, c.editions.first.assigned_to
    assert !c.has_lined_up?

    presenter = AdminRootPresenter.new(bob)
    assert_equal [b], presenter.lined_up.to_a

    presenter = AdminRootPresenter.new(:nobody)
    assert_equal [a], presenter.lined_up.to_a

    presenter = AdminRootPresenter.new(:all)
    assert_equal [a, b], presenter.lined_up.to_a
  end

end
