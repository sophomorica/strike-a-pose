# Judge

Round r's judge is player index (r − 1) mod N. The grid shows the other players' snaps from that round, misses included, and hides the judge's own. Confirming adds 50 once. Two players, judge off, and referee mode skip the step.

Drive: `flutter test test/engine_test.dart --name judge` and `flutter test test/widget_test.dart --name "judge grid"`.
