# -*- encoding: utf-8 -*-

require 'logger'
require 'json'
require 'rest_client'
require 'time'
require 'tuppari/auth'
require 'tuppari/application'
require 'tuppari/authentication_error'
require 'tuppari/client'
require 'tuppari/client_error'
require 'tuppari/server_url'

# Tuppari API client
#
# `Tuppari` is an experimental implementation of unbreakable message broadcasting system
# using WebSocket and Amazon Web Services.
#
# see also https://github.com/hakobera/tuppari-servers/wiki/API-Reference
#
module Tuppari

  # Creates a new Tuppari::Client instance.
  def self.new(params = {})
    Tuppari::Client.new(params)
  end

  def self.create_account(account_name, password)
    new().create_account(account_name, password)
  end

  def self.login(account_name, password)
    new().login(account_name, password)
  end

  def self.publish_message(params)
    Tuppari.new().publish_message(params)
  end

end

