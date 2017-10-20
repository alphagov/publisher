class RemoveBusinessSupportEditionsAndSupportObjects < Mongoid::Migration
  def self.up
    db = Mongoid::Clients.default

    say_with_time "Removing business support editions from editions collection" do
      editions = db[:editions]
      editions.delete_many(_type: 'BusinessSupportEdition').deleted_count
    end

    say_with_time "Removing business support business sizes collection" do
      business_support_business_sizes = db[:business_support_business_sizes]
      business_support_business_sizes.drop()
    end

    say_with_time "Removing business support business types collection" do
      business_support_business_types = db[:business_support_business_types]
      business_support_business_types.drop()
    end

    say_with_time "Removing business support locations collection" do
      business_support_locations = db[:business_support_locations]
      business_support_locations.drop()
    end

    say_with_time "Removing business support purposes collection" do
      business_support_purposes = db[:business_support_purposes]
      business_support_purposes.drop()
    end

    say_with_time "Removing business support sectors collection" do
      business_support_sectors = db[:business_support_sectors]
      business_support_sectors.drop()
    end

    say_with_time "Removing business support stages collection" do
      business_support_stages = db[:business_support_stages]
      business_support_stages.drop()
    end

    say_with_time "Removing business support support types collection" do
      business_support_support_types = db[:business_support_support_types]
      business_support_support_types.drop()
    end
  end

  def self.down
    # this can't be undone
  end
end
