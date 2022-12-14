module Auth
  def make_token_if_authenticated(email, password)
    p email, password
    # ユーザー取得
    user = User.find_by(email: email)&.authenticate(password)
    if user == nil
      return nil
    end
    # payload作成
    payload = {
      iss: "example.com", # JWT発行者
      sub: user.id, #JWT主体
      exp: (DateTime.current + 14.days).to_i #JWT有効期限
    }
    # 秘密鍵の取得
    rsa_private = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('auth/service.key')))
    # JWTの作成
    token = JWT.encode(payload, rsa_private, 'RS256')
    return token
  end

  def get_authenticated_user
    # CookieからJWTを取得
    token = cookies[:token]
    # 秘密鍵の取得
    rsa_private = OpenSSL::PKey::RSA.new(File.read(Rails.root.join('auth/service.key')))
    # JWTデコード、ペイロードから取得エラーの場合、認証エラーとする
    begin
      decoded_token = JWT.decode(token, rsa_private, true, { algorithm: 'RS256' })
    rescue StandardError => e
      p e.message
      return {
        status_code: 401,
        message: :unauthorized
      }
    end
    # subからユーザーIDを取得
    user_id = decoded_token.first['sub']
    # user_idからユーザーを検索
    user = User.find(user_id)
    return user
  end
end
