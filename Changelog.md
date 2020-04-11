# TimeCalc changelog

## 0.0.4 / 2020-04-11

* Support `ActiveSupport::TimeWithZone` as a calculation target.


## 0.0.3 / 2019-12-14

* Add `TimeCalc#iterate` to easily operate in "business date/time" contexts.

## 0.0.2 / 2019-07-08

* Alias `TimeCalc[tm]` for those who disapporve on `TimeCalc.(tm)`;
* More accurate zone info preservation when time is in local timezone of current machine.

## 0.0.1 / 2019-07-05

First release. Rip-off of [time_math2](https://github.com/zverok/time_math2) with full API redesign and dropping of some less-used features ("resamplers").
