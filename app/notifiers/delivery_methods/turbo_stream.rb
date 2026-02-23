class DeliveryMethods::TurboStream < ApplicationDeliveryMethod
  def deliver
    notification.broadcast_prepend_to(
      "notifications_#{recipient.id}",
      target: "notifications_list",
      html: render_item
    )
  end

  private

  def render_item
    ApplicationController.render(
      Notifications::ItemComponent.new(notification: notification),
      layout: false
    )
  end
end
