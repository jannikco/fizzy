class Notifier::Popped < Notifier
  private
    def body
      "Popped by #{event.creator.name}"
    end
end
