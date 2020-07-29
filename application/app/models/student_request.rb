class StudentRequest < ApplicationRecord
  belongs_to :term
  belongs_to :student_term
  belongs_to :timetable

  def self.get_student_requests(student_term, term)
    student_requests = where(
      term_id: term.id,
      student_term_id: student_term.id,
    )
    term.timetables.reduce({}) do |accu, item|
      accu.deep_merge({
        item.date => {
          item.period => student_requests.find do |student_request|
            item.id == student_request.timetable_id
          end,
        },
      })
    end
  end
end