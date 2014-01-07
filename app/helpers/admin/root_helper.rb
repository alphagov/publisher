module Admin::RootHelper
  def user_options
    [["All", "all"], ["Nobody", "nobody"]] +
      User.where(suspended_at: nil).asc(:name).map{ |u| [u.name, u.uid] }
  end
end
