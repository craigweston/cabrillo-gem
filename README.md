# Cabrillo

[![Build Status](https://secure.travis-ci.org/CodeBlock/cabrillo-gem.png?branch=master)](http://travis-ci.org/CodeBlock/cabrillo-gem)

This library handles the parsing and generation of the Cabrillo ham radio
logging format, commonly used by the ARRL for contesting. 

# Using the Library

## Parsing log data

```ruby
require 'cabrillo'
my_log = Cabrillo.parse(string_containing_log)

# OR

my_log = Cabrillo.parse_file(path_to_log)
```

### Examples

```ruby
# Parse a logfile:
>> log = Cabrillo.parse_file('../test/data/cabrillo1.cabrillo')
 => #<Cabrillo:0x00000002ea9c58 @version="3.0", @created_by="WavePower 1.0", @contest="WAEDC", @callsign="W8UPD", @claimed_score="1234", @club="University of Akron", @name="Ricky Elrod">
 
# Convert it to a Hash:
>> log.to_hash
 => {:version=>"3.0", :created_by=>"WavePower 1.0", :contest=>"WAEDC", :callsign=>"W8UPD", :claimed_score=>"1234", :club=>"University of Akron", :name=>"Ricky Elrod"}

# Convert it to JSON using the stdlib JSON library:
>> require 'json'
 => true
>> log.to_hash.to_json
 => "{\"version\":\"3.0\",\"created_by\":\"WavePower 1.0\",\"contest\":\"WAEDC\",\"callsign\":\"W8UPD\",\"claimed_score\":\"1234\",\"club\":\"University of Akron\",\"name\":\"Ricky Elrod\"}"
```

## Generating log files

* Not yet possible, coming soon.

# Things to note.

We will stay as close to the current specification version as possible.
As of this writing, that is version 3.0. No guarantee is made that
this library will work on any version prior to the latest current
version of the spec. We follow [semver](http://semver.org), so with
each backwards-incompatible change in the spec will result in us
bumping the major version of the gem.

We make a few (slight) differences in our parsing, which are described here:

### Invalid Data

In fields which have a limited number of possible responses, we do some sanity
checks as we parse, and we raise an exception and stop parsing if we come
across an invalid field. You can catch the exception and handle it accordingly.

Although we don't recommend it, if you absolutely must, you can disable
exceptions being thrown for giving an invalid value, effectively disabling
sanity checking when parsing. To do this, just set:

```ruby
Cabrillo.raise_on_invalid_data = false
```

before parsing a log file or string.

### Overwriting Data

If a log has a field multiple times, which isn't expected to occur more than
once (as per the spec), the last occurance always wins, every time. This is
because we `Hash.merge!` the field to a hash internally, and `Hash.merge!` does
the following:

```ruby
>> a = { :foo => "bar" }
 => {:foo=>"bar"} 
>> a.merge!({ :foo => "buzz" })
 => {:foo=>"buzz"} 
>> a
 => {:foo=>"buzz"} 
```

### Comments

To start with, **any line beginning with a `#` or `//` is parsed as a
comment.**

Lines parsed as comments have no effect on the parsed Cabrillo log. They are
totally ignored and skipped over as if they were a blank line.

Cabrillo (the gem) will never add comments to Cabrillo files on its own because
they are not officially part of the spec.

# Contributing

Contributions are gladly accepted and encouraged. Please run the tests and
ensure everything still passes.

Do this by ensuring you have all of the required gems (including rspec). This
can be done with `bundle` in your clone of the git repository. Then run the
test suite with `rspec`.

Please commit your changes on a separate branch and send a pull request.

Please remember to document (using [TomDoc](http://tomdoc.org/)) any new methods
that you add.

# License

This library is released under the MIT license

```
Copyright (c) 2012-present Ricky Elrod <ricky@elrod.me>
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
