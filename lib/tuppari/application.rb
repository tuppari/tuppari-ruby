# -*- encoding: utf-8 -*-

module Tuppari
  class Application

    attr_accessor :name, :id, :access_key_id, :access_secret_key

    def initialize(params)
      @name = params[:name]
      @id = params[:id]
      @access_key_id = params[:access_key_id]
      @access_secret_key = params[:access_secret_key]
    end

  end
end