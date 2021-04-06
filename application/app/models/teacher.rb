class Teacher < ApplicationRecord
  belongs_to :room
  has_many :term_teachers, dependent: :restrict_with_exception

  validates :name,
            length: { minimum: 1, maximum: 20 }
  validates :email,
            format: { with: /\A([^@\s]+)@(([-a-z0-9]+\.)+[a-z]{2,})\z/ }

  scope :active, -> { where(is_deleted: false) }
  scope :ordered, -> { order(name: 'ASC') }
  scope :matched, lambda { |keyword|
    keyword.instance_of?(String) && keyword.present? ?
      where('name like ?', "%#{sanitize_sql_like(keyword)}%") :
      itself
  }
  scope :pagenated, lambda { |page, page_size|
    page.instance_of?(Integer) && page_size.instance_of?(Integer) ?
      slice((page - 1) * page_size, page_size) :
      itself
  }
end
