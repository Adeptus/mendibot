require 'cinch'
require 'date'

module Mendibot

  module Plugins

    class Default
      include Cinch::Plugin

      def inicjalize
        @topic_creator = nil        
      end


      match /site/,                   method: :site
      match /start_discussion (.+)$/, method: :start_discussion
      match /end_discussion/,         method: :end_discussion
      match /topic/,                  method: :topic
      listen_to :message

      def listen(m)
        if @topic_creator == m.user.nick
          run_timer(900)
        end
      end

      def run_timer(seconds, option = "ping_user_before_close_topic")
        break if option == "stop"
          
        timer seconds method: :#{option}
      end

      def ping_user_before_close_topic
        Channel("#rmu").send "Please continue topic discussion"
        run_timer(300, "end_topic_by_timeout")
      end

      def end_topic_by_timeout
        Channel("#rmu").send "end_discussion"
      end

      def site(m)
        m.reply "#{m.user.nick}: http://university.rubymendicant.com"
      rescue Exception => e
        bot.logger.debug e.message
      end

      def start_discussion(m, topic)
        Mendibot::TOPICS[m.channel] = topic

        @topic_creator = m.user.nick
        run_timer(900)

        m.reply "The topic under discussion is now '#{topic}'"
      rescue Exception => e
        m.reply "Failed to start discussion"
        bot.logger.debug e.message
      end

      def end_discussion(m)
        topic = Mendibot::TOPICS[m.channel]
        Mendibot::TOPICS[m.channel] = nil

        @topic_creator = nil
        run_timer(nil, "stop")

        if topic
          m.reply "The topic about '#{topic}' has now ended"
        else
          m.reply "There is no topic under discussion at the moment"
        end
      rescue Exception => e
        m.reply "Failed to end discussion"
        bot.logger.debug e.message
      end

      def topic(m)
        topic = Mendibot::TOPICS[m.channel]

        if topic
          m.reply "The current topic under discussion is '#{topic}'"
        else
          m.reply "There is no topic under discussion at the moment"
        end
      rescue Exception => e
        m.reply "Failed to retreive topic"
        bot.logger.debug e.message
      end

    end

  end

end
