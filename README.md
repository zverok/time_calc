# TimeCalc -- next generation of Time arithmetic library

[![Gem Version](https://badge.fury.io/rb/time_calc.svg)](http://badge.fury.io/rb/time_calc)
[![Build Status](https://travis-ci.org/zverok/time_calc.svg?branch=master)](https://travis-ci.org/zverok/time_calc)
[![Documentation](http://b.repl.ca/v1/yard-docs-blue.png)](http://rubydoc.info/gems/time_calc/frames)

**TimeCalc** tries to provide a way to do **simple time arithmetic** in a modern, readable, idiomatic, no-"magic" Ruby.

_**NB:** TimeCalc is a continuation of [TimeMath](https://github.com/zverok/time_math2) project. As I decided to change API significantly (completely, in fact) and drop a lot of "nice to have but nobody uses" features, it is a new project rather than "absolutely incompatible new version". See [API design](#api-design) section to understand how and why TimeCalc is different._

## Features

* Small, clean, pure-Ruby, idiomatic, no monkey-patching, no dependencies (except `backports`);
* Arithmetic akin to what Ruby numbers provide: `+`/`-`, `floor`/`ceil`/`round`, enumerable sequences (`step`/`to`);
* Works with `Time`, `Date` and `DateTime` and allows to mix them freely (e.g. create sequences from `Date` to `Time`, calculate their diffs);
* Tries its best to preserve timezone/offset information:
  * **on Ruby 2.6+**, for `Time` with real timezones, preserves them;
  * on Ruby < 2.6, preserves at least `utc_offset` of `Time`;
  * for `DateTime` preserves zone name;
* _Since 0.0.4,_ supports `ActiveSupport::TimeWithZone`, too. While in ActiveSupport-enabled context TimeCalc may seem redundant (you'll probably use `time - 1.day` anyways), some of the functionality is easier with TimeCalc (rounding to different units) or just not present in ActiveSupport (time sequences, iterate with skippking); also may be helpful for third-party libraries which want to use TimeCalc underneath but don't want to be broken in Rails context.

## Synopsis

### Arithmetic with units

```ruby
require 'time_calc'

TC = TimeCalc

t = Time.parse('2019-03-14 08:06:15')

TC.(t).+(3, :hours)
# => 2019-03-14 11:06:15 +0200
TC.(t).round(:week)
# => 2019-03-11 00:00:00 +0200

# TimeCalc.call(Time.now) shortcut:
TC.now.floor(:day)
# => beginning of the today
```

Operations supported:

* `+`, `-`
* `ceil`, `round`, `floor`

Units supported:

* `:sec` (also `:second`, `:seconds`);
* `:min` (`:minute`, `:minutes`);
* `:hour`/`:hours`;
* `:day`/`:days`;
* `:week`/`:weeks`;
* `:month`/`:months`;
* `:year`/`:years`.

Timezone preservation on Ruby 2.6:

```ruby
require 'tzinfo'
t = Time.new(2019, 9, 1, 14, 30, 12, TZInfo::Timezone.get('Europe/Kiev'))
# => 2019-09-01 14:30:12 +0300
#                        ^^^^^
TimeCalc.(t).+(3, :months) # jump over DST: we have +3 in summer and +2 in winter
# => 2019-12-01 14:30:12 +0200
#                        ^^^^^
```
<small>(Random fun fact: it is Kyiv, not Kiev!)</small>

### Math with skipping "non-business time"

[TimeCalc#iterate](https://www.rubydoc.info/gems/time_calc/TimeCalc#iterate-instance_method) allows to advance or decrease time values by skipping some of them (like weekends, holidays, and non-working hours):

```ruby
# add 10 working days (weekends are not counted)
TimeCalc.(Time.parse('2019-07-03 23:28:54')).iterate(10, :days) { |t| (1..5).cover?(t.wday) }
# => 2019-07-17 23:28:54 +0300

# add 12 working hours
TimeCalc.(Time.parse('2019-07-03 13:28:54')).iterate(12, :hours) { |t| (9...18).cover?(t.hour) }
# => 2019-07-04 16:28:54 +0300

# negative spans are working, too:
TimeCalc.(Time.parse('2019-07-03 13:28:54')).iterate(-12, :hours) { |t| (9...18).cover?(t.hour) }
# => 2019-07-02 10:28:54 +0300

# zero span could be used to robustly enforce value into acceptable range
# (increasing forward till block is true):
TimeCalc.(Time.parse('2019-07-03 23:28:54')).iterate(0, :hours) { |t| (9...18).cover?(t.hour) }
# => 2019-07-04 09:28:54 +0300
```

### Difference of two values

```ruby
diff = TC.(t) - Time.parse('2019-02-30 16:30')
# => #<TimeCalc::Diff(2019-03-14 08:06:15 +0200 − 2019-03-02 16:30:00 +0200)>
diff.days # or any other supported unit
# => 11
diff.factorize
# => {:year=>0, :month=>0, :week=>1, :day=>4, :hour=>15, :min=>36, :sec=>15}
```

There are several options to [Diff#factorize](https://www.rubydoc.info/gems/time_calc/TimeCalc/Diff#factorize-instance_method) to obtain the most useful result.

### Chains of operations

```ruby
TC.wrap(t).+(1, :hour).round(:min).unwrap
# => 2019-03-14 09:06:00 +0200

# proc constructor synopsys:
times = ['2019-06-01 14:30', '2019-06-05 17:10', '2019-07-02 13:40'].map { |t| Time.parse(t) }
times.map(&TC.+(1, :hour).round(:min))
# => [2019-06-01 15:30:00 +0300, 2019-06-05 18:10:00 +0300, 2019-07-02 14:40:00 +0300]
```

### Enumerable time sequences

```ruby
TC.(t).step(2, :weeks)
# => #<TimeCalc::Sequence (2019-03-14 08:06:15 +0200 - ...):step(2 weeks)>
TC.(t).step(2, :weeks).first(3)
# => [2019-03-14 08:06:15 +0200, 2019-03-28 08:06:15 +0200, 2019-04-11 09:06:15 +0300]
TC.(t).to(Time.parse('2019-04-30 16:30')).step(3, :weeks).to_a
# => [2019-03-14 08:06:15 +0200, 2019-04-04 09:06:15 +0300, 2019-04-25 09:06:15 +0300]
TC.(t).for(3, :months).step(4, :weeks).to_a
# => [2019-03-14 08:06:15 +0200, 2019-04-11 09:06:15 +0300, 2019-05-09 09:06:15 +0300, 2019-06-06 09:06:15 +0300]
```

## API design

The idea of this library (as well as the idea of the previous one) grew of the simple question "how do you say `<some time> + 1 hour` in good Ruby?" This question also leads (me) to notifying that other arithmetical operations (like rounding, or `<value> up to <value> with step <value>`) seem to be applicable to `Time` or `Date` values as well.

Prominent ActiveSupport's answer of extending simple numbers to respond to `1.year` never felt totally right to me. I am not completely against-any-monkey-patches kind of guy, it just doesn't sit right, to say "number has a method to produce duration". One of the attempts to find an alternative has led me to the creation of [time_math2](https://github.com/zverok/time_math2), which gained some (modest) popularity by presenting things this way: `TimeMath.year.advance(time, 1)`.

TBH, using the library myself only eventually, I have never been too happy with it: it never felt really natural, so I constantly forgot "what should I do to calculate '2 days ago'". This simplest use case (some time from now) in `TimeMath` looked too far from "how you pronounce it":

```ruby
# Natural language: 2 days ago
# "Formalized": now - 2 days

# ActiveSupport:
Time.now - 2.days
# also there is 2.days.ago, but I am not a big fan of "1000 synonyms just for naturality"

# TimeMath:
TimMath.day.decrease(Time.now, 2) # Ughhh what? "Day decrease now 2"?
```

The thought process that led to the new library is:

* `(2, days)` is just a _tuple_ of two unrelated data elements
* `days` is "internal name that makes sense inside the code", which we represent by `Symbol` in Ruby
* Math operators can be called just like regular methods: `.+(something)`, which may look unusual at first, but can be super-handy even with simple numbers, in method chaining -- I am grateful to my Verbit's colleague Roman Yarovoy to pointing at that fact (or rather its usefulness);
* To chain some calculations with Ruby core type without extending this type, we can just "wrap" it into a monad-like object, do the calculations, and unwrap at the end (TimeMath itself, and my Hash-processing gem [hm](https://github.com/zverok/hm) have used this approach).

So, here we go:
```ruby
TimeCalc.(Time.now).-(2, :days)
# Small shortcut, as `Time.now` is the frequent start value for such calculations:
TimeCalc.now.-(2, :days)
```

The rest of the design (see examples above) just followed naturally. There could be different opinions on the approach, but for myself the resulting API looks straightforward, hard to forget and very regular (in fact, all the hard time calculations, including support for different types, zones, DST and stuff, are done in two core methods, and the rest was easy to define in terms of those methods, which is a sign of consistency).

¯\\\_(ツ)_/¯

## Author & license

* [Victor Shepelev](https://zverok.github.io)
* [MIT](https://github.com/zverok/time_calc/blob/master/LICENSE.txt).
