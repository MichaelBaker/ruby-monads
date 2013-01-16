require_relative 'monads'

# The identity monad, while seeming useless, captures one of the key features of monads.
# All the identity monad allows you to do is sequence operations together.
describe "identity" do
  # unit is one one of the two functions required to make a monad.
  # unit's job is to take a non-monad value and make it compatable with the monad.
  # The identity monad doesn't place any special requirements on its value, so it doesn't need to do anything
  context "unit" do
    specify "id_unit returns the value it's given" do
      id_unit("ohai").should   == "ohai"
      id_unit(5).should        == 5
      id_unit(Hash.new).should == Hash.new
    end
  end

  # bind is the second, and more interesting, function for a given monad.
  # bind's job is to sequence operations together while processing the monadic value.
  # Because the identity monad doesn't do any processing, it only provides the sequencing function.
  context "bind" do
    specify "id_bind passes its first argument to the given block" do
      id_bind(id_unit "orly") { |text| text + " yarly" }.should == "orly yarly"
    end
  end
end

# The famous maybe monad, which you're already familiar with, is a way of stopping a sequence of operations when one of them fails.
# We'll be using Nothing to represent a failed operation and Just to indicate a successful operation.
describe "maybe" do
  specify "maybe_unit always creates a successful result" do
    maybe_unit("yeop").should == Just.new("yeop")
    maybe_unit(nil).should    == Just.new(nil)
  end

  # Beyond providing the shortcut behavior, maybe also provides another basic monadic function.
  # When you bind a monadic value to an operation, bind exposes the value wrapped by the monadic value to that operation.
  specify "maybe_bind returns its last value if no Nothing values are encountered" do
    maybe_bind(Just.new "thingy") { |text| maybe_unit "other" + text }.should == Just.new("otherthingy")

    maybe_bind(Just.new "o_O")    do |face_one|
    maybe_bind(Just.new "X.X")    do |face_two|
    maybe_bind(Just.new "-____-") do |face_three|
      maybe_unit(face_one + face_two + face_three)
    end end end.should == Just.new("o_OX.X-____-")
  end

  specify "maybe_bind ends the sequence of operations if it encounters a Nothing value" do
    maybe_bind(Nothing.new) { raise "Should not get here" }.should == Nothing.new

    maybe_bind(Just.new "o_O")    do |face_one|
    maybe_bind(Just.new "-____-") do |face_two|
    maybe_bind(Nothing.new)       do
      raise "Should not get here"
    end end end.should == Nothing.new

    maybe_bind(Just.new "o_O")    do |face_one|
    maybe_bind(Nothing.new)       do
    maybe_bind(Just.new "-____-") do |face_three|
      raise "Should not get here"
    end end end.should == Nothing.new
  end
end

# either is a more powerful shortcut mechanism than maybe.
# It also has two values named Left and Right.
# Left ends the operation sequence. Right allows the operation to continue.
# Unlike maybe's Nothing value, Left wraps a value of some kind.
describe "either" do
  specify "either_unit always creates a successful result" do
    either_unit("wat").should == Right.new("wat")
    either_unit(nil).should   == Right.new(nil)
  end

  specify "either_fail always creates a failed result" do
    either_fail("wat").should == Left.new("wat")
    either_fail(nil).should   == Left.new(nil)
  end

  specify "either_bind ends the sequence in the event of a Left value" do
    either_bind(either_unit "o_O")       do |face_one|
    either_bind(either_unit "-____-")    do |face_two|
    either_bind(either_fail "error sir") do
      raise "Should not get here"
    end end end.should == either_fail("error sir")

    either_bind(either_unit "o_O")    do |face_one|
    either_bind(either_fail "Omgosh") do
    either_bind(either_unit "-____-") do |face_three|
      raise "Should not get here"
    end end end.should == either_fail("Omgosh")
  end

  specify "either_bind returns the last value if a Left value is never encoutered" do
    either_bind(either_unit "o_O")    do |face_one|
    either_bind(either_unit "X.X")    do |face_two|
    either_bind(either_unit "-____-") do |face_three|
      either_unit face_one + face_two + face_three
    end end end.should == either_unit("o_OX.X-____-")
  end
end

# The writer monad allows you to accululate some extra information about the sequence of operations being performed.
describe "writer" do
  specify "writer_unit attaches an empty list of writes to the given value" do
    writer_unit(5).should == Writer.new(5, [])
  end

  # One common use case for the writer is as a logger.
  specify "writer_bind accumulates the writes from each operation" do
    writer_bind(Writer.new("yhello", ["Gettin' Goin'"])) do |message|
      Writer.new(message, ["[DaTime] #{message}"])
    end.should == Writer.new("yhello", ["Gettin' Goin'", "[DaTime] yhello"])
  end

  # writer_tell is the first specialized monadic function in these examples.
  # Often monads will include functions in addition to unit and bind that afford more sophisticated behavior.
  # writer_tell records a new write without performing an operation.
  specify "writer_tell" do
    writer_bind(writer_unit nil) { writer_tell "I pitty da fool" }.should == Writer.new(nil, ["I pitty da fool"])

    writer_bind(writer_unit 0)                               do |first_value|
    writer_bind(writer_tell "Got #{first_value}")            do
    writer_bind(writer_unit 1)                               do |second_value|
    writer_bind(writer_tell "Got #{second_value}")           do
    writer_bind(writer_unit 2)                               do |third_value|
    writer_bind(writer_tell "Got #{third_value}. Adding...") do
      writer_unit first_value + second_value + third_value
    end end end end end end.should == Writer.new(3, ["Got 0", "Got 1", "Got 2. Adding..."])
  end
end
