module TeacherTermHelper
  def teacher_request_button(teacher_request, timetable, teacher_term)
    content_tag(:div,
                'data-id' => teacher_request ? teacher_request.id : nil,
                'data-teacher_term_id' => teacher_term.id,
                'data-timetable_id' => timetable.id) do
      button_tag(
        teacher_request ? 'OK' : 'NG',
        class: teacher_request ? 'btn btn-primary' : 'btn btn-danger',
        id: "btn_#{timetable.id}",
        disabled: teacher_term.is_decided,
      )
    end
  end

  def schedule_cell(pieces)
    content_tag(:div) do
      pieces.each do |piece|
        concat(
          content_tag(:div) do
            "#{piece.contract.student_term.student.name}
            （#{piece.contract.subject_term.subject.name}）"
          end,
        )
      end
    end
  end
end
