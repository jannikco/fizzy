module NotificationsHelper
  def notification_tag(notification, &)
    link_to notification.resource, id: dom_id(notification), class: "notification border-radius",
      data: { turbo_frame: "_top" }, &
  end
end
