require 'cinch'
require 'json'
require 'time'

module Mendibot
  extend self

  TOPICS         = {}
  TOPIC_CREATORS = {}
  THREAD         = {}

  def run(options = {})
    opts = parse_options(options)

    bot = Cinch::Bot.new do
      configure do |c|
        c.server          = opts[:server]
        c.port            = opts[:port]
        c.nick            = opts[:nick]
        c.password        = opts[:password] if opts[:password]
        c.channels        = opts[:channels]
        c.plugins.plugins = opts[:plugins]
      end

      on :channel do |m|
        begin
          msg = { 
            :channel       => m.channel, 
            :handle        => m.user, 
            :body          => m.message.encode("UTF-8", :invalid => :replace, :undef => :replace), 
            :recorded_at   => DateTime.now,
            :topic         => Mendibot::TOPICS[m.channel],
            :topic_creator => Mendibot::TOPIC_CREATORS[m.channel]
          }.to_json

          Mendibot::THREAD[m.channel]
          Mendibot::Config::SERVICE["/chat/messages.json"].post(:message => msg)
        rescue Exception => e
          bot.logger.debug e.message
        end
      end
    end

    bot.start
  end

  private

  def parse_options(options = {})
    { server:   Mendibot::Config::SERVER,
      port:     Mendibot::Config::PORT,
      nick:     Mendibot::Config::NICK,
      channels: Mendibot::Config::CHANNELS,
      plugins:  Mendibot::Config::PLUGINS,
      password: Mendibot::Config::PASSWORD
    }.merge(options)
  end

end
