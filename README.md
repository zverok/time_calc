**TimeCalc** tries to provide a way to do **simple time arithmetics** in a modern, readable, idiomatic, no-"magic" Ruby.

_**NB:** TimeCalc is a continuation of [TimeMath](https://github.com/zverok/time_math2) project. As I decided to change API significantly (completely, in fact) and drop lot of "nice to have but nobody uses" features, it is a new project rather than "absolutely incompatible new version"._

## Synopsys:

### Arithmetic with units

```ruby
require 'time_calc'

TC = TimeCalc

t = Time.parse('2018-03-14 08:06:15')

TC.(t).+(3, :hours)
# TimeCalc.call(Time.now) shortcut:
TC.now.floor(:day) # beginning of the today

TC.now.round(2/7r, :weeks)

TC.(t).-(other) # TimeDiff# to_i(:year), to_f(:year), % :year

```

Operations supported:
* `+`, `-`
* `ceil`, `round`, `floor`
* `clamp`

Each operation has two forms: `op(num, unit)` and `op(unit)` (= synonym for `op(1, unit)`). This means
you can also do `round(3, :hours)` to round to nearest 3-hour mark (0h, 3h, 9h, 12h, 15h...), and
even `round(1/2r, :hours)` to round to nearest half-an-hour mark.

Units supported:
* `:sec` (also `:second`, `:seconds`);
* `:min` (`:minute`, `:minutes`);
* `:hour`/`:hours`;
* `:day`/`:days`;
* `:week`/`:weeks`;
* `:month`/`:months`;
* `:year`/`:years`.

### Chains of operations

```ruby
t = Time.parse('2018-03-14 08:06:15')

TC.with(t).+(1, :hour).round(:min).to_time

# proc constructor synopsys:
times.map(&TC.+(1, :hour).round(:min))

# First tuesday of current month:
TC.with_now.floor(:month).ceil(2/7r, :week).to_time
# It is algorithmically pretty, yet not for everybody's eyes, so this is the synonym:
TC.with_now.floor(:month).ceil(:tuesday).to_time
```

### Math sequences

```ruby
TC.(t).step(2, :weeks)
TC.(from).upto(to).step(3, :weeks)
TC.(from).for(3, :years).step(2, :weeks)
```

### Utility methods

```ruby
TC.(t).merge(year: 2001)
```