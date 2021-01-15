# Spotify Listen Later

A script for managing your own "Listen Later" playlist which removes
tracks you've recently listened to.


## Requirements
- ruby
- bundle


## Setup
1. Create a [Spotify Application](https://developer.spotify.com/dashboard/applications)
and add `http://localhost` as a valid Redirect URI. Take note of its client
ID and secret.

2. Create your own Spotify playlist (public or private) for the app to manage.
Take note of the playlist ID, which can be found in either the playlist link or URI.

3. Clone this repo and `cd` into the directory.

4. Create an `.env` file with the following variables:
```
SPOTIFY_CLIENT_ID=<your application client id>
SPOTIFY_CLIENT_SECRET=<your application client secret>
SPOTIFY_PLAYLIST_ID=<listen later playlist id>
SPOTIFY_MARKET=<your market, i.e. "US">
```

5. Install dependencies by running `bundle install`.

6. Authorize your app by running `./bin/authorize`. This will save your
access tokens in the file `.spotify_auth_state.json` to be used by other
scripts.

7. Test the `./bin/update_listen_later` script. This outputs a JSON of the
response if the playlist is updated, or a message saying that there are no
tracks to delete.

8. Schedule the `update_listen_later` script to run regularly, such as every
10 minutes. This must be run from the project directory for it to work
properly. I personally prefer to schedule a cron job on my own VM.
```bash
# sample cron job
*/10 * * * * cd ~/spotify-listen-later && ./bin/update_listen_later
```
