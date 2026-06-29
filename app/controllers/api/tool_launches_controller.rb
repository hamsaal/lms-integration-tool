module Api
  class ToolLaunchesController < ApplicationController
    skip_before_action :authenticate_request!, only: :create

    def create
      launch = LtiLaunchValidator.call(id_token: params.require(:id_token))
      render json: {
        data: ToolLaunchSerializer.render(launch.tool_launch),
        token: Auth::Token.encode(launch.user)
      }, status: :created
    rescue LtiLaunchValidator::LaunchError => error
      render_error("invalid_launch", error.message, :unauthorized)
    end
  end
end
