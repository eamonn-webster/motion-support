module MotionSupport
  # Provides accurate date and time measurements using Date#advance and
  # Time#advance, respectively. It mainly supports the methods on Numeric.
  #
  #   1.month.ago       # equivalent to Time.now.advance(months: -1)
  class Duration
    attr_accessor :value, :parts

    def initialize(value, parts) #:nodoc:
      @value, @parts = value, parts
    end

    # Adds another Duration or a Numeric to this Duration. Numeric values
    # are treated as seconds.
    def +(other)
      if Duration === other
        Duration.new(value + other.value, @parts + other.parts)
      else
        Duration.new(value + other, @parts + [[:seconds, other]])
      end
    end

    # Subtracts another Duration or a Numeric from this Duration. Numeric
    # values are treated as seconds.
    def -(other)
      self + (-other)
    end

    def -@ #:nodoc:
      Duration.new(-value, parts.map { |type,number| [type, -number] })
    end

    def is_a?(klass) #:nodoc:
      Duration == klass || value.is_a?(klass)
    end
    alias :kind_of? :is_a?

    # Returns +true+ if +other+ is also a Duration instance with the
    # same +value+, or if <tt>other == value</tt>.
    def ==(other)
      if Duration === other
        other.value == value
      else
        other == value
      end
    end

    def self.===(other) #:nodoc:
      other.is_a?(Duration)
    rescue ::NoMethodError
      false
    end

    # Calculates a new Time or Date that is as far in the future
    # as this Duration represents.
    def since(time = ::Time.now)
      sum(1, time)
    end
    alias :from_now :since

    # Calculates a new Time or Date that is as far in the past
    # as this Duration represents.
    def ago(time = ::Time.now)
      sum(-1, time)
    end
    alias :until :ago

    def inspect #:nodoc:
      consolidated = parts.inject(::Hash.new(0)) { |h,(l,r)| h[l] += r; h }
      parts = [:years, :months, :days, :minutes, :seconds].map do |length|
        n = consolidated[length]
        "#{n} #{n == 1 ? length.to_s.singularize : length.to_s}" if n.nonzero?
      end.compact
      parts = ["0 seconds"] if parts.empty?
      parts.to_sentence
    end

    def as_json(options = nil) #:nodoc:
      to_i
    end

    def to_json
      as_json.to_json
    end

    protected

    def sum(sign, time = ::Time.now) #:nodoc:
      parts.inject(time) do |t,(type,number)|
        if t.acts_like?(:time) || t.acts_like?(:date)
          if type == :seconds
            t.since(sign * number)
          else
            t.advance(type => sign * number)
          end
        else
          raise ::ArgumentError, "expected a time or date, got #{time.inspect}"
        end
      end
    end

  private

    def method_missing(method, *args, &block) #:nodoc:
      value.send(method, *args, &block)
    end
  end
end
