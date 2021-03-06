#! /usr/bin/perl -w
eval 'exec perl -S $0 ${1+"$@"}'
    if 0; #$running_under_some_shell

# ======================================================================
# splitindex.pl
# Copyright (c) Markus Kohm, 2002-2009
#
# $Id: splitindex.pl,v 1.3 2009-03-20 14:55:11 mjk Exp $
#
# This file is part of the SplitIndex bundle.
#
# This work may be distributed and/or modified under the conditions of
# the LaTeX Project Public License, version 1.3c of the license.
# The latest version of this license is in
#   http://www.latex-project.org/lppl.txt
# and version 1.3c or later is part of all distributions of LaTeX
# version 2005/12/01 or later and of this work.
#
# This work has the LPPL maintenance status "author-maintained".
#
# The Current Maintainer and author of this work is Markus Kohm.
#
# The list of all files belongig to the SplitIndex bundle is given in
# in the file `manifest.txt'. Files generated by means of unpacking the
# distribution (using, for example, the docstrip program) or by means
# of compiling them from a source file, for example, from splitindex.c
# or splitindex.java may be distributed at the distributor's discretion.
# However if they are distributed then a copy of the SplitIndex bundle
# must be distributed together with them.
#
# The list of derived (unpacked or compiled) files belongig to the 
# distribution and covered by LPPL is defined by the unpacking scripts 
# (with extension .ins) and the installation script (with name 
# install.sh) which are part of the distribution.
#
# Two often ignorred clauses from LPPL 1.3c you should not ignore:
# ----------------------------------------------------------------
# 2. You may distribute a complete, unmodified copy of the Work as you
#    received it.  Distribution of only part of the Work is considered
#    modification of the Work, and no right to distribute such a Derived
#    Work may be assumed under the terms of this clause.
# 3. You may distribute a Compiled Work that has been generated from a
#    complete, unmodified copy of the Work as distributed under Clause 2
#    above, as long as that Compiled Work is distributed in such a way that
#    the recipients may install the Compiled Work on their system exactly
#    as it would have been installed if they generated a Compiled Work
#    directly from the Work.
# ======================================================================

use strict;
use Getopt::Long;

my $makeindex = "makeindex";
# my $identify = "^(.*)\\\\UseIndex *\\{([^\\}]*)\\}(.*)\$";
my $identify = "^(\\\\indexentry)\\[([^]]*)\\](.*)\$";
my $suffixis = "-\$2";
my $lineis = "\$1\$3";
my $verbose = 0;   # option verbose with default value 
my $result = GetOptions(
			'help' => sub { help() },
			'makeindex=s' => \$makeindex,
			'identify=s' => \$identify,
			'resultis=s' => \$lineis,
			'suffixis=s' => \$suffixis,
			'verbose|v+' => \$verbose,
			 'version' => sub { version(); exit 0; } 
			);

usage("missing raw index file") if ( $#ARGV < 0 );

my $indexinput = shift;
my $jobname    = ( $indexinput =~ /^(.*)\.idx$/ ) ? $1 : $indexinput;

my %idxfile;
my %linesatidxfile;

version() if ($verbose > 0);

if ( !( open (IDX,"<$indexinput") ) ) {
    if ( $indexinput ne "$jobname.idx" ) {
	open (IDX,"<$jobname.idx") ||
	    die "Cannot read raw index file $indexinput nor $jobname.idx";
	$indexinput = "$jobname.idx";
    } else {
	die "Cannot read raw index file $indexinput";
    }
}

while (<IDX>) {
    my $line;
    my $suffix;
    if ( /$identify/ ) {
	my $eval = "\$line = \"$lineis\n\"";
	eval $eval;
	$eval = "\$suffix = \"$suffixis\"";
	eval $eval;
    } else {
	$line = $_;
	$suffix = "";
	$suffix .= "$1" if ( $suffixis =~ /^(.*)\$/ );
	$suffix .= "idx";
	$suffix .= "$1" if ( $suffixis =~ /\$[123456789](.*)$/ );
    }
    while ( $suffix =~ /(^[^,]+)(.*)$/ ) {
	$suffix = $2;
	writetoidx ($1,$line);
    }
}

closeallind();

close(IDX);

generateallind(@ARGV);

exit 0;

sub generateallind {
    my $name;
    my $file;
    
    if ( $makeindex ne "" ) {
	while (($name,$file) = each %idxfile) {
	    system( "$makeindex @ARGV $jobname$name.idx" );
	}
    }
}

sub closeallind {
    my $name;
    my $file;
    my $lines;
    while (($name,$file) = each %idxfile) {
	print "Close $jobname$name.idx\n" 
	    if ( $verbose > 1 );
	close( $file );
	$idxfile{$name}=0;
    }
    if ( $verbose > 0 ) {
	print "\n";
	while (($name,$lines) = each %linesatidxfile) {
	    print "$jobname$name.idx with $lines lines\n";
	}
    }
}

sub writetoidx {
    my $suffix = $_[0];
    my $line = $_[1];
    my $file = $idxfile{$suffix};
    if ( ! $file ) {
	open ( $file, ">$jobname$suffix.idx" ) ||
	    die "Cannot write to file $jobname$suffix.idx";
	$idxfile{$suffix} = $file;
	$linesatidxfile{$suffix} = 0;
	print( "New index file $jobname$suffix.idx\n" )
	    if ( $verbose > 1 );
    }
    print ($file $line);
    $linesatidxfile{$suffix}++;
}

sub help {
    version();
    print "\n";
    usage();
    print  	
	"Split a single raw index file into multiple raw index files.\n".
	"Example: splitindex.pl foo.idx.\n".
	"\n".
	"Options:\n" .
	"  -h, --help    " .
	"\tshow this help and terminate\n" .
	"  -m, --makeindex PROGNAME\n" .
	"\t\t\tcall PROGNAME instead of default \`makeindex\'.\n" .
	"  -i, --identify EXPRESSION\n" .
	"\t\t\tuse regular EXPRESSION to match entries\n".
	"\t\t\t(see also option --resultis and --suffixis).\n".
	"\t\t\tDefault is \'$identify\'.\n".
	"  -r, --resultis PATTERN\n" .
	"\t\t\tcreate line to be written from PATTERN after matching\n".
	"\t\t\tlines (see also option --identify).\n".
	"\t\t\tDefault is \'$lineis\'.\n".
	"  -s, --suffixis PATTERN\n" .
	"\t\t\tcreate suffix to be used from PATTERN after matching\n".
	"\t\t\tlines (see also option --identify).\n".
	"\t\t\tDefault is \'$suffixis\'.\n".
	"  -v, --verbose " .
	"\tbe more verbose\n".
	"\t\t\t(can be used multiple to increase verbosity)\n" .
	"      --version " .
	"\tshow version and terminate\n";
    exit 0;
}

sub version {
    print "splitindex.pl 0.1\n" .
	"Copyright (c) 2002 Markus Kohm \<kohm\@gmx.de\>\n";
}

sub usage {
    my $text = "Usage: splitindex.pl [OPTION]... RAWINDEXFILE [MAKEINDEXOPTION]...\n";
    if ( $#_ >= 0 ) {
	print STDERR @_;
	print STDERR "\n$text";
	print STDERR "Try \`splitindex.pl --help\' for more information.\n";
	exit 1;
    } else {
	print $text;
    }
}
