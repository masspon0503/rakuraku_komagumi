class CreateSeats < ActiveRecord::Migration[5.2]
  def change
    create_table :seats do |t|
      t.integer :timetable_id, null: false
      t.integer :term_teacher_id
      t.integer :seat_index, null: false
      t.integer :seat_limit, null: false
      t.timestamps
    end
    add_index :seats, [:timetable_id, :seat_index], unique: true
    add_foreign_key :seats, :timetables, on_update: :cascade, on_delete: :cascade
  end
end