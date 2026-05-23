class KanbanCardPolicy < ApplicationPolicy
  def index?
    record.kanban_board.user_id == user.id
  end

  def create?
    record.kanban_board.user_id == user.id
  end

  def update?
    record.kanban_board.user_id == user.id
  end

  def move?
    record.kanban_board.user_id == user.id
  end

  def archive?
    record.kanban_board.user_id == user.id
  end

  def unarchive?
    record.kanban_board.user_id == user.id
  end

  def bulk_archive?
    record.kanban_board.user_id == user.id
  end

  def destroy?
    record.kanban_board.user_id == user.id
  end
end
