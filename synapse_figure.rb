#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'

get '/' do
  #File.read("plot.html")
  "hello world!"
end

get '/hi' do
  "hi there"
end
