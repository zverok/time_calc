**TimeCalc** tries to provide a way to do **simple time arithmetics** in a modern, readable, idiomatic, no-"magic" Ruby.

_**NB:** TimeCalc is a continuation of [TimeMath](https://github.com/zverok/time_math2) project. As I decided to change API significantly (completely, in fact) and drop lot of "nice to have but nobody uses" features, it is a new project rather than "absolutely incompatible new version"._

## Synopsys:

### Arithmetic with units

```ruby
require 'time_calc'

TC = TimeCalc

t = Time.parse('2018-03-14 08:06:15')

TC.(t).+(1, :hour).round(:min).to_time
# TimeCalc.call(Time.now) shortcut:
TC.now.ceil(:day).to_time # beginning of the today

# proc constructor synopsys:
times.map(&TC.+(1, :hour).round(:min))

# First tuesday of current month:
TC.now.floor(:month).ceil(2/7r, :week).to_time
# It is algorithmically pretty, yet not for everybody's eyes, so this is the synonym:
TC.now.floor(:month).ceil(:tuesday).to_time
```

Operations supported:
* `+`, `-`
* `ceil`, `round`, `floor`

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

TC::Op.(t).+(1, :hour).round(:min).to_time

# proc constructor synopsys:
times.map(&TC::Op.+(1, :hour).round(:min))

# First tuesday of current month:
TC::Op.now.floor(:month).ceil(2/7r, :week).to_time
# It is algorithmically pretty, yet not for everybody's eyes, so this is the synonym:
TC::Op.now.floor(:month).ceil(:tuesday).to_time
```