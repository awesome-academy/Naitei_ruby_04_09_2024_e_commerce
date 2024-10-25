require "jwt"

class Authentication
  ALGORITHM = Settings.algorithm.freeze

  def self.encode payload
    JWT.encode(payload, ENV["AUTH_SECRET"], ALGORITHM)
  end

  def self.decode token
    JWT.decode(token, ENV["AUTH_SECRET"], true, algorithm: ALGORITHM).first
  end
end
