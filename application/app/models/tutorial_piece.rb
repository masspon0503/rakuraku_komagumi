class TutorialPiece < ApplicationRecord
  extend OccupationsBlanks

  belongs_to :term
  belongs_to :tutorial_contract
  belongs_to :seat, optional: true

  validate :verify_seat_occupation,
           on: :update,
           if: :will_save_change_to_seat_id?
  validate :verify_term_teacher,
           on: :update,
           if: :will_save_change_to_seat_id?
  validate :verify_student_vacancy,
           on: :update,
           if: :will_save_change_to_seat_id?
  validate :verify_doublebooking,
           on: :update,
           if: :will_save_change_to_seat_id?
  validate :verify_daily_occupation_limit,
           on: :update,
           if: :will_save_change_to_seat_id?
  validate :verify_daily_blank_limit,
           on: :update,
           if: :will_save_change_to_seat_id?
  accepts_nested_attributes_for :seat

  before_validation :fetch_seat_in_database, on: :update
  before_validation :fetch_new_tutorials_group_by_timetable, on: :update
  before_validation :fetch_groups_group_by_timetable, on: :update
  before_update :set_term_teacher_on_seat,
                if: :will_save_change_to_seat_id?
  before_update :unset_term_teacher_on_seat,
                if: :will_save_change_to_seat_id?
  # after_updateコールバックの順番を入れ替えてはいけません
  # save_seat_in_databaseの実行後に一時的にバリデーション違反がある中間状態を経由しています
  after_update :set_skip_intermediate_state_validation
  after_update :save_seat_in_database
  after_update :save_seat

  scope :filter_by_placed, -> { where.not(seat_id: nil) }
  scope :filter_by_unplaced, -> { where(seat_id: nil) }
  scope :filter_by_student, lambda { |term_student_id|
    itself
      .joins(:tutorial_contract)
      .where('tutorial_contracts.term_student_id': term_student_id)
  }
  scope :indexed_and_named, lambda {
    joins(
      tutorial_contract: [
        term_student: [:student],
        term_tutorial: [:tutorial],
        term_teacher: [:teacher]
      ],
      seat: :timetable,
    ).select(
      'tutorial_pieces.*',
      'timetables.date_index',
      'timetables.period_index',
      'seats.seat_index',
      'students.name AS student_name',
      'tutorials.name AS tutorial_name',
      'teachers.name AS teacher_name',
    )
  }

  private

  def seat_creation?
    seat_id_in_database.nil? && seat_id.present?
  end

  def seat_updation?
    seat_id_in_database.present? && seat_id.present? && seat_id_in_database != seat_id
  end

  def seat_deletion?
    seat_id_in_database.present? && seat_id.nil?
  end

  # validate
  def verify_seat_occupation
    if (seat_creation? || seat_updation?) && seat.tutorial_pieces.count >= seat.position_count
      errors.add(:base, '座席の最大人数をオーバーしています')
    end
  end

  def verify_term_teacher
    if (seat_creation? || seat_updation?) &&
       seat.term_teacher_id.present? &&
       seat.term_teacher_id != tutorial_contract.term_teacher_id
      errors.add(:base, '座席に割り当てられた講師と担当講師が一致しません')
    end
  end

  def verify_student_vacancy
    if (seat_creation? || seat_updation?) &&
       !seat.timetable.student_vacancies.find_by(term_student_id: tutorial_contract.term_student_id).is_vacant
      errors.add(:base, '生徒の予定が空いていません')
    end
  end

  def position_occupations(timetable)
    @new_tutorials_group_by_timetable.dig(timetable.date_index, timetable.period_index).to_a.count
  end

  def verify_doublebooking
    if seat_creation? && position_occupations(seat.timetable) > 1
      errors.add(:base, '生徒の予定が重複しています')
    end

    if seat_updation? && position_occupations(seat.timetable) > 1
      errors.add(:base, '生徒の予定が重複しています')
    end
  end

  def daily_occupations(date_index)
    tutorials = @new_tutorials_group_by_timetable[date_index].to_h
    groups = @groups_group_by_timetable[date_index].to_h
    self.class.daily_occupations_from(term, tutorials, groups)
  end

  def verify_daily_occupation_limit
    limit = tutorial_contract.term_student.optimization_rule.occupation_limit
    if seat_creation? && daily_occupations(seat.timetable.date_index) > limit
      errors.add(:base, '生徒の１日の合計コマの上限を超えています')
    end

    if seat_updation? && daily_occupations(seat.timetable.date_index) > limit
      errors.add(:base, '生徒の１日の合計コマの上限を超えています')
    end
  end

  def daily_blanks(date_index)
    tutorials = @new_tutorials_group_by_timetable[date_index].to_h
    groups = @groups_group_by_timetable[date_index].to_h
    self.class.daily_blanks_from(term, tutorials, groups)
  end

  def verify_daily_blank_limit
    limit = tutorial_contract.term_student.optimization_rule.blank_limit
    if seat_creation? && daily_blanks(seat.timetable.date_index) > limit
      errors.add(:base, '生徒の１日の空きコマの上限を超えています')
    end

    if seat_updation? && (
      daily_blanks(seat.timetable.date_index) > limit ||
      daily_blanks(@seat_in_database.timetable.date_index) > limit
    )
      errors.add(:base, '生徒の１日の空きコマの上限を超えています')
    end

    if seat_deletion? && daily_blanks(@seat_in_database.timetable.date_index) > limit
      errors.add(:base, '生徒の１日の空きコマの上限を超えています')
    end
  end

  # before_validation
  def fetch_seat_in_database
    @seat_in_database = Seat.find_by(id: seat_id_in_database)
  end

  def fetch_new_tutorials_group_by_timetable
    records = term
              .tutorial_pieces
              .filter_by_student(tutorial_contract.term_student_id)
              .left_joins(:tutorial_contract, seat: :timetable)
              .select(:id, :term_student_id, :date_index, :period_index, :seat_id)
              .map do |item|
                {
                  id: item[:id],
                  term_student_id: item[:term_student_id],
                  date_index: item[:id] == id ? seat&.timetable&.date_index : item[:date_index],
                  period_index: item[:id] == id ? seat&.timetable&.period_index : item[:period_index],
                  seat_id: item[:id] == id ? seat_id : item[:seat_id],
                }
              end
              .select { |item| item[:seat_id].present? }
    @new_tutorials_group_by_timetable = records.group_by_recursive(
      proc { |item| item[:date_index] },
      proc { |item| item[:period_index] },
    )
  end

  def fetch_groups_group_by_timetable
    records = term
              .group_contracts
              .filter_by_student(tutorial_contract.term_student_id)
              .filter_by_is_contracted
              .joins(term_group: :timetables)
              .select(:term_student_id, :date_index, :period_index)
    @groups_group_by_timetable = records.group_by_recursive(
      proc { |item| item[:date_index] },
      proc { |item| item[:period_index] },
    )
  end

  # before_update
  def set_term_teacher_on_seat
    if (seat_creation? || seat_updation?) && seat.tutorial_pieces.count.zero?
      seat.term_teacher_id = tutorial_contract.term_teacher_id
    end
  end

  def unset_term_teacher_on_seat
    if (seat_updation? || seat_deletion?) && @seat_in_database.tutorial_pieces.count == 1
      @seat_in_database.term_teacher_id = nil
    end
  end

  # after_update
  def set_skip_intermediate_state_validation
    if @seat_in_database.present? && seat.present?
      skip_intermediate_state_validation = @seat_in_database.timetable.date_index == seat.timetable.date_index
      @seat_in_database.skip_intermediate_state_validation = skip_intermediate_state_validation
    end
  end

  def save_seat_in_database
    if @seat_in_database.present? && !@seat_in_database.save
      raise ActiveRecord::Rollback
    end
  end

  def save_seat
    if seat.present? && !seat.save
      raise ActiveRecord::Rollback
    end
  end
end
