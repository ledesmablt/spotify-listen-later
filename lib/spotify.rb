require 'json'
require 'base64'

require 'dotenv/load'
require 'rest-client'


AUTH_URL = 'https://accounts.spotify.com/api/token'

def get_access_token()
  encoded_secret = Base64.strict_encode64(
    "#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}"
  )
  headers = {
    authorization: "Basic #{encoded_secret}",
  }
  payload = {
    grant_type: 'client_credentials',
  }
  response = RestClient.post(AUTH_URL, payload, headers)
  data = JSON.parse(response.body)
  return data['access_token']
end

puts get_access_token
