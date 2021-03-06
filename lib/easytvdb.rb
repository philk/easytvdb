=begin rdoc
  This is a series of methods to access theTVDB's api.  Replace @api_key with your own @api_key from their site.  It requires the absolutely amazing httparty gem (http://httparty.rubyforge.org/) which really does the heavy lifting for me.  It also requires curb (http://curb.rubyforge.org/) because it's faster and easier to use.
  Author::  Phil Kates (mailto:hawk684@gmail.com)
=end
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'httparty'
require 'cgi'
require 'curb'

module Easytvdb
  VERSION = '0.0.1'
  class TVDBServer
    include HTTParty
    format :xml
    attr_accessor :mirror
    def initialize
    end
  end
  
=begin rdoc
==Usage
Probably overly simplistic examples here, but hey, I'm new, gimme a break ;)

    series = TVDB.find_series_by_name("Battlestar Galactica (2003)")
    puts series["SeriesName"]
    puts series["Overview"]
    puts series["id"]

    episode = TVDB.find_episode_by_seriesid_and_number(series["id"], 1, 1)

    puts episode["Overview"]

    episodes = TVDB.find_all_episodes(series["id"])
    episodes.each do |episode|
      puts episode["Overview"]
    end
=end
  class TVDB
    include HTTParty
    format :xml
    attr_accessor :mirror, :api_key
    def initialize(api_key)
    	@api_key = api_key
      begin
        # The code in the comment below should work, but it doesn't.  I get a ParseException from REXML, but REXML can process it just fine normally
        # @mirror = self.class.get("www.thetvdb.com/api/#{@api_key}/mirrors.xml")["Mirrors"]["Mirror"]
        doc = REXML::Document.new(Curl::Easy.perform("www.thetvdb.com/api/#{@api_key}/mirrors.xml").body_str)
        total_mirrors = doc.elements["Mirrors"].get_elements("Mirror").size - 1
        if total_mirrors == 1
          @mirror = doc.elements["Mirrors"].get_elements("Mirror/mirrorpath")[0].text
        else
          @mirror = doc.elements["Mirrors"].get_elements("Mirror/mirrorpath")[rand(total_mirrors) - 1].text
        end
      rescue REXML::ParseException => e
        puts e
      end
      self.class.base_uri @mirror
    end
=begin rdoc
This function is highly likely to return more than one result.  It returns and Array of Hash(es) whether it returns one result or 100.  This seemed like a good way to simplify dealing with the results since you always know what you're going to get.  You're on your own as to how you deal with this however, since it's interface dependant.
==Example
    series = TVDB.find_series_by_name("Battlestar Galactica")
    if series.size != 1
      counter = 0
      series.each do |show|
        puts "#{show["SeriesName"]}\t\t#{show["FirstAired"]}\t\t#{counter}"
        counter += 1
      end
      puts "Type the number of the show"
      selection = gets.to_i
      series = TVDB.find_series_by_id(series[selection]["id"])
      end
=end
    def find_series_by_name(series_name)
      res = self.class.get("/api/GetSeries.php?seriesname=" + CGI::escape(series_name.to_s))
      if res["Data"].to_s =~ /.*connection to localhost.*/
        raise "TVDB search api is currently down."
      else
        res = res["Data"]["Series"]
      end
      if res.is_a?(Hash)
        return [res]
      elsif res.is_a?(Array)
        return res
      else
        raise "Unexpected Data Type Returned #{res.class}"
      end
    end
#  This is a more reliable way to get your series information (if you happen to know the series ID).  Use inspect to determine the different hash values.
    def find_series_by_id(series_id)
      self.class.get("/api/#{@api_key}/series/#{series_id}/en.xml")["Data"]["Series"]
    end
#  This finds a single episode's data when provided with (series_id, season, episode_number)
    def find_episode_by_seriesid_and_number(series_id, season, episode_number)
      get("/api/#{@api_key}/series/#{series_id}/default/#{season}/#{episode_number}/en.xml")["Data"]["Episode"]
    end
#  Provides an array of hashes of all episodes for a show.  EpisodeNumber is the key for finding the specific episode you want.  Use inspect to find the others.
    def find_all_episodes(series_id)
      get("/api/#{@api_key}/series/#{series_id}/all/en.xml")["Data"]["Episode"]
    end

    def find_actor_info_by_seriesid(series_id)
      get("/api/#{@api_key}/series/#{series_id}/actors.xml")["Actors"]["Actor"]
    end
# Returns a file handle containing the episode banner file.
    def get_episode_banner(banner)
      Curl::Easy.perform("http://www.thetvdb.com/banners/#{banner}").body_str
    end
    
# Provides and Array of banners to choose from.
    def get_series_banners(series_id)
      get("/api/#{@api_key}/series/#{series_id}/banners.xml")["Banners"]["Banner"]
    end
  end
  
end
