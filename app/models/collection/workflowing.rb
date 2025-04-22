module Collection::Workflowing
  extend ActiveSupport::Concern

  included do
    belongs_to :workflow, optional: true

    after_update_commit :set_all_cards_to_initial_workflow_stage, if: :saved_change_to_workflow_id?
  end

  def initial_workflow_stage
    workflow&.stages&.first
  end

  private
    def set_all_cards_to_initial_workflow_stage
      cards.update_all(stage_id: initial_workflow_stage.id)
    end
end
