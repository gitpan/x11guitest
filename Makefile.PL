use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
        'NAME'      => 'X11::GUITest',
		($] ge '5.005') ? (
			'AUTHOR'        => 'Dennis K. Paulsen',
			'ABSTRACT'      => 'Collection of functions for X11 GUI testing/interaction.',
		) : (),
	    'VERSION_FROM' => 'GUITest.pm', # finds $VERSION
        'LIBS'  => ['-L/usr/X11R6/lib -lX11 -lXtst'], # e.g., '-lm'
        'DEFINE' => '-DNDEBUG',     # e.g., '-DHAVE_SOMETHING'
        'INC'   => '-I/usr/X11R6/include',     # e.g., '-I/usr/include/other'
	    'CCFLAGS' => '-Werror', 
#    'OPTIMIZE' => '-Od'
);
