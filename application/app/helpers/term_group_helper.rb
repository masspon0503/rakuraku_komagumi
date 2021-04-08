module TermGroupHelper
  def options_for_select_group_id(room, term)
    plucked_groups = room.groups.active.pluck(:name, :id) 
    plucked_term_groups = term.term_groups.ordered.joins(:group).pluck('groups.name', :group_id)
    plucked_groups - plucked_term_groups
  end
end