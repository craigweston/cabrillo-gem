require File.join(File.dirname(__FILE__), '..', 'lib', 'cabrillo')

describe Cabrillo do
  before(:each) { Cabrillo.raise_on_invalid_data = true }

  context "validate lines written" do

    before :all do
      valid_file = File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo')

      file_lines = []
      File.open(valid_file).each_line do |line|
        next if line.start_with? '#'
        file_lines << line
      end

      io = StringIO.new
      log = Cabrillo.parse_file(valid_file)
      Cabrillo.write(log, io)

      @lines = io.string.lines.map(&:chomp)
    end

    context "validate header lines written" do

      it "should write START-OF-LOG line" do
        @lines.shift.should == "START-OF-LOG: 3.0"
      end

      it "should write CREATED-BY line" do
        @lines.shift.should == "CREATED-BY: WavePower 1.0"
      end

      it "should write CONTEST line" do
        @lines.shift.should == "CONTEST: NEQP"
      end

      it "should write CALLSIGN line" do
        @lines.shift.should == "CALLSIGN: W8UPD"
      end

      it "should write CATEGORY-ASSISTED line" do
        @lines.shift.should == "CATEGORY-ASSISTED: NON-ASSISTED"
      end

      it "should write CATEGORY-BAND line" do
        @lines.shift.should == "CATEGORY-BAND: ALL"
      end

      it "should write CATEGORY-MODE line" do
        @lines.shift.should == "CATEGORY-MODE: SSB"
      end

      it "should write CATEGORY-OPERATOR line" do
        @lines.shift.should == "CATEGORY-OPERATOR: SINGLE-OP"
      end

      it "should write CATEGORY-POWER line" do
        @lines.shift.should == "CATEGORY-POWER: LOW"
      end

      it "should write CATEGORY-STATION line" do
        @lines.shift.should == "CATEGORY-STATION: FIXED"
      end

      it "should write CATEGORY-TIME line" do
        @lines.shift.should == "CATEGORY-TIME: 24-HOURS"
      end

      it "should write CATEGORY-TRANSMITTER line" do
        @lines.shift.should == "CATEGORY-TRANSMITTER: ONE"
      end

      it "should write CATEGORY-OVERLAY line" do
        @lines.shift.should == "CATEGORY-OVERLAY: ROOKIE"
      end

      it "should write CLAIMED-SCORE line" do
        @lines.shift.should == "CLAIMED-SCORE: 1234"
      end

      it "should write CLUB line" do
        @lines.shift.should == "CLUB: University of Akron"
      end

      it "should write EMAIL line" do
        @lines.shift.should == "EMAIL: test@test.com"
      end

      it "should write NAME line" do
        @lines.shift.should == "NAME: Ricky Elrod"
      end

      it "should write LOCATION line" do
        @lines.shift.should == "LOCATION: OH"
      end

      it "should write both OPERATORS lines" do
        @lines.shift.should == "OPERATORS: N8SQL"
      end

      it "should write ADDRESS line" do
        @lines.shift.should == "ADDRESS: 501 Zook Hall"
      end

      it "should write ADDRESS-CITY line" do
        @lines.shift.should == "ADDRESS-CITY: Akron"
      end

      it "should write ADDRESS-STATE-PROVINCE line" do
        @lines.shift.should == "ADDRESS-STATE-PROVINCE: OH"
      end

      it "should write ADDRESS-POSTALCODE line" do
        @lines.shift.should == "ADDRESS-POSTALCODE: 44325"
      end

      it "should write ADDRESS-COUNTRY line" do
        @lines.shift.should == "ADDRESS-COUNTRY: United States"
      end

      it "should write both SOAPBOX lines" do
        @lines.shift.should == "SOAPBOX: This is just a test log."
        @lines.shift.should == "SOAPBOX: If parsed successfully, N8SQL will be happy."
      end

      it "should write both OFFTIME lines" do
        @lines.shift.should == "OFFTIME: 2012-02-11 0000 2012-02-11 2032"
      end

      it "should write qso lines" do
        @lines.shift.should == "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  001    KG4SGP        59  HARCT"
        @lines.shift.should == "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  002    KD8LCV        59  NHNCT"
        @lines.shift.should == "QSO: 14325 PH 2012-02-11 0102 N8SQL         59  003    W1AW          59  SOMME"
      end

    end

  end
end
