#!/usr/bin/env perl

use v5.20;
use utf8;
use strict;
use warnings;

use Path::Tiny;

my $PATCH_VERSION = 1;

#
# clear repo
#
path($_)->remove_tree for qw(
    .gitignore
    .pause
    MANIFEST.SKIP
    Makefile.PL
    cpanfile
    dist.ini
    lib/OpenCloset/
    t/lib/OpenCloset/
);

#
# remove file
#
path($_)->remove for qw(
    Build.PL
    Makefile.PL
    README
);

#
# generate skeleton file
#
path($_)->touch for qw(
    .gitignore
    .pause
    MANIFEST.SKIP
    Makefile.PL
    cpanfile
    dist.ini
);

#
# .gitignore
#
path(".gitignore")->spew_utf8(<<'END_CONTENT');
*.bak
*.old
*.tar.gz
*.tmp
*~
.pause
/.build
/.tidyall.d
/Build
/Build.bat
/MYMETA.yml
/Makefile
/PM_to_blib
/_build
/blib
/cover_db
/pm_to_blib

/OpenCloset-Patch-DateTime-Format-Human-Duration-*
END_CONTENT

#
# .pause
#
path(".pause")->spew_utf8(<<'END_CONTENT');
user
password
END_CONTENT

#
# dist.ini
#
path("dist.ini")->spew_utf8(<<'END_CONTENT');
name              = OpenCloset-Patch-DateTime-Format-Human-Duration
author            = 김도형 - Keedi Kim <keedi@cpan.org>
license           = Perl_5
copyright_holder  = SILEX

[@DAGOLDEN]
authority                                   = cpan:KEEDI
CopyFilesFromBuild::Filtered.copy[]         = cpanfile
Test::MinimumVersion.max_target_perl        = 5.012
Git::CheckFor::CorrectBranch.release_branch = release
Git::Tag.tag_message                        = Release %v
Test::Version.has_version                   = 0

stopwords = CLDR
stopwords = Essencially
stopwords = MERCHANTABILITY
stopwords = Muey
stopwords = Rolksy
stopwords = TODO
stopwords = That'd
stopwords = XYZ
stopwords = expediate
stopwords = expediate,
stopwords = localizable
stopwords = reparsing
stopwords = reuseable

UploadToCPAN.upload_uri     = https://cpan.theopencloset.net
UploadToCPAN.pause_cfg_dir  = .
UploadToCPAN.pause_cfg_file = .pause
END_CONTENT

#
# MANIFEST.SKIP
#
path("MANIFEST.SKIP")->spew_utf8(<<'END_CONTENT');
patch.pl
END_CONTENT

#
# substitute namespace
#

path("lib/OpenCloset/Patch")->mkpath;
path("lib/DateTime")->move("lib/OpenCloset/Patch/DateTime");

path("t/lib/OpenCloset/Patch")->mkpath;
path("t/lib/DateTime")->move("t/lib/OpenCloset/Patch/DateTime");

my $state = path(".")->visit(
    sub {
        my ($path, $state) = @_;

        return if $path->is_dir;
        return if -B $path;
        return if $path =~ m/^\./;
        return if $path->basename =~ m/^\./;
        return if $path->absolute eq path(__FILE__)->absolute;

        $state->{list} = [] unless exists $state->{list};
        push @{ $state->{list} }, $path;
    },
    { recurse => 1 }
);

for my $path ( @{ $state->{list} } ) {
    my $content = $path->slurp_utf8;
    $content =~ s{DateTime::Format::Human::Duration}{OpenCloset::Patch::DateTime::Format::Human::Duration}gms;
    $content =~ s{DateTime/Format/Human/Duration}{OpenCloset/Patch/DateTime/Format/Human/Duration}gms;
    $content =~ s{our \$VERSION = '(.*?)';}{our \$VERSION = 'v$1.$PATCH_VERSION';}gms;
    $path->spew_utf8($content);
}

{
    my $path = path("Changes");
    my $content = $path->slurp_utf8;
    $content =~ s{(Revision history for) DateTime-Format-Human-Duration}{$1 OpenCloset-Patch-DateTime-Format-Human-Duration\n\n{{ \$NEXT }}\n       * Patch for OpenCloset}gms;
    $path->spew_utf8($content);
}

#
# for Dist::Zilla test
#
{
    {
        my $path = path("lib/OpenCloset/Patch/DateTime/Format/Human/Duration/Locale.pm");

        my $content = $path->slurp_utf8;
        $content .= <<"END_CONTENT";

# ABSTRACT: ...

=for Pod::Coverage calc_locale determine_locale_from
END_CONTENT
        $path->spew_utf8($content);
    }

    for my $path ( path("lib/OpenCloset/Patch/DateTime/Format/Human/Duration/Locale")->children ) {
        return if $path->is_dir;
        return if -B $path;
        return if $path =~ m/^\./;
        return if $path->basename =~ m/^\./;
        return unless $path->basename =~ m/\.pm$/;

        my $content = $path->slurp_utf8;
        $content .= <<"END_CONTENT";

# ABSTRACT: ...

=for Pod::Coverage get_human_span_hashref get_human_span_from_units
END_CONTENT
        $path->spew_utf8($content);
    }
}

#
# remove from git
#
for my $file ( qw(
    Build.PL
    README
    lib/DateTime/Format/Human/Duration.pm
    lib/DateTime/Format/Human/Duration
) )
{
    system "git", "rm", "-r", $file;
}

#
# add to git
#
for my $file ( qw(
    .gitignore
    Changes
    MANIFEST.SKIP
    Makefile.PL
    cpanfile
    dist.ini
    lib/
    t/
    xt/
) )
{
    system "git", "add", $file;
}

#
# test & commit
#
system "prove", "-lv", "t/", "xt/";
system "git", "st";
system "git", "commit", "-m", "Patch for OpenCloset";

#
# build & commit again
#
system "dzil", "build";
for my $file ( qw(
    Makefile.PL
    cpanfile
) )
{
    system "git", "add", $file;
}
system "git", "commit", "--amend", "-m", "Patch for OpenCloset";
