# app/helpers/admin/application_helper.rb
module Admin::ApplicationHelper
  def product_image product
    product.img_url.presence || "default_image_url_here"
  end
end
