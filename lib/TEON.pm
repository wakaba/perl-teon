package TEON;
use strict;
use warnings;
our $VERSION = '1.0';

BEGIN {
  unless (eval q{ use Unicode::UTF8 qw(decode_utf8); 1 }) {
    eval q{ use Encode qw(decode_utf8); 1 } or die $@;
  }
}

sub _e ($) {
  my $s = $_[0];
  $s =~ s/([\x0D\x0A\\])/{"\x0D" => "\\r", "\x0A" => "\\n", "\\" => "\\\\"}->{$1}/ge;
  return $s;
} # _e

sub _ec ($) {
  my $s = $_[0];
  $s =~ s/([\x0D\x0A:\\])/{"\x0D" => "\\r", "\x0A" => "\\n", ":" => "\\C", "\\" => "\\\\"}->{$1}/ge;
  return $s;
} # _ec

sub _ue ($) {
  return $_[0] unless index ($_[0], '\\') > -1;
  my $v = $_[0];
  $v =~ s/\\([nrC\\])/{n => "\x0A", r => "\x0D", "C" => ":", "\\" => "\\"}->{$1}/ge;
  return $v;
} # _ue

sub parse_bytes ($$) {
  return shift->parse_text (map { s/^\x{FEFF}//; $_ } decode_utf8 ($_[0]));
} # parse_bytes

sub parse_text ($$) {
  my ($class, $text) = @_;
  my $props = {};
  my $enum_props = {};
  my $list_props = {};
  $text =~ s/\x0D\x0A/\x0A/g;
  for (split /\x0A/, $text) {
    if (/\A\$([^:]+):(.*)\z/) {
      my ($n, $v) = ($1, $2);
      $props->{_ue $n} = _ue $v;
    } elsif (/\A&([^:]+):(.*)\z/) {
      my ($n, $v) = (_ue $1, _ue $2);
      $enum_props->{$n}->{$v} = 1;
    } elsif (/\A\@([^:]+):(.*)\z/) {
      my ($n, $v) = (_ue $1, _ue $2);
      push @{$list_props->{$n} ||= []}, $v;
    }
  }
  return {scalars => $props, enums => $enum_props, lists => $list_props};
} # parse_text

sub to_text ($$) {
  my $props = $_[1]->{scalars} || {};
  my @s;
  for (sort { $a cmp $b } keys %$props) {
    my $s = '$' . (_ec $_) . ':' . _e $props->{$_};
    push @s, $s;
  }
  my $enum_props = $_[1]->{enums} || {};
  for my $key (sort { $a cmp $b } keys %$enum_props) {
    for (sort { $a cmp $b } grep { $enum_props->{$key}->{$_} } keys %{$enum_props->{$key}}) {
      my $s = '&' . (_ec $key) . ':' . _e $_;
      push @s, $s;
    }
  }
  my $list_props = $_[1]->{lists} || {};
  for my $key (sort { $a cmp $b } keys %$list_props) {
    for my $item (@{$list_props->{$key}}) {
      my $s = '@' . (_ec $key) . ':' . _e $item;
      push @s, $s;
    }
  }
  return join "\x0A", @s;
} # to_text

1;
