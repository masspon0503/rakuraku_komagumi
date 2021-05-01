class TermsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rooms!
  before_action :set_room!
  before_action :set_term!, only: [:show, :schedule]

  def index
    @terms = @room.terms.order(begin_at: 'DESC')
  end

  def create
    @term = Term.new(create_params)
    respond_to do |format|
      if @term.save
        format.js { @success = true }
      else
        format.js { @success = false }
      end
    end
  end

  def update
    @term = Term.find_by(id: params[:id])
    respond_to do |format|
      if @term.update(update_params)
        format.js { @success = true }
      else
        format.js { @success = false }
      end
    end
  end

  def show
  end

  def schedule
    @tutorial_pieces = TutorialPiece.indexed_and_named.where(term_id: @term.id)
    @seats = Seat.with_group.with_index.where(term_id: @term.id)
  end

  def optimization
    record = Term.find_by(id: params[:id])
    if record.update(update_optimization_params)
      render json: record.to_json, status: :ok
    else
      render json: { message: record.errors.full_messages }, status: :bad_request
    end
  end

  protected

  def create_params
    params.require(:term).permit(
      :room_id,
      :name,
      :term_type,
      :year,
      :begin_at,
      :end_at,
      :period_count,
      :seat_count,
      :position_count,
    )
  end

  def update_params
    params.require(:term).permit(:name, :year)
  end

  def update_optimization_params
    params.require(:term).permit(:is_optimizing)
  end
end
