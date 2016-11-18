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

my @all_project_reviewers =
  (
   q{alancaster@affinegy.com},
   q{lioy@qce.qualcomm.com},
  );

my %project_committers =
  (
   'core/ajtcl' => undef,
   'core/alljoyn' => undef,
   'core/alljoyn-js' => undef,
   'core/openwrt_feed' => undef,
   'core/test' => undef,
   'ajsipe2e' => undef,
   'cdm' => undef,
   'cdm_tcl' => undef,
   'compliance/tests' => undef,
   'devtools/manifest' => undef,
   'dsb' => undef,
   'extras/automation' => undef,
   'extras/webdocs' => undef,
   'gateway/gwagent' => undef,
   'hdb' => undef,
   'interfaces' => undef,
   'lighting/apps' => undef,
   'lighting/service_framework' => undef,
   'location' => undef,
   'meta-alljoyn' => undef,
   'services/base' => undef,
   'services/base_tcl' => undef,
   'xmppconn' => undef,
  );

my %group;

foreach my $ch ( @open_gerrit_change ) {
  my @reviewers = map { "-a $_" }
    (
     @all_project_reviewers,
    );

unless( defined $project_committers{$ch->{project}} ){
  my @m;
  my @groups = grep { /committers/ } qx{ssh -p ${gerrit_port} ${gerrit_host} gerrit ls-groups -p core/alljoyn};

  foreach my $g ( @groups ){
    if( exists $group{$g} ){
      push(@m, @{ $group{$g} });
      next
    }

    my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit ls-members $g};
    print STDERR $cmd, $/;
    chomp(my @line = qx{$cmd});
    shift(@line);
    my @member;
    foreach my $l ( @line ){
      my @f = ( split(/\t/, $l) );
      push(@member,
        { id => $f[0],
          username => $f[1],
          'full name' => $f[2],
          email => $f[3]
        } );
    };

    $group{$g} = [@member];
    push( @m, @member );
  }

  $project_committers{$ch->{project}} = [map { $_->{email} } @m];

  push( @reviewers, map { "-a $_" } @{ $project_committers{$ch->{project}} } );

  my $cmd = qq{ssh -p ${gerrit_port} ${gerrit_host} gerrit set-reviewers $ch->{currentPatchSet}->{revision} @reviewers};
  print STDERR $cmd, $/;
  system($cmd);
}


