class TermTeachersController < ApplicationController
  PAGE_SIZE = 10

  before_action :authenticate_user!
  before_action :set_rooms!
  before_action :set_room!
  before_action :set_term!

  def index
    @page = sanitize_integer_query_param(params[:page]) || 1
    @page_size = PAGE_SIZE
    @term_teachers = current_term.term_teachers.ordered.pagenated(@page, @page_size)
    @term_teachers_count = current_term.term_teachers.count
  end

  def create
    @term_teacher = TermTeacher.new(create_params)
    respond_to do |format|
      if @term_teacher.save
        format.js { @success = true }
      else
        format.js { @success = false }
      end
    end
  end

  def show
    @teacher_term = TeacherTerm.find(params[:id])
    @timetables = Timetable.get_timetables(@term)
    @teacher_requests = TeacherRequest.get_teacher_requests(@teacher_term, @term)
    @week = @term.week(params[:week].to_i)
  end

  def schedule
    @teacher_term = TeacherTerm.find(params[:id])
    @timetables = Timetable.get_timetables(@term)
    @teacher_requests = TeacherRequest.get_teacher_requests(@teacher_term, @term)
    @week = @term.week(params[:week].to_i)
    @pieces = Piece.get_pieces_for_teacher(@term, @teacher_term)
    respond_to do |format|
      format.html
      format.pdf do
        pdf = TeacherSchedule.new(
          @term, @teacher_term, @pieces, @teacher_requests
        ).render
        send_data pdf,
                  filename: "#{@term.name}予定表#{@teacher_term.teacher.name}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  def update
    record = TeacherTerm.find(params[:id])
    if record.update(update_params)
      render json: record.to_json, status: :ok
    else
      render json: { message: record.errors.full_messages }, status: :bad_request
    end
  end

  private

  def create_params
    params.require(:term_teacher).permit(:term_id, :teacher_id)
  end

  def update_params
    params.require(:teacher_term).permit(:is_decided)
  end
end