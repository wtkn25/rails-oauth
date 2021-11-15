require "google/apis/calendar_v3"
require 'google/api_client/client_secrets.rb'
require "googleauth"
require "googleauth/stores/file_token_store"
require "date"
require "fileutils"

class CalendarController < ApplicationController
  REDIRECT_URI = "http://localhost:3000/oauth2callback".freeze
  APPLICATION_NAME = "api-sample".freeze
  CLIENT_SECRET_PATH = "client_secret.json".freeze
  # The file token.yaml stores the user's access and refresh tokens, and is
  # created automatically when the authorization flow completes for the first
  # time.
  TOKEN_PATH = "credentials.yaml".freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY
  MY_CALENDAR_ID = 'primary'

  def index
    unless session.has_key?(:credentials)
      puts(session[:credentials])
      redirect_to action: :callback
      return
    end

    client_opts = JSON.parse(session[:credentials])
    auth_client = Signet::OAuth2::Client.new(client_opts)
    calendar = Google::Apis::CalendarV3::CalendarService.new
    calendar_id = MY_CALENDAR_ID
    response = calendar.list_events(calendar_id, options: {
      authorization: auth_client
    })
    puts response.items
  end

  def callback
    client_secrets = Google::APIClient::ClientSecrets.load('./client_secret.json')
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      :scope => 'https://www.googleapis.com/auth/calendar',
      :redirect_uri => 'http://localhost:3000/oauth2callback'
    )
    if request['code'] == nil
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to auth_uri
    else
      auth_client.code = request['code']
      auth_client.fetch_access_token!
      auth_client.client_secret = nil
      session[:credentials] = auth_client.to_json
      redirect_to action: :index
    end
  end

  def fetchEvents(service)
    # Fetch the next 10 events for the user
    calendar_id = MY_CALENDAR_ID
    response = service.list_events(calendar_id,
                                   max_results:   10,
                                   single_events: true,
                                   order_by:      "startTime",
                                   time_min:      DateTime.now.rfc3339)
    puts "Upcoming events:"
    puts "No upcoming events found" if response.items.empty?
    response.items.each do |event|
      start = event.start.date || event.start.date_time
      puts "- #{event.summary} (#{start})"
    end
  end

end
