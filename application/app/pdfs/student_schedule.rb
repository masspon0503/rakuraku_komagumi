class StudentSchedule < Prawn::Document
  include Common

  def initialize(term, term_student, tutorial_pieces, timetables)
    page_layout = rotate?(term) ? :landscape : :portrait
    super(page_size: 'A4', page_layout: page_layout, left_margin: 20, right_margin: 20, top_margin: 60)
    font Rails.root.join('vendor', 'fonts', 'ipaexm.ttf')
    pdf_table(term, tutorial_pieces, timetables)
    number_pages('<page> / <total>', { at: [bounds.right - 50, 0], size: 7 })
    number_pages("#{term.name}予定表 #{term_student.student.name}", at: [bounds.left, bounds.top + 20])
  end

  private

  def pdf_table(term, tutorial_pieces, timetables)
    max_width = rotate?(term) ? 801 : 555
    header_col_width = 80
    body_col_width = (max_width - header_col_width) / term.period_count
    font_size(8) do
      table table_cells(term, tutorial_pieces, timetables),
            cell_style: { width: body_col_width, padding: 3, leading: 2 } do
        cells.borders = [:top, :bottom, :right, :left]
        cells.border_width = 1.0
        columns(0).width = header_col_width
        row(0).text_color = 'ffffff'
        self.header = true
      end
    end
  end

  def table_cells(term, tutorial_pieces, timetables)
    term.date_index_array.reduce([header(term)]) do |rows, date_index|
      rows + [
        term.period_index_array.reduce([header_left(term, date_index)]) do |cols, period_index|
          tutorial_piece = tutorial_pieces.find do |item|
            item[:date_index] == date_index && item[:period_index] == period_index
          end
          timetable = timetables.find do |item|
            item[:date_index] == date_index && item[:period_index] == period_index
          end
          cols + [table_cell(tutorial_piece, timetable)]
        end
      ]
    end
  end

  def table_cell(tutorial_piece, timetable)
    if timetable[:is_closed]
      {
        content: '休講',
        background_color: COLOR_DISABLE,
        height: 25,
      }
    elsif !timetable[:is_vacant]
      {
        content: '出席不可',
        background_color: COLOR_DISABLE,
        height: 25,
      }
    elsif timetable[:group_name]
      {
        content: timetable[:group_name],
        background_color: timetable[:is_contracted] ? COLOR_ENABLE : COLOR_DISABLE,
        height: 25,
      }
    elsif tutorial_piece.present?
      {
        content: "#{tutorial_piece.tutorial_name}（#{tutorial_piece.teacher_name}）",
        background_color: COLOR_ENABLE,
        height: 25,
      }
    else
      {
        content: ' ',
        background_color: COLOR_PLAIN,
        height: 25,
      }
    end
  end
end
