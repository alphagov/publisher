module SignonApiHelpers
  def stub_users_from_signon_api(uuids = [], users = [])
    Services.signon_api.stubs(:get_users).with(uuids:).returns(users)
  end
end
