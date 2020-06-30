class Term < ApplicationRecord
  belongs_to :room
  has_many :begin_end_times, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :student_terms, dependent: :destroy
  has_many :students, through: :student_terms
  has_many :student_requests, dependent: :destroy
  has_many :subject_terms, dependent: :destroy
  has_many :subjects, through: :subject_terms
  has_many :pieces, dependent: :destroy
  has_many :teacher_terms, dependent: :destroy
  has_many :teachers, through: :teacher_terms
  has_many :teacher_requests, dependent: :destroy
  has_many :timetables, dependent: :destroy
  validate :verify_context
  after_create :create_associations
  enum type: { one_week: 0, variable: 1 }
  self.inheritance_column = :_type_disabled

  def date_array
    if one_week?
      (('2001-01-01'.to_date)..('2001-01-07'.to_date)).map(&:to_s)
    elsif variable?
      (begin_at..end_at).map(&:to_s)
    end
  end

  def period_array
    (1..max_period).map(&:to_s)
  end

  def seat_array
    (1..max_seat).map(&:to_s)
  end

  def seat_per_teacher_array
    (1..class_per_teacher).map(&:to_s)
  end

  def max_week
    (end_at - begin_at + 7).to_i / 7
  end

  def date_array_one_week(week_number)
    if one_week?
      ('2001-01-01'.to_date)..('2001-01-07'.to_date)
    elsif variable?
      week_number = 1 if week_number < 1
      week_number = max_week if week_number > max_week
      begindate = begin_at + (7 * week_number) - 7
      enddate = begin_at + (7 * week_number) - 1
      enddate = self.end_at if enddate > self.end_at
      begindate..enddate
    end
  end

  def readied_teachers
    teachers.joins(:teacher_terms).where(
      'teacher_terms.term_id': id,
      'teacher_terms.status': 1,
    )
  end

  def readied_students
    students.joins(:student_terms).where(
      'student_terms.term_id': id,
      'student_terms.status': 1,
    )
  end

  def show_type
    if one_week?
      '１週間モード'
    elsif variable?
      '任意期間モード'
    end
  end

  def ordered_students
    students.order(birth_year: 'ASC')
  end

  def ordered_teachers
    teachers.order(name: 'DESC')
  end

  def ordered_subjects
    subjects.order(order: 'ASC')
  end

  def terms_per_teacher(date, period)
    timetable_id = Timetable.find_by(date: date, period: period).id
    terms.where(timetable_id: timetable_id).reduce({}) do |accu, term|
      (accu[term.teacher_id.to_s] ||= []).push(term)
    end
  end

  private

  def verify_context
    return if begin_at.nil? || end_at.nil?

    if variable? && (end_at - begin_at).negative?
      errors[:base] << '開始日、終了日を正しく設定してください。'
    elsif variable? && (end_at - begin_at) >= 50
      errors[:base] << '期間は50日以内に設定してください。'
    end
  end

  def create_associations
    SubjectTerm.bulk_create(self)
    StudentTerm.bulk_create(self)
    TeacherTerm.bulk_create(self)
    BeginEndTime.bulk_create(self)
    Timetable.bulk_create(self)
    Contract.bulk_create(self)
  end
end
