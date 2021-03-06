FactoryGirl.define do

  factory :term do
    season 100
    starts_on "2013-01-15"
    ends_on "2013-05-15"
    year 2013

    factory :term2 do
      season 400
      starts_on "2013-08-15"
      ends_on "2013-12-15"
    end
  end

end
