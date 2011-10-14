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
    a.save
    assert a.has_drafts
    assert ! a.lined_up
    assert ! a.has_fact_checking
    assert ! a.has_reviewables

    b = Guide.create
    b.publish b.editions.first, "Publishing this"
    b.save
    b.reload
    assert !b.has_drafts

    assert_equal [a], presenter.in_draft.to_a
  end

  test "should filter by published state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create
    assert !a.has_published

    b = Guide.create
    b.publish b.editions.first, "Publishing this"
    b.save
    b.reload
    assert b.has_published

    assert_equal [b], presenter.published.to_a
  end

  test "should filter by archived state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create
    assert !a.archived

    b = Guide.create(archived: true)
    assert b.archived

    assert_equal [b], presenter.archive.to_a
  end

  test "should filter by review requested state" do
    presenter = AdminRootPresenter.new(:all)
    user = User.create

    a = Guide.create
    assert !a.has_reviewables

    b = Guide.create
    b.editions.first.new_action(user, Action::REVIEW_REQUESTED)
    b.save
    b.reload
    assert b.has_reviewables

    assert_equal [b], presenter.review_requested.to_a
  end

  test "should filter by fact checking state" do
    presenter = AdminRootPresenter.new(:all)
    user = User.create

    a = Guide.create
    assert !a.has_fact_checking

    b = Guide.create
    b.editions.first.new_action(user, Action::FACT_CHECK_REQUESTED)
    b.save
    b.reload
    assert b.has_fact_checking

    assert_equal [b], presenter.fact_checking.to_a
  end

  test "should filter by lined up state" do
    presenter = AdminRootPresenter.new(:all)

    a = Guide.create
    assert a.lined_up

    b = Guide.create
    b.lined_up = false
    b.save
    b.reload
    assert !b.lined_up

    assert_equal [a], presenter.lined_up.to_a
  end

  test "should select in progress publications assigned to a user" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    assert_nil a.editions.first.assigned_to
    assert a.has_drafts

    b = Guide.create
    b.save
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_drafts
    assert ! b.lined_up

    presenter = AdminRootPresenter.new(bob)
    assert_equal [b], presenter.in_draft.to_a
  end

  test "should select in progress publications assigned to nobody" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    a.save
    assert_nil a.editions.first.assigned_to
    assert a.has_drafts

    b = Guide.create
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_drafts

    presenter = AdminRootPresenter.new(:nobody)
    assert_equal [a], presenter.in_draft.to_a
  end

  test "should select all in progress publications" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    a.save
    assert_nil a.editions.first.assigned_to
    assert a.has_drafts

    b = Guide.create
    b.save
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_drafts

    presenter = AdminRootPresenter.new(:all)
    assert_equal [b, a].collect { |i| i.id.to_s }.sort, presenter.in_draft.to_a.collect { |i| i.id.to_s }.sort
  end

  test "should select and filter" do
    alice = User.create
    bob   = User.create

    a = Guide.create
    a.save
    assert_nil a.editions.first.assigned_to
    assert a.has_drafts

    b = Guide.create
    b.save
    alice.assign(b.editions.first, bob)
    assert_equal bob, b.editions.first.assigned_to
    assert b.has_drafts

    c = Guide.create
    c.publish c.editions.first, "Publishing this"
    c.save
    c.reload
    alice.assign(c.editions.first, bob)
    assert_equal bob, c.editions.first.assigned_to
    assert !c.has_drafts

    presenter = AdminRootPresenter.new(bob)
    assert_equal [b], presenter.in_draft.to_a

    presenter = AdminRootPresenter.new(:nobody)
    assert_equal [a], presenter.in_draft.to_a

    presenter = AdminRootPresenter.new(:all)
    assert_equal [a, b], presenter.in_draft.to_a
  end

end
