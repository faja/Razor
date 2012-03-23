# EMC Confidential Information, protected under EMC Bilateral Non-Disclosure Agreement.
# Copyright © 2012 EMC Corporation, All Rights Reserved

require "json"
require "yaml"

# Root ProjectRazor namespace
# @author Nicholas Weaver
module ProjectRazor
  module Slice
    # ProjectRazor Slice Model
    # @author Nicholas Weaver
    class Model < ProjectRazor::Slice::Base
      include(ProjectRazor::Logging)
      # Initializes ProjectRazor::Slice::Model including #slice_commands, #slice_commands_help, & #slice_name
      # @param [Array] args
      def initialize(args)
        super(args)
        # Here we create a hash of the command string to the method it corresponds to for routing.
        @slice_commands = {:default => "get_model",
                           :get => "get_model",
                           :add => "add_model",
                           :remove => "remove_model"}
        @slice_commands_help = {:get => "imagesvc model ".red + "{get [config|type]}".blue,
                                :default => "imagesvc model ".red + "{get [config|type]}".blue,
                                :add_cli => "imagesvc model add".red + " (model_type) (model config name)".blue,
                                :add_web => "imagesvc model add".red + " (model_type) (json string)".blue}
        @slice_name = "Model"
      end

      def get_model
        @command = :get
        @arg01 =  @command_array.shift

        case @arg01
          when "config"
            get_model_config
          when "type"
            get_model_types
          when "help"
            slice_error("Help", false)
          else
            get_model_config
        end
      end


      def get_model_config
        print_model_configs get_object("model_config", :model)
      end

      def get_model_types
        policy_rules = ProjectRazor::PolicyRules.instance
        print_model_types policy_rules.get_model_types
      end

      def add_model
        if @web_command
          # REST call
          add_model_web
        else
          # CLI call
          add_model_cli
        end
      end

      def add_model_cli
        @command = :add_cli
        @model_name =  @command_array.shift
        policy_rules = ProjectRazor::PolicyRules.instance

        unless @model_name != nil
          slice_error("ModelTypeMissing")
          return
        end


        new_model = policy_rules.is_model_type?(@model_name)
        unless new_model
          slice_error("ModelTypeNotFound")
          return
        end

        @model_config_name =  @command_array.shift
        unless @model_config_name != nil
          slice_error("ModelNameMissing")
          return
        end

        if new_model.req_metadata_hash != {}
          cli_interactive_metadata(new_model)
        else

        end



      end


      def cli_interactive_metadata(new_model)
        req_metadata_hash = new_model.req_metadata_hash
        #@req_metadata_hash = {
        #    "@hostname" => {:default => "hostname.example.org", :validation => '\S', :required => true}
        #}
        puts "\n--- Building Model Config(#{@model_name}): #{@model_config_name}\n".yellow
        req_metadata_hash.each_key do
        |md|
          flag = false

          while !flag

            print "\nPlease enter " + "#{req_metadata_hash[md][:description]}".yellow.bold
            print " (example: " + "#{req_metadata_hash[md][:example]}".yellow + ") \n"
            if req_metadata_hash[md][:default] != ""
              puts "default: " + "#{req_metadata_hash[md][:default]}".yellow
            end
            if req_metadata_hash[md][:required]
              puts quit_option
            else
              puts skip_quit_option
            end
            print " > "
            response = gets.strip


            case response

              when "SKIP"
                if req_metadata_hash[md][:required]
                  puts "Cannot skip, value required".red
                else
                  flag = true
                end

              when "QUIT"
                slice_error("AddCanceled")
                return

              when ""
                if req_metadata_hash[md][:default] != ""
                  set_metadata_value(new_model, md, req_metadata_hash[md][:default])
                else
                  puts "no default value, must enter something".red
                end

              else
                set_metadata_value(new_model, md, response)

            end

          end

        end
        nil

      end

      def set_metadata_value(new_model, md, value)
        puts value
        new_model.instance_variable_set(md.to_sym, value)
        puts new_model.inspect
      end

      def skip_quit_option
        "(" + "SKIP".white + " to skip, " + "QUIT".red + " to cancel)"
      end

      def quit_option
        "(" + "QUIT".red + " to cancel)"
      end

      def add_model_web
        @command = :add_web
        @model_type =  @command_array.shift
        @values_json_string =  @command_array.shift
        slice_error("NotImplemented")
      end




    end
  end
end