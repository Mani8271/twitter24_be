class HomeController < ApplicationController
  skip_before_action :authorize_request
  layout false

  def index
  end
end
