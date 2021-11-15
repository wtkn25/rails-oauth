require "google/apis/calendar_v3"
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
    authorize
  end

  def authorize
    client_id = Google::Auth::ClientId.from_file CLIENT_SECRET_PATH
    logger.debug(client_id.id)
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "atrastar72@gmail.com"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      code = session[:code]
      url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
      logger.debug(url)
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: REDIRECT_URI
      )
    end
    credentials
  end

  def callback
    session[:code] = params[:code]
    logger.debug(session[:code])
    calendar = Google::Apis::CalendarV3::CalendarService.new
    calendar.client_options.application_name = APPLICATION_NAME
    calendar.authorization = authorize
    fetchEvents(calendar)
    redirect_to action: :index
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
