#!/usr/bin/env ruby
# Cabrillo - Amateur Radio Log Library
#
# This library handles the parsing and generation of the Cabrillo ham radio
# logging format, commonly used by the ARRL for contesting. 
#
# Written by Ricky Elrod (github: @CodeBlock) and released an MIT license.
# https://www.github.com/CodeBlock/cabrillo-gem

$: << File.dirname(__FILE__)
require "contest_validators"
require 'date'
require 'time'

# TODO: Split these into their own gem because they are handy. :-)
class String
  def to_hz
    freq_split = self.split('.')
    hertz = freq_split[0].to_i * 1000000 # MHz

    # Handle KHz
    if not freq_split[1].nil?
      freq_split[1] += '0' while freq_split[1].length < 3
      hertz += freq_split[1].to_i * 1000 # KHz
    end

    # Handle Hz
    if not freq_split[2].nil?
      freq_split[2] += '0' while freq_split[2].length < 3
      hertz += freq_split[2].to_i # Hz
    end
    hertz
  end
end

class Integer
  def to_mhz
    self.to_s.reverse.gsub(/(.{3})(?=.)/, '\1.\2').reverse
  end
end
# END TODO

class InvalidDataError < StandardError; end

HEADER_META = {
  'START-OF-LOG' => { :data_key => :version },
  'CREATED-BY' => { :data_key => :created_by },
  'CONTEST' => { :data_key => :contest, :validators => ContestValidators::CONTEST },
  'CALLSIGN' => { :data_key => :callsign },
  'CATEGORY-ASSISTED' => { :data_key => :category_assisted, :validators => ContestValidators::CATEGORY_ASSISTED },
  'CATEGORY-BAND' => { :data_key => :category_band, :validators => ContestValidators::CATEGORY_BAND },
  'CATEGORY-MODE' => { :data_key => :category_mode, :validators => ContestValidators::CATEGORY_MODE },
  'CATEGORY-OPERATOR' => { :data_key => :category_operator, :validators => ContestValidators::CATEGORY_OPERATOR },
  'CATEGORY-POWER' => { :data_key => :category_power, :validators => ContestValidators::CATEGORY_POWER },
  'CATEGORY-STATION' => { :data_key => :category_station, :validators => ContestValidators::CATEGORY_STATION },
  'CATEGORY-TIME' => { :data_key => :category_time, :validators => ContestValidators::CATEGORY_TIME },
  'CATEGORY-TRANSMITTER' => { :data_key => :category_transmitter, :validators => ContestValidators::CATEGORY_TRANSMITTER },
  'CATEGORY-OVERLAY' => { :data_key => :category_overlay, :validators => ContestValidators::CATEGORY_OVERLAY },
  'CLAIMED-SCORE' => { :data_key => :claimed_score, :validators => ContestValidators::CLAIMED_SCORE },
  'CLUB' => { :data_key => :club },
  'EMAIL' => { :data_key => :email },
  'NAME' => { :data_key => :name, :validators => ContestValidators::NAME },
  'LOCATION' => { :data_key => :location },
  'OPERATORS' => { :data_key => :operators,  :validators => ContestValidators::OPERATORS, multi_line: true },
  'ADDRESS' => { :data_key => :address, :validators => ContestValidators::ADDRESS, multi_line: true },
  'ADDRESS-CITY' => { :data_key => :address_city },
  'ADDRESS-STATE-PROVINCE' => { :data_key => :address_state_province },
  'ADDRESS-POSTALCODE' => { :data_key => :address_postalcode },
  'ADDRESS-COUNTRY' => { :data_key => :address_country },
  'SOAPBOX' => { :data_key => :soapbox,  :validators => ContestValidators::SOAPBOX, multi_line: true },
  'OFFTIME' => { :data_key => :offtime }
}

class Cabrillo
  @raise_on_invalid_data = true

  CABRILLO_VERSION = '3.0' # The current version of the spec, our default.
  FREQUENCY_PAD = 5 # The reserved length for qso frequency
  MODE_PAD = 2 # The reserved length for qso mode
  CALLSIGN_PAD = 13 # The reserved length for callsign in qso
  EXCHANGE_PAD = 6 # The reserved length for exchange in qso
  RST_PAD = 3 # The reserved length for rst in qso

  # Public: Creates an instance of Cabrillo from a Hash of log data
  #
  # options - A Hash which contains data from a cabrillo log
  #
  # Returns an instance of Cabrillo.
  def initialize(options = {})
    # Let all the given entries automagically become instance variables.
    options.each do |key, value|
      instance_variable_set("@#{key}", value)
      this = class << self; self; end
      this.class_eval { attr_accessor key }
    end

    # Defaults and sanity checks can go here if they need to.
    @version = options[:version] || CABRILLO_VERSION
  end

  attr_accessor :callsign
  attr_accessor :version
  attr_accessor :category_assisted
  attr_accessor :category_band
  attr_accessor :category_mode
  attr_accessor :category_operator
  attr_accessor :category_power
  attr_accessor :category_station
  attr_accessor :category_time
  attr_accessor :category_transmitter
  attr_accessor :category_overlay
  attr_accessor :claimed_score
  attr_accessor :club
  attr_accessor :contest
  attr_accessor :created_by
  attr_accessor :email
  attr_accessor :name
  attr_accessor :location
  attr_accessor :address_city
  attr_accessor :address_state_province
  attr_accessor :address_postalcode
  attr_accessor :address_country
  attr_accessor :address
  attr_accessor :soapbox
  attr_accessor :operators
  attr_accessor :offtime
  attr_accessor :qsos

  # Public: Return the collected data as a Hash.
  #
  # Returns the data that was parsed (or given) as a Hash.
  def to_hash
    h = {}
    self.instance_variables.each do |variable|
      h[variable[1..-1].to_sym] = self.instance_variable_get(variable)
    end
    h
  end

  class << self
    attr_accessor :raise_on_invalid_data

    def write_file(cabrillo_info, path = nil)
      callsign = cabrillo_info.callsign
      if callsign.to_s.empty?
        raise InvalidDataError, "Callsign not provided (required for filename)."
      end

      filename = "#{callsign}.log"
      filename = File.join(path, filename) if path

      File.open(filename, "w") do |f|
        write(cabrillo_info, f)
      end
    end

    def write(cabrillo_info, io)
      HEADER_META.each do |line_key, meta|
        data_value = cabrillo_info.send(meta[:data_key])
        if meta[:multi_line]
          data_value.each do |s_line|
            write_basic_line(io, line_key, s_line, meta[:validators])
          end
        else
          write_basic_line(io, line_key, data_value, meta[:validators])
        end
      end
      cabrillo_info.qsos.each do |qso|
        write_qso(io, qso, cabrillo_info.contest)
      end
      io.puts "END-OF-LOG:"
    end

    # Public: Parses a log (a string containing newlines) into a Cabrillo
    #         instance.
    #
    # log_contents - A String containing the entire to parse.
    #
    # TODO: Use a parsing lib like Treetop maybe?
    #
    # Returns an instance of Cabrillo.
    def parse(log_contents)
      cabrillo_info = Hash.new { |h,k| h[k] = [] }
      log_contents.lines.each do |line|
        line = line.strip

        # Ignore comments. (See README.md for info.)
        next if line.start_with? '#' or line.start_with? '//' or line.empty?

        # If we already parsed in a contest then we're good. If not, we don't
        # know what to parse as, so skip.
        if line.start_with? "QSO: "
          if cabrillo_info[:contest]
            cabrillo_info[:qsos] << parse_qso(line, cabrillo_info[:contest])
          end
        else
          line_key, line_value = line.split(/:\s+/, 2)
          meta = HEADER_META[line_key]
          next unless meta
          data_key, validators = meta[:data_key], meta[:validators]
          line_value = split_basic_line(line_key, line_value, validators)
          if line_value
           if meta[:multi_line]
            cabrillo_info[data_key] << line_value unless line_value.empty?
            else
              cabrillo_info[data_key] = line_value
            end
          end
        end
      end
      Cabrillo.new(cabrillo_info)
    end

    # Public: A wrapper to Cabrillo.parse() to parse a log from a file.
    #
    # file_path - The path to the logfile to parse.
    #
    # Returns what Cabrillo.parse() returns, an instance of Cabrillo.
    def parse_file(file_path)
      Cabrillo.parse(IO.read(file_path))
    end

    private

    # Private: Parses a specific line of the log, in most cases.
    #
    # line     - The String of log line to parse.
    # key      - The key to look for in the line.
    # hash_key - The key to use in the resulting Hash.
    # validators - The optional collection of validators to use.
    #
    # Throws an Exception if validators are given but the data does not match
    #   one of them.
    #
    # Returns a Hash of {:hash_key => value_from_parsed_line} or nil if the key
    #   wasn't found.
    def split_basic_line(line_key, line_value, validators = nil)
      line_value.strip! if line_value
      valid = validate_line_value(line_value, validators)
      if valid || !@raise_on_invalid_data
        line_value
      elsif validators && !validators.empty? && @raise_on_invalid_data
        raise InvalidDataError, "Invalid value: `#{line_value}` given for key `#{line_key}`."
      else
        nil
      end
    end

    # Private: Writes line value of log and validates with supplied validators.
    #
    # io - The IO stream instance being written
    # line_key - The String containing the log file line key
    # data_key - The String containing the instance data key
    # validators - The collection of validators to use.
    #
    # Returns a Boolean representing the validation result.
    def write_basic_line(io, line_key, line_value, validators)
      return if !line_value || line_value.empty?
      line_value.strip!
      valid = validate_line_value(line_value, validators)
      if valid || !@raise_on_invalid_data
        io.puts "#{line_key}: #{line_value}"
      elsif validators && !validators.empty? && @raise_on_invalid_data
        raise InvalidDataError, "Invalid value: `#{line_value}` given for key `#{line_key}`"
      end
    end

    # Private: Validates the line value of log with supplied validators.
    #
    # line_value - The String containing the log file line value
    # validators - The collection of validators to use.
    #
    # Returns a Boolean representing the validation result.
    def validate_line_value(line_value, validators)
      okay = true
      if validators && !validators.empty?
        okay = false
        validators.each do |v|
          okay = true and break if v.class.to_s == 'Regexp' and line_value =~ v
          okay = true and break if v.class.to_s == 'String' and line_value == v
          okay = true and break if v.respond_to?(:call) and v.call(line_value)
        end
      end
      okay
    end

    # Private: Left pads the QSO value to appropriate length.
    #
    # key - A Symbol hash key for the particular qso value
    # qso - A Hash containing qso information
    # pad - A Integer representing expected length of value
    def qso_value(key, qso, pad)
      qso[key].ljust(pad, ' ')
    end

    # Private: Parses a QSO: line based on the contest type.
    #
    # io - The IO stream instance being written
    # qso_line - A Hash containing the qso details
    # contest  - A String representing the name of the contest that we are parsing.
    def write_qso(io, qso, contest)
      if @raise_on_invalid_data
        raise InvalidDataError, "Invalid contest: #{contest}" unless ContestValidators::CONTEST.include? contest
      end

      qso_values = []
      qso_values << qso_value(:frequency, qso, FREQUENCY_PAD)
      qso_values << qso_value(:mode, qso, MODE_PAD)

      time = qso[:time]
      raise InvalidDataError, "Invalid qso time" unless time && @raise_on_invalid_data
      qso_values << time.strftime('%Y-%m-%d')
      qso_values << time.strftime('%H%M')

      exchange = qso[:exchange]
      raise InvalidDataError, "Invalid qso exchange" unless exchange && @raise_on_invalid_data

      sent, received = exchange[:sent], exchange[:received]

      raise InvalidDataError, "Invalid sent exchange" unless sent && @raise_on_invalid_data
      raise InvalidDataError, "Invalid receive exchange" unless received && @raise_on_invalid_data

      raise InvalidDataError, "Invalid sent callsign: #{sent[:callsign]}" unless sent[:callsign] && @raise_on_invalid_data
      qso_values << qso_value(:callsign, sent, CALLSIGN_PAD)

      raise InvalidDataError, "Invalid recv callsign: #{received[:callsign]}" unless received[:callsign] && @raise_on_invalid_data

      # extract and concat the rest of the exchange
      case contest
      when 'CQ-160-CW', 'CQ-160-SSB', 'CQ-WPX-RTTY', 'CQ-WPX-CW', 'CQ-WPX-SSB', 'CQ-WW-RTTY', 'CQ-WW-CW', 'CQ-WW-SSB', 'ARRL-DX-CW', 'ARRL-DX-SSB', 'IARU-HF', 'ARRL-10', 'ARRL-160', 'JIDX-CW', 'JIDX-SSB', 'STEW-PERRY', 'OCEANIA-XD-CW', 'OCEANIA-DX-SSB', 'AP-SPRINT', 'NEQP', 'ARRL-FIELD-DAY'
        qso_values << qso_value(:rst, sent, RST_PAD)
        qso_values << qso_value(:exchange, sent, EXCHANGE_PAD)
        qso_values << qso_value(:callsign, received, CALLSIGN_PAD)
        qso_values << qso_value(:rst, received, RST_PAD)
        qso_values << qso_value(:exchange, received, EXCHANGE_PAD)
        qso_values << received[:transmitter_id]
      when 'ARRL-SS-CW', 'ARRL-SS-SSB'
        qso_values << sent.values_at(:serial_number, :precedence, :check, :arrl_section)
        qso_values << received.values_at(:serial_number, :precedence, :check, :arrl_section)
      end

      # combine qso components
      qso_line = qso_values.compact.join(' ').strip
      io.puts "QSO: #{qso_line}"
    end

    # Private: Parses a QSO: line based on the contest type.
    #
    # qso_line - The String containing the line of the logfile that we are
    #   parsing. Starts with "QSO:"
    # contest  - A String, the name of the contest that we are parsing.
    #
    # Returns a Hash containing the parsed result.
    def parse_qso(qso_line, contest)
      if @raise_on_invalid_data
        raise InvalidDataError, "Invalid contest: #{contest}" unless ContestValidators::CONTEST.include? contest
        raise InvalidDataError, "Line does not start with 'QSO: '" unless qso_line.start_with? "QSO: "
      end
      qso_line.gsub!(/^QSO: /, "")

      # Basic structure
      qso = {
        :exchange => {
          :sent     => {},
          :received => {}
        }
      }

      # In any and all cases, the first fields are: frequency, mode, date, time.
      # Store the exchange/everything else into an array (using splat) for
      #   later.
      qso[:frequency], qso[:mode], date, time, *exchange = qso_line.split

      # Parse the date and time into a Time object.
      qso[:time] = Time.parse(DateTime.strptime("#{date} #{time}", '%Y-%m-%d %H%M').to_s)

      # Transmitted callsign always comes first.
      qso[:exchange][:sent][:callsign] = exchange.shift

      # Parse the rest of the exchange
      case contest
      when 'CQ-160-CW', 'CQ-160-SSB', 'CQ-WPX-RTTY', 'CQ-WPX-CW', 'CQ-WPX-SSB', 'CQ-WW-RTTY', 'CQ-WW-CW', 'CQ-WW-SSB', 'ARRL-DX-CW', 'ARRL-DX-SSB', 'IARU-HF', 'ARRL-10', 'ARRL-160', 'JIDX-CW', 'JIDX-SSB', 'STEW-PERRY', 'OCEANIA-XD-CW', 'OCEANIA-DX-SSB', 'AP-SPRINT', 'NEQP', 'ARRL-FIELD-DAY'
        qso[:exchange][:sent][:rst] = exchange.shift
        qso[:exchange][:sent][:exchange] = exchange.shift

        qso[:exchange][:received][:callsign] = exchange.shift
        qso[:exchange][:received][:rst] = exchange.shift
        qso[:exchange][:received][:exchange] = exchange.shift
        qso[:exchange][:received][:transmitter_id] = exchange.shift
      when 'ARRL-SS-CW', 'ARRL-SS-SSB'
        qso[:exchange][:sent][:serial_number] = exchange.shift
        qso[:exchange][:sent][:precedence] = exchange.shift
        qso[:exchange][:sent][:check] = exchange.shift
        qso[:exchange][:sent][:arrl_section] = exchange.shift

        qso[:exchange][:received][:callsign] = exchange.shift
        qso[:exchange][:received][:serial_number] = exchange.shift
        qso[:exchange][:received][:precedence] = exchange.shift
        qso[:exchange][:received][:check] = exchange.shift
        qso[:exchange][:received][:arrl_section] = exchange.shift
      end

      qso
    end

  end
end
