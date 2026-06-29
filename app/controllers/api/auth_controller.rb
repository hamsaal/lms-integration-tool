module Api
  class AuthController < ApplicationController
    skip_before_action :authenticate_request!, only: :dev_token

    def dev_token
      user = User.find_by!(email: params.require(:email))
      render json: { token: Auth::Token.encode(user), user: UserSerializer.render(user) }
    end
  end
end
