**TimeCalc** tries to provide a way to do **simple time arithmetics** in a modern, readable, idiomatic, no-"magic" Ruby.

_**NB:** TimeCalc is a continuation of [TimeMath](https://github.com/zverok/time_math2) project. As I decided to change API significantly (completely, in fact) and drop lot of "nice to have but nobody uses" features, it is a new project rather than "absolutely incompatible new version". See [API design](#api-design) section to understand how and why TimeCalc is different._

## Features

* Small, clean, pure-Ruby, idiomatic, no monkey-patching, no dependencies (except `backports`);
* Arithmetic akin to what Ruby numbers provide: `+`/`-`, `floor`/`ceil`/`round`, enumerable sequences (`step`/`to`);
* Works with `Time`, `Date` and `DateTime` and allows to mix them freely (e.g. create sequences from `Date` to `Time`, calculate their diffs);
* Tries its best to preserve timezone/offset information:
  * **on Ruby 2.6+**, for `Time` with real timezones, preserves them;
  * on Ruby < 2.6, preserves at least `utc_offset` of `Time`;
  * for `DateTime` preserves zone name.

## Synopsys

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

### Difference of two values

```ruby
diff = TC.(t) - Time.parse('2019-02-30 16:30')
# => #<TimeCalc::Diff(2019-03-14 08:06:15 +0200 − 2019-03-02 16:30:00 +0200)>
diff.days # or any other supported unit
# => 11
diff.factorize
# => {:year=>0, :month=>0, :week=>1, :day=>4, :hour=>15, :min=>36, :sec=>15}
```

There are several options to [Diff#factorize](http://localhost:8808/docs/TimeCalc/Diff#factorize-instance_method) to obtain the most useful result.

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

## Credits & license