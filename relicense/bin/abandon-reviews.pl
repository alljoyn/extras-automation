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
my $gerrit_cmd =
#  qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit query --format=JSON topic:^.*_re-license --current-patch-set};
  qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit query --format=JSON topic:^.*_re-license --patch-sets};

print STDERR $gerrit_cmd, $/ if $DEBUG;

print STDERR 'fetching list of changes with topic matching re-license...';
my( @gerrit_output ) = qx{$gerrit_cmd};
print STDERR "done$/";

my $gerrit_status = $json->decode( pop( @gerrit_output ) );

my( @open_gerrit_change ) =
  sort { $a->{number} <=> $b->{number} }
  grep { $_->{open} }
  map { $json->decode( $_ ) }
  @gerrit_output;

my $num_changes = scalar @open_gerrit_change;
print STDERR "Abandoning all patchsets from $num_changes changes.$/";

foreach my $ch ( @open_gerrit_change ) {
  next if $ch->{status} eq 'DRAFT';

  foreach my $ps ( @{ $ch->{patchSets}} ){
#    my $ps = $ch->{currentPatchSet};

#  my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit review --abandon $ch->{id}};
#  my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit review --abandon $ch->{number},$ps->{number}};
    my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit review --abandon $ps->{revision}};
    print STDERR $cmd, $/;
    system($cmd);
  }
}


