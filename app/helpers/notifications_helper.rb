module NotificationsHelper
  def notification_title(notification)
    title = notification.bubble.title

    if notification.resource.is_a? Comment
      "RE: " + title
    elsif notification_event_action(notification) == "assigned"
      "Assigned to you: " + title
    else
      title
    end
  end

  def notification_body(notification)
    name = notification.creator.name

    case notification_event_action(notification)
    when "popped" then "Popped by #{name}"
    when "published" then "Added by #{name}"
    else name
    end
  end

  def notification_tag(notification, &)
    link_to notification.resource, id: dom_id(notification), class: "notification border-radius",
      data: { action: "click->dialog#close", turbo_frame: "_top" }, &
  end

  def notifications_next_page_link(page)
    unless @page.last?
      tag.div id: "next_page", data: { controller: "fetch-on-visible", fetch_on_visible_url_value: notifications_path(page: @page.next_param) }
    end
  end

  private
    def notification_event_action(notification)
      if notification_is_for_initial_assignement?(notification)
        "assigned"
      else
        notification.event.action
      end
    end

    def notification_is_for_initial_assignement?(notification)
      notification.event.action == "published" && notification.bubble.assigned_to?(notification.user)
    end
end
