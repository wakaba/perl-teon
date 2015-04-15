use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');
use Test::X1;
use Test::Differences;
use Test::HTCT::Parser;
use JSON::PS;
use TEON;

test {
  my $c = shift;

  my $parsed = TEON->parse_bytes (qq{\$fo\xE3\x81\xBBo:a\xE7\xAD\x89b\x80});
  eq_or_diff $parsed, {scalars => {"fo\x{307B}o" => "a\x{7B49}b\x{FFFD}"}, enums => {}, lists => {}};

  my $serialized = TEON->to_text ($parsed);
  eq_or_diff $serialized, "\$fo\x{307B}o:a\x{7B49}b\x{FFFD}";

  done $c;
} n => 2, name => 'parse_bytes';

test {
  my $c = shift;

  my $parsed = TEON->parse_bytes (qq{\xEF\xBB\xBF\$fo\xE3\x81\xBBo:a\xE7\xAD\x89b\x80});
  eq_or_diff $parsed, {scalars => {"fo\x{307B}o" => "a\x{7B49}b\x{FFFD}"}, enums => {}, lists => {}};

  my $serialized = TEON->to_text ($parsed);
  eq_or_diff $serialized, "\$fo\x{307B}o:a\x{7B49}b\x{FFFD}";

  done $c;
} n => 2, name => 'parse_bytes BOM';

test {
  my $c = shift;

  my $parsed = TEON->parse_bytes (qq{\xEF\xBB\xBF\xEF\xBB\xBF\$fo\xE3\x81\xBBo:a\xE7\xAD\x89b\x80\x0D\x0A\$a:b});
  eq_or_diff $parsed, {scalars => {"a" => "b"}, enums => {}, lists => {}};

  my $serialized = TEON->to_text ($parsed);
  eq_or_diff $serialized, "\$a:b";

  done $c;
} n => 2, name => 'parse_bytes BOM';

for my $file_name (map { path (__FILE__)->parent->parent->child ('t_deps/tests', $_) } qw(
  data-1.dat
)) {
  for_each_test $file_name, {
    data => {is_prefixed => 1},
    parsed => {},
    serialized => {},
  }, sub {
    my $test = $_[0];
    test {
      my $c = shift;

      my $parsed = TEON->parse_text ($test->{data}->[0]);
      eq_or_diff $parsed, json_chars2perl $test->{parsed}->[0], 'parse';

      my $serialized = TEON->to_text ($parsed);
      eq_or_diff $serialized, $test->{serialized}->[0], 'serialize';

      done $c;
    } n => 2, name => [$file_name, $test->{data}->[0]];
  };
}

run_tests;
