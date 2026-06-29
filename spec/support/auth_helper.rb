module AuthHelper
  def auth_headers(user)
    { "Authorization" => "Bearer #{Auth::Token.encode(user)}" }
  end
end
