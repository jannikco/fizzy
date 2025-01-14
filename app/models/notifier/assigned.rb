class Notifier::Assigned < Notifier
  private
    def body
      "#{event.creator.name} assigned to you"
    end

    def recipients
      event.assignees.without(creator)
    end
end
