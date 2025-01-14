class Notifier::Commented < Notifier
  private
    def body
      "#{event.creator.name}"
    end

    def resource
      event.comment
    end
end
