require 'cinch'
require 'date'

module Mendibot

  module Plugins

    class Default
      include Cinch::Plugin

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

        Mendibot::TOPICCREATORS[m.channel] = m.user.nick
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
        
        Mendibot::TOPICCREATORS[m.channel] = nil
        timer(m, nil)

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
        if Mendibot::TOPICCREATORS[m.channel] == m.user.nick
          timer(m, nil)
          timer(m, 900, :ping_user_before_close_topic)
        end
      rescue Exception => e
        m.reply "Failed listen method"
        bot.logger.debug e.message
      end

      def timer(m, timeout, method = nil)
        if method == nil
          Mendibot::THREAD[m.channel].kill
        else
          Mendibot::THREAD[m.channel] = Thread.new do
            sleep timeout
            send(method, m)
          end
        end
      rescue Exception => e
        m.reply "Failed timer method"
        bot.logger.debug e.message
      end
          
      def ping_user_before_close_topic(m)
        m.reply "#{m.user.nick}: Please continue topic discussion or" +
                                 " topic will close in five minutes"

        timer(m, 300, :end_discussion)
      rescue Exception => e
        m.reply "Failed ping method"
        bot.logger.debug e.message
      end

    end

  end
  
end
