module ApplicationHelper
  include Pagy::Frontend

  def full_title page_title
    base_title = t :page_title
    page_title.blank? ? base_title : "#{page_title} | #{base_title}"
  end

  def message_class message_type
    case message_type.to_sym
    when :notice
      "text-green-600 bg-green-200"
    when :success
      "text-green-600 bg-green-200"
    when :danger
      "text-red-600 bg-red-200"
    when :alert
      "text-red-600 bg-red-200"
    when :info
      "text-blue-600 bg-blue-200"
    else
      "text-yellow-600 bg-yellow-200"
    end
  end
end
