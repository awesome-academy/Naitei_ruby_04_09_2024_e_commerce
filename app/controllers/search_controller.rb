class SearchController < ApplicationController
  before_action :set_query
  before_action :check_empty_query, only: [:index]

  def index
    perform_search
  end

  private

  def set_query
    @query = params[:query].to_s.strip
  end

  def check_empty_query
    return if @query.present?

    flash[:alert] = t("search.enter")
    redirect_to root_path and return
  end

  def perform_search
    @categories = Category.search_by_name(@query)
    @products = Product.search_by_name(@query)
  end
end