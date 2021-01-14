require 'uri'
require 'json'
require 'base64'
require 'io/console'

require 'dotenv/load'
require 'rest-client'

AUTH_STATE_FILENAME = '.spotify_auth_state.json'
REDIRECT_URI = 'http://localhost'
SCOPES = [
  'user-read-recently-played',
  'playlist-modify-public',
  'playlist-modify-private',
  'playlist-read-private',
]


module Spotify
  def self.authorize_user()
    base = 'https://accounts.spotify.com/authorize'
    params = URI.encode_www_form({
      response_type: 'code',
      redirect_uri: REDIRECT_URI,
      scope: SCOPES.join(' '),
      client_id: ENV['SPOTIFY_CLIENT_ID'],
    })
    puts "Open the link below in your browser, authorize your app, then paste the code from the URL params."
    puts "#{base}?#{params}"
    print "\nCode: "
    auth_code = gets
    url = 'https://accounts.spotify.com/api/token'
    payload = {
      grant_type: 'authorization_code',
      show_dialog: 'true',
      code: auth_code.chomp,
      redirect_uri: REDIRECT_URI,
      client_id: ENV['SPOTIFY_CLIENT_ID'],
      client_secret: ENV['SPOTIFY_CLIENT_SECRET'],
    }
    response = RestClient.post(url, payload, headers={})
    data = JSON.parse(response.body)
    File.write(AUTH_STATE_FILENAME, response.body)
    puts "\nAccess tokens saved to #{AUTH_STATE_FILENAME}!"
    return data['access_token']
  end


  def self.refresh_access_token()
    auth_state = JSON.parse(File.read(AUTH_STATE_FILENAME))
    url = 'https://accounts.spotify.com/api/token'
    payload = {
      grant_type: 'refresh_token',
      refresh_token: auth_state['refresh_token'].chomp,
      redirect_uri: REDIRECT_URI,
      client_id: ENV['SPOTIFY_CLIENT_ID'],
      client_secret: ENV['SPOTIFY_CLIENT_SECRET'],
    }
    response = RestClient.post(url, payload, headers={})
    data = JSON.parse(response.body)
    return data['access_token']
  end


  def self.get_listening_history(access_token)
    url = 'https://api.spotify.com/v1/me/player/recently-played?limit=50'
    headers = {
      Authorization: "Bearer #{access_token}",
    }
    response = RestClient.get(url, headers)
    data = JSON.parse(response.body)
    tracks = data['items'].select { |item| item.key?('track') }
    return tracks
  end


  def self.update_listen_later(playlist_id, history, access_token)
    # get playlist tracks
    base_url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
    params = {
      market: ENV['SPOTIFY_MARKET'],
      fields: 'items(track(uri,linked_from))',
    }
    headers = {
      Authorization: "Bearer #{access_token}",
      'Content-Type': 'application/json',
    }
    url = "#{base_url}?#{URI.encode_www_form(params)}"
    response = RestClient.get(url, headers)
    playlist_tracks = JSON.parse(response.body)['items']
    playlist_uris = []
    # get URIs of playlist tracks in history
    history_uris = history.map { |item| item['track']['uri'] }
    playlist_tracks.each do |p_item|
      track = p_item['track']
      if history_uris.include? track['uri']
        if track.has_key?('linked_from')
          playlist_uris.append({
            uri: track['linked_from']['uri']
          })
        end
      end
    end
    if playlist_uris.length == 0
      return
    end
    # delete tracks already listened to
    payload = {
      tracks: playlist_uris
    }
    puts payload
    response = RestClient::Request.execute(
      method: 'delete',
      url: base_url,
      payload: payload.to_json,
      headers: headers,
    )
    return response
  end


  def self.check_env()
    vars = [
			'SPOTIFY_PLAYLIST_ID',
			'SPOTIFY_CLIENT_ID',
			'SPOTIFY_CLIENT_SECRET',
			'SPOTIFY_MARKET',
    ]
    missing_vars = []
    vars.each do |var|
      if not ENV.has_key?(var)
        missing_vars.append(var)
      end
    end
    message = ''
    if missing_vars.length > 0
      message = ".env file missing variables:\n#{missing_vars.join(', ')}"
    end
    return message
  end
end
