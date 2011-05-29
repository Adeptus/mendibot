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
      listen_to                               :message


      def site(m)
        m.reply "#{m.user.nick}: http://university.rubymendicant.com"
      rescue Exception => e
        bot.logger.debug e.message
      end

      def start_discussion(m, topic)
        Mendibot::TOPICS[m.channel] = topic

        @topic_creator = m.user.nick
        timer(m, 900, "ping_user_before_close_topic")

        m.reply "The topic under discussion is now '#{topic}'"
      rescue Exception => e
        m.reply "Failed to start discussion"
        bot.logger.debug e.message
      end

      def end_discussion(m)
        topic = Mendibot::TOPICS[m.channel]
        Mendibot::TOPICS[m.channel] = nil

        if topic
          m.reply "The topic about '#{topic}' has now ended"
        else
          m.reply "There is no topic under discussion at the moment"
        end
        
        @topic_creator = nil
        timer(m, nil, "stop")

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

      def listen(m)
        if @topic_creator == m.user.nick
          timer(m, nil, "stop")
          timer(m, 900, "ping_user_before_close_topic")
        end
      end

      def timer(m, seconds, option = nil)
        if option == "ping_user_before_close_topic"
          @thread = Thread.new do
            sleep seconds
            ping_user_before_close_topic(m)
          end
        
        elsif option == "end_topic_by_timeout"
          @thread = Thread.new do
            sleep seconds
            end_discussion(m)
          end

        else
          @thread.kill
        end
      end
          
      def ping_user_before_close_topic(m)
        m.reply "#{m.user.nick}: Please continue topic discussion or" +
                                 " topic will close in five minutes"

        timer(m, 300, "end_topic_by_timeout")
      end

    end

  end

end
