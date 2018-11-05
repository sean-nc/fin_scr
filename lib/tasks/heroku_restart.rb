desc 'heroku_restart'
task heroku_restart: :environment do
  heroku = PlatformAPI.connect_oauth(ENV['OAUTH_TOKEN'])
  dynos =  heroku.dyno.list(ENV['HEROKU_APP_NAME'])
  heroku.dyno.restart(ENV['HEROKU_APP_NAME'], dynos[0]['name'])
end
