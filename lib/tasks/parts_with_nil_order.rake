# Temporary task to fix a guide edition with a part saved without an order.
namespace :parts_with_nil_order do
  desc "Set the order of the part with no order on edition 0e2b17bf-88c3-43ac-81aa-347f991bef43 to 4"
  task fix: :environment do
    edition = Edition.find("0e2b17bf-88c3-43ac-81aa-347f991bef43")
    parts = edition.parts.where(order: nil)
    abort "Expected 1 part with no order, found #{parts.count}" unless parts.count == 1

    part = parts.first
    part.update!(order: 4)

    puts "Set order to 4 for part Id: #{part.id} Title: #{part.title} on edition: #{edition.title} (#{edition.state})"
  end
end
