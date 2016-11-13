require File.join(File.dirname(__FILE__), '..', 'lib', 'cabrillo')
require 'tmpdir'

describe Cabrillo do

  let (:valid_file)  { File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo') }
  let (:log) { Cabrillo.parse_file(valid_file) }

  before :all do
    Cabrillo.raise_on_invalid_data = true
  end

  context 'write_file' do

    let (:filename) { "#{log.callsign}.log" }
    let (:path) { Dir.tmpdir }

    context 'with path provided' do

      it "should create file using callsign provided in path" do
        Cabrillo.write_file(log, path)
        File.exists?(File.join(path, filename)).should == true
      end

    end

    context 'with no path provided' do

      it "should create file using callsign provided" do
        Cabrillo.write_file(log)
        File.exists?(filename).should == true
      end

    end

    context 'with no callsign provided' do

      it "should raise an error" do
        log.callsign = nil
        expect {
          Cabrillo.write_file(log, path)
        }.to raise_error(InvalidDataError)
      end

    end

  end

  context "validate lines written" do

    before :all do
      io = StringIO.new
      Cabrillo.write(log, io)
      @lines = io.string.lines.map(&:chomp).to_set
    end

    it "should write START-OF-LOG line" do
      @lines.should include "START-OF-LOG: 3.0"
    end

    it "should write CREATED-BY line" do
      @lines.should include "CREATED-BY: WavePower 1.0"
    end

    it "should write CONTEST line" do
      @lines.should include "CONTEST: NEQP"
    end

    it "should write CALLSIGN line" do
      @lines.should include "CALLSIGN: W8UPD"
    end

    it "should write CATEGORY-ASSISTED line" do
      @lines.should include "CATEGORY-ASSISTED: NON-ASSISTED"
    end

    it "should write CATEGORY-BAND line" do
      @lines.should include "CATEGORY-BAND: ALL"
    end

    it "should write CATEGORY-MODE line" do
      @lines.should include "CATEGORY-MODE: SSB"
    end

    it "should write CATEGORY-OPERATOR line" do
      @lines.should include "CATEGORY-OPERATOR: SINGLE-OP"
    end

    it "should write CATEGORY-POWER line" do
      @lines.should include "CATEGORY-POWER: LOW"
    end

    it "should write CATEGORY-STATION line" do
      @lines.should include "CATEGORY-STATION: FIXED"
    end

    it "should write CATEGORY-TIME line" do
      @lines.should include "CATEGORY-TIME: 24-HOURS"
    end

    it "should write CATEGORY-TRANSMITTER line" do
      @lines.should include "CATEGORY-TRANSMITTER: ONE"
    end

    it "should write CATEGORY-OVERLAY line" do
      @lines.should include "CATEGORY-OVERLAY: ROOKIE"
    end

    it "should write CLAIMED-SCORE line" do
      @lines.should include "CLAIMED-SCORE: 1234"
    end

    it "should write CLUB line" do
      @lines.should include "CLUB: University of Akron"
    end

    it "should write EMAIL line" do
      @lines.should include "EMAIL: test@test.com"
    end

    it "should write NAME line" do
      @lines.should include "NAME: Ricky Elrod"
    end

    it "should write LOCATION line" do
      @lines.should include "LOCATION: OH"
    end

    it "should write both OPERATORS lines" do
      @lines.should include "OPERATORS: N8SQL"
    end

    it "should write ADDRESS line" do
      @lines.should include "ADDRESS: 501 Zook Hall"
    end

    it "should write ADDRESS-CITY line" do
      @lines.should include "ADDRESS-CITY: Akron"
    end

    it "should write ADDRESS-STATE-PROVINCE line" do
      @lines.should include "ADDRESS-STATE-PROVINCE: OH"
    end

    it "should write ADDRESS-POSTALCODE line" do
      @lines.should include "ADDRESS-POSTALCODE: 44325"
    end

    it "should write ADDRESS-COUNTRY line" do
      @lines.should include "ADDRESS-COUNTRY: United States"
    end

    it "should write both SOAPBOX lines" do
      @lines.should include "SOAPBOX: This is just a test log."
      @lines.should include "SOAPBOX: If parsed successfully, N8SQL will be happy."
    end

    it "should write both OFFTIME lines" do
      @lines.should include "OFFTIME: 2012-02-11 0000 2012-02-11 2032"
    end

    it "should write qso lines" do
      @lines.should include "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  001    KG4SGP        59  HARCT"
      @lines.should include "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  002    KD8LCV        59  NHNCT"
      @lines.should include "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  003    W1AW          59  SOMME"
    end

    it "should have end of log line" do
      @lines.to_a.last.should ==  "END-OF-LOG:"
    end

  end
end
