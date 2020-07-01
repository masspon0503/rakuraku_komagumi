class TeacherscheduleController < ApplicationController
  before_action :check_logined
  before_action :check_schedulemaster

  def teacherrequestmasters
    return @teacherrequestmasters if defined? @teacherrequestmasters

    @teacherrequestmasters = Teacherrequestmaster.get_teacherrequestmasters(@schedulemaster)
  end
  helper_method :teacherrequestmasters

  def blank_schedule_counts
    return @blank_schedule_counts if defined? @blank_schedule_counts

    @blank_schedule_counts = {}
    @schedulemaster.teachers.each do |te|
      @blank_schedule_counts[te.id] =
        @schedulemaster.schedules.where(timetable_id: 0, teacher_id: te.id).count
    end
    @blank_schedule_counts
  end
  helper_method :blank_schedule_counts
end
