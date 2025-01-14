class Notifier::Created < Notifier
  private
    def body
      "Added by #{event.creator.name}"
    end
end
