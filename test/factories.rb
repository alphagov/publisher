FactoryGirl.define do
  factory :guide do
    slug "Childcare"
    tags "children,care"
    is_business false
  end
  
  factory :part do
    title "A part"
    body  "Part body"
  end
end