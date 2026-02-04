class ViewsController < ApplicationController
  before_action :authorize_request

  def create
    viewable = find_viewable
    viewable.views.find_or_create_by!(user: current_user)
    head :ok
  end

  private

  def find_viewable
    allowed_types = %w[GlobalFeed FreedCrate]

    type = params.require(:viewable_type)
    id   = params.require(:viewable_id)

    raise ActiveRecord::RecordNotFound unless allowed_types.include?(type)

    type.constantize.find(id)
  end
end
