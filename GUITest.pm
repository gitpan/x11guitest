# X11::GUITest - GUITest.pm
#  
# Copyright (c) 2003  Dennis K. Paulsen, All Rights Reserved.
# Email: ctrondlp@users.sourceforge.net
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#

=head1 NAME

X11::GUITest - Provides GUI testing/interaction facilities

Developed by Dennis K. Paulsen

=head1 SYNOPSIS

  use X11::GUITest qw/
    StartApp
    WaitWindowViewable
    SetInputFocus
    SendKeys
  /;

  # Start gedit application
  StartApp('gedit');

  # Wait for application window to come up and become viewable. 
  my ($GEditWinId) = WaitWindowViewable('gedit');
  if (!$GEditWinId) {
    die("Couldn't find gedit window in time!");
  }

  # Ensure input focus is set to the window
  SetInputFocus($GEditWinId);

  # Send text to it
  SendKeys("Hello, how are you?\n");

  # Close Application (Alt-f, q).
  SendKeys("%(f)q");

  # Handle gedit's Question window if it comes up when closing.  Wait
  # at most 5 seconds for it.
  if (WaitWindowViewable('Question', undef, 5)) {
    # DoN't Save (Alt-n)
    SendKeys("%(n)");
  }

=head1 INSTALLATION

  perl Makefile.PL
  make
  make test
  make install

=head1 DEPENDENCIES

An  X server with the XTest extensions enabled.  This seems to be the
norm.  If it is not enabled, it usually can be by modifying the X
server configuration (i.e., XF86Config).

=head1 DESCRIPTION

This Perl package is intended to facilitate the testing of GUI applications
by means of user emulation.  It can be used to test/interact with GUI
applications; which have been built upon the X toolkit or other toolkits
(i.e., GTK) that "wrap" X toolkit's functionality.

=head1 VERSION

0.10

=head1 CHANGES

0.10 Tue Mar 05 2003 18:00:00
- Initial Release.

=cut

package X11::GUITest;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    
);

@EXPORT_OK = qw(
	ClickMouseButton
	ClickWindow
	FindWindowLike
	GetChildWindows
	GetEventSendDelay
	GetInputFocus
	GetKeySendDelay
	GetRootWindow
	GetScreenDepth
	GetScreenRes
	GetWindowName
	GetWindowPos
	IconifyWindow
	IsWindow
	IsWindowViewable
	LowerWindow
	MoveMouseAbs
	MoveWindow
	RaiseWindow
	ResizeWindow
	RunApp
	SendKeys
	SetEventSendDelay
	SetInputFocus
	SetKeySendDelay
	StartApp
	UnIconifyWindow
	WaitWindowLike
	WaitWindowViewable
);

# (:ALL, etc.)
%EXPORT_TAGS = (
	'ALL' => \@EXPORT_OK,
	'CONST' => [qw(DEF_WAIT M_LEFT M_MIDDLE M_RIGHT)]
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);

$VERSION = '0.10';

# Module Constants
# Module Variables


bootstrap X11::GUITest $VERSION;

# Constants
# sub [NAME]() { [VALUE]; }
sub DEF_WAIT() { 10; }
# Mouse Buttons
sub M_LEFT() { 1; }
sub M_MIDDLE() { 2; }
sub M_RIGHT() { 3; }

=head1 FUNCTIONS

Parameters enclosed within [] are optional.  

If there are multiple optional parameters available for a function
and you would like to specify the last one, for example, you can
utilize undef for those parameters you don't specify.

REGEX in the documentation below denotes an item that is treated as 
a regular expression.  For example, the regex "^OK$" would look for
an exact match for the word OK.


=over 8

=item FindWindowLike TITLEREGEX [, WINDOWIDSTARTUNDER]

Finds the window Ids of the windows matching the specified title regex.  
Optionally one can specify the window to start under; which would allow
one to constrain the search to child windows of that window.

An array of window Ids is returned for the matches found.  An empty
array is returned if no matches were found.

  my @WindowIds = FindWindowLike('gedit');
  # Only worry about first window found
  my ($WindowId) = FindWindowLike('gedit');

=back

=cut

sub FindWindowLike {
	my $titlerx = shift;
	my $start = shift || GetRootWindow();
	my $winname = '';
	my @wins = ();

	# Match the root window???
	$winname = GetWindowName($start) || "";
	if ($winname =~ /$titlerx/i) {
		push @wins, $start;
	}
	
	# Match a child window?
	foreach my $child (GetChildWindows($start)) {
		my $winname = GetWindowName($child) || "";
		if ($winname =~ /$titlerx/i) {
			push @wins, $child;
		}
	}
	return(@wins);
}

=over 8

=item WaitWindowLike TITLEREGEX [, WINDOWIDSTARTUNDER] [, MAXWAITINSECONDS]

Waits for a window to come up that matches the specified title regex.  
Optionally one can specify the window to start under; which would allow
one to constrain the search to child windows of that window.  

One can optionally specify an alternative wait amount in seconds.  A
window will keep being looked for that matches the specified title regex
until this amount of time has been reached.  The default amount is defined
in the DEF_WAIT constant available through the :CONST export tag.

If a window is going to be manipulated by input, WaitWindowViewable is the
more robust solution to utilize.

An array of window Ids is returned for the matches found.  An empty
array is returned if no matches were found.

  my @WindowIds = WaitWindowLike('gedit');
  # Only worry about first window found
  my ($WindowId) = WaitWindowLike('gedit');

  WaitWindowLike('gedit') or die("gedit window not found!");

=back

=cut

sub WaitWindowLike {
	my $titlerx = shift;
	my $start = shift || GetRootWindow();
	my $wait = shift || DEF_WAIT;
	my @wins = ();

	# For each second we $wait, look for window title
	# twice (2 lookups * 500ms = 1 second).
	for (my $i = 0; $i < ($wait * 2); $i++) {
		my @wins = FindWindowLike($titlerx, $start);
		if (@wins) {
			return(@wins);
		}
		# Wait 500 ms in order not to bog down the system.  If one 
		# changes this, the ($wait * 2) above will want to be changed
		# in order to represent seconds correctly.
		select(undef, undef, undef, 0.50);
	}	
	# Nothing
	return(@wins);
}

=over 8

=item WaitWindowViewable TITLEREGEX [, WINDOWIDSTARTUNDER] [, MAXWAITINSECONDS]

Similar to WaitWindow, but only recognizes windows that are viewable.  When GUI
applications are started, their window isn't necessarily viewable yet, let alone
available for input, so this function is very useful.

Likewise, this function will only return an array of the matching window Ids for
those windows that are viewable.  An empty array is returned if no matches were
found.

=back

=cut

sub WaitWindowViewable {
	my $titlerx = shift;
	my $start = shift || GetRootWindow();
	my $wait = shift || DEF_WAIT;
	my @wins = ();

	# For each second we $wait, look for window title
	# twice (2 lookups * 500ms = 1 second).
	for (my $i = 0; $i < ($wait * 2); $i++) {
		# Find windows and recognizes only those that are viewable
		foreach my $win (FindWindowLike($titlerx, $start)) {
			if (IsWindowViewable($win)) {
				push @wins, $win;
			}
		}
		if (@wins) {
			return(@wins);
		}
		# Wait 500 ms in order not to bog down the system.  If one 
		# changes this, the ($wait * 2) above will want to be changed
		# in order to represent seconds correctly.
		select(undef, undef, undef, 0.50);
	}	
	# Nothing
	return(@wins);
}

=over 8

=item ClickWindow  WINDOWID [, X Offset] [, Y Offset] [, Button]

Clicks on the specified window with the mouse.

Optionally one can specify the X offset and Y offset.  By default,
the top left corner of the window is clicked on, with these two
parameters one can specify a different position to be clicked on.

One can also specify an alternative button.  The default button is
M_LEFT, but M_MIDDLE and M_RIGHT are also available through the
:CONST export tag.

zero is returned on failure, non-zero for success

  ClickWindow('gedit');

=back

=cut

sub ClickWindow {
	my $win = shift;
	my $x_offset = shift || 0;
	my $y_offset = shift || 0;
	my $button = shift || M_LEFT;

	my ($x, $y) = GetWindowPos($win);
	if (!defined($x) or !defined($y)) {
		return(0);
	}
	if (!MoveMouseAbs($x + $x_offset, $y + $y_offset)) {
		return(0);
	}
	if (!ClickMouseButton($button)) {
		return(0);
	}
	return(1);
}

=over 8

=item StartApp COMMANDLINE

Uses the shell to execute a program.  A primative method is used
to detach from the shell, so this function returns as soon as the
program is called.  Useful for starting GUI applications and then
going on to work with them.

zero is returned on failure, non-zero for success

  StartApp('gedit');

=back

=cut

sub StartApp {
	my $CmdLine = shift;

	# Add ampersand if not present to detach program from shell, allowing
	# this function to return before application is finished running.
	# RegExp: [&][zero or more whitespace][anchor, nothing to follow whitespace]
	if ($CmdLine !~ /\&\s*$/) {
		$CmdLine .= " &"; 
	}
	local $! = '';
	system($CmdLine);

	# Limited to catching specific problems due to detachment from shell
	return( (length($!) == 0) );
}

=over 8

=item RunApp COMMANDLINE

Uses the shell to execute a program until its completion.

Return value will be application specific, however -1 is returned
to indicate a failure in starting the program.

  RunApp('/work/myapp');

=back

=cut

sub RunApp {
	my $CmdLine = shift;
	return( system($CmdLine) );
}


# Subroutine: INIT
# Description: Used to initialize the underlying mechanisms
#			   that this package utilizes. 
# Note: Perl idiom not to return values for this subroutine.
sub INIT {
	InitGUITest();
}

# Subroutine: END
# Description: Used to deinitialize the underlying mechanisms
#			   that this package utilizes.
# Note: Perl idiom not to return values for this subroutine.
sub END {
	DeInitGUITest();
}

# Autoload methods go after __END__, and are processed by the autosplit program.

# Return success
1;
__END__
