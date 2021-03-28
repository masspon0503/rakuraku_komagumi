FactoryBot.define do
  factory :term_student, class: TermStudent do
    association :student, factory: :student
    association :term, factory: :spring_term
    id             { 1 }
    school_grade   { 21 }
    vacancy_status { 0 }
  end
end