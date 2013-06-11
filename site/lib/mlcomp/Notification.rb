# MLcomp: website for automatic and standarized execution of algorithms on datasets.
# Copyright (C) 2010 by Percy Liang and Jake Abernethy
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Utilities for notifying (via email or twitter)
require 'yaml'
require 'rubygems'
require 'twitter' if SITEPARAMS[:twitter_configured]

module Notification
  
  class Tweeter
    
    def initialize
      if SITEPARAMS[:twitter_configured]
        toks = SITEPARAMS[:twitter_tokens]
        oauth = Twitter::OAuth.new(toks[:consumer_token], toks[:consumer_secret])
        oauth.authorize_from_access(toks[:access_token],toks[:access_secret])
        @client = Twitter::Base.new(oauth)
      end
    end
    
    def tweet msg
      if SITEPARAMS[:twitter_configured]
        @client.update(msg)
      end
    end
    
  end
  
  TW = Tweeter.new
  
  def self.notify_tweet_and_email(options)
    self.notify_tweet(options)
    self.notify_email(options)
  end
  
  def self.notify_tweet(options)
    if SITEPARAMS[:twitter_configured]
      message = options[:message] or raise "Missing message"
      message = "[#{Format.datetime(Time.now)}] #{message}" # Need time so we can post two of the same message
      TW.tweet(message)
    end
  end

  # def self.tweet(options)
  #   # DOESN'T WORK: TODO: FIX!
  #   username = options[:username] or raise "Missing username"
  #   password = options[:password] or raise "Missing password"
  #   message = options[:message] or raise "Missing message"
  #   args = ['curl', '-u', "#{username}:#{password}", '-d', "status=#{message}", 'http://twitter.com/statuses/update.xml']
  #   #log "Executing: #{args.inspect}"
  #   systemOrFail(*args)
  # end
  
  def self.notify_email(options)
    if SITEPARAMS[:email_configured]
      log "SENDING EMAIL: #{options.inspect}"
      begin
        Emailer.deliver_general_email(options[:subject], options[:message])
      rescue Exception => e
        log "ERROR SENDING EMAIL: #{e}!"
      end
    end
  end

  def self.notify_event(options)
    options[:subject] ||= "EVENT"
    self.notify_email(options)
  end
  def self.notify_error(options)
    options[:subject] ||= "ERROR"
    self.notify_email(options)
  end
end
