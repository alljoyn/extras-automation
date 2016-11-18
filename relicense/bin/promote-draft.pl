#!/usr/bin/perl -w
use strict;

use JSON::XS;
use Data::Dumper;

my $DEBUG=1;

my $json = JSON::XS->new->utf8->pretty;

my $domain = q{allseenalliance.org};

my $gerrit_host = qq{git.$domain};
my $gerrit_port = 29418;

# Query gerrit for all re-license changes
print STDERR 'fetching list of changes with topic matching re-license...' if $DEBUG;
my $gerrit_cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit query --format=JSON topic:^.*_re-license --current-patch-set};
my( @gerrit_output ) = qx{$gerrit_cmd};
print STDERR "done$/" if $DEBUG;

my $gerrit_status = $json->decode( pop( @gerrit_output ) );

my( @open_gerrit_change ) =
  sort { $a->{number} <=> $b->{number} }
  grep { $_->{open} }
  map { $json->decode( $_ ) }
  @gerrit_output;

foreach my $ch ( @open_gerrit_change ) {
  next unless $ch->{status} eq 'DRAFT';
  my $bname = $ch->{branch};
  my $pname = $ch->{project};
  my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit review -p ${pname} -b ${bname} --publish $ch->{currentPatchSet}->{revision}};
  print STDERR $cmd, $/;
  system($cmd);
}


