=begin rdoc
  This is a series of methods to access theTVDB's api.  Replace API_KEY with your own API_KEY from their site.  It requires the absolutely amazing httparty gem (http://httparty.rubyforge.org/) which really does the heavy lifting for me.  It also requires curb (http://curb.rubyforge.org/) because it's faster and easier to use.
  Author::  Phil Kates (mailto:hawk684@gmail.com)
=end
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'httparty'
require 'cgi'
require 'curb'

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
  base_uri 'www.thetvdb.com'
  format :xml
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
  def self.find_series_by_name(series_name)
    res = get("/api/GetSeries.php?seriesname=" + CGI::escape(series_name))
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
=begin rdoc
  Much more reliable way to get your series information.  Use inspect to determine the different hash values.
=end
  def self.find_series_by_id(series_id)
    get("/api/#{API_KEY}/series/#{series_id}/en.xml")["Data"]["Series"]
  end
=begin rdoc
  This finds a single episode's data when provided with (series_id, season, episode_number)
=end
  def self.find_episode_by_seriesid_and_number(series_id, season, episode_number)
    get("/api/#{API_KEY}/series/#{series_id}/default/#{season}/#{episode_number}/en.xml")["Data"]["Episode"]
  end
=begin rdoc
  Provides an array of hashes of all episodes for a show.  EpisodeNumber is the key for finding the specific episode you want.  Use inspect to find the others.
=end
  def self.find_all_episodes(series_id)
    get("/api/#{API_KEY}/series/#{series_id}/all/en.xml")["Data"]["Episode"]
  end

  def self.find_actor_info_by_seriesid(series_id)
    get("/api/#{API_KEY}/series/#{series_id}/actors.xml")["Actors"]["Actor"]
  end

  def self.get_episode_banner(banner)
    Curl::Easy.perform("http://www.thetvdb.com/banners/#{banner}").body_str
  end
end