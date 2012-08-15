# -*- encoding: utf-8 -*-

require 'tuppari/gyoji_server_spec'

module Tuppari
  class Application

    attr_accessor :gyoji_base_url, :name, :id, :access_key_id, :access_secret_key

    def initialize(params)
      @gyoji_base_url = GyojiServerSpec::DEFAULT_GYOJI_BASE_URL
      @name = params[:name]
      @id = params[:id]
      @access_key_id = params[:access_key_id]
      @access_secret_key = params[:access_secret_key]
    end

  end
end