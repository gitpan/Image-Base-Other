#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use warnings;
use Test::More tests => 1008;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Image::Base::Text;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 2;
  is ($Image::Base::Text::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::Text->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::Text->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::Text->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $image = Image::Base::Text->new;
  is ($image->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $image->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $image = Image::Base::Text->new (-width => 6,
                                                      -height => 7);
  is ($image->get('-file'), undef);
  is ($image->get('-height'), 7);
  isa_ok ($image, 'Image::Base');
  isa_ok ($image, 'Image::Base::Text');
}

#------------------------------------------------------------------------------
# -width when -height 0

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  is ($image->get('-width'), 20);
  is ($image->get('-height'), 10);

  $image->set (-height => 0);
  is ($image->get('-width'), 20);
  is ($image->get('-height'), 0);
}

#------------------------------------------------------------------------------
# -width expand/contract

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  $image->set (-width => 20);
  is ($image->xy(15,0), ' ', '-width increase fills with spaces');

  $image->set (-width => 20);
  $image->set (-width => 15);
  is ($image->get('-width'), 15);
}

#------------------------------------------------------------------------------
# -height expand/contract

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  $image->set (-height => 20);
  is ($image->xy(5,15), ' ', '-height increase fills with spaces');

  $image->set (-height => 20);
  $image->set (-height => 15);
  is ($image->get('-height'), 15);
}

#------------------------------------------------------------------------------
# load_lines()

{
  my $image = Image::Base::Text->new;
  $image->load_lines ("* *", " * ");
  is ($image->get('-width'), 3);
  is ($image->get('-height'), 2);
  $image->xy (0,0, '*');
  $image->xy (1,0, ' ');
  $image->xy (2,0, '*');
  $image->xy (0,1, ' ');
  $image->xy (1,1, '*');
  $image->xy (2,1, ' ');
}

#------------------------------------------------------------------------------
# load_string()

{
  my $image = Image::Base::Text->new;
  $image->load_string ("* *\n * \n");
  is ($image->get('-width'), 3);
  is ($image->get('-height'), 2);
  $image->xy (0,0, '*');
  $image->xy (1,0, ' ');
  $image->xy (2,0, '*');
  $image->xy (0,1, ' ');
  $image->xy (1,1, '*');
  $image->xy (2,1, ' ');
}

foreach my $elem (["", 0,0],
                  ["ab", 2,1],
                  ["ab\n", 2,1],
                  ["ab\n\n", 2,2],
                  ["ab\n\n\n", 2,3],
                  ["ab\ncde\n", 3,2],
                  ["ab\ncde", 3,2],

                  ["\nabcd\n", 4,2],
                  ["\n\nabcd\n", 4,3],
                  ["\nabcd\n\n", 4,3],
                  ["\n\n\n", 0,3],

                 ) {
  my ($str, $want_width, $want_height) = @$elem;
  my $image = Image::Base::Text->new;
  my $name = "load_string() $str";
  $image->load_string ($str);
  is ($image->get('-width'),  $want_width,  $name);
  is ($image->get('-height'), $want_height, $name);
}

#------------------------------------------------------------------------------
# save() / load()

my $want_file_temp_version = '0.14'; # for object-oriented interface
my $have_File_Temp = eval { require File::Temp;
                            File::Temp->VERSION($want_file_temp_version);
                            1 };
if (! $have_File_Temp) {
  diag "File::Temp $want_file_temp_version not available: $@";
}
# $File::Temp::KEEP_ALL = 1;
# $File::Temp::DEBUG = 1;

SKIP: {
  $have_File_Temp
    or skip 'File::Temp not available', 6;

  my $fh = File::Temp->new;
  my $filename = $fh->filename;
  diag "temp file ",$filename;

  # save file
  {
    my $image = Image::Base::Text->new (-width => 1,
                                        -height => 1);
    $image->xy (0,0, '*');
    $image->set(-file => $filename);
    is ($image->get('-file'), $filename);
    $image->save;
    ok (-e $filename, "tempfile $filename exists");
    cmp_ok (-s $filename, '>', 0, "tempfile $filename not empty");
    # system ("cat $filename");
  }

  # existing file with new(-file)
  {
    my $image = Image::Base::Text->new (-file => $filename);
    is ($image->get('-file'), $filename);
    is_deeply ($image->{'-rows_array'}, [ "*" ]);
    is ($image->xy (0,0), '*');
  }

  # existing file with load()
  {
    my $image = Image::Base::Text->new (-width => 1,
                                        -height => 1);
    $image->load ($filename);
    is ($image->get('-file'), $filename);
    is ($image->xy (0,0), '*');
  }
}


#------------------------------------------------------------------------------
# colour_to_character

{
  my $image = Image::Base::Text->new (-width => 1, -height => 1);

  is ($image->colour_to_character(' '),
      $image->colour_to_character(' '));
  is ($image->colour_to_character('*'),
      $image->colour_to_character('*'));
}

#------------------------------------------------------------------------------
# line

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->line (5,5, 7,7, '*', 0);
  is ($image->xy (4,4), ' ');
  is ($image->xy (5,5), '*');
  is ($image->xy (5,6), ' ');
  is ($image->xy (6,6), '*');
  is ($image->xy (7,7), '*');
  is ($image->xy (8,8), ' ');
}
{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->line (0,0, 2,2, '*', 1);
  is ($image->xy (0,0), '*');
  is ($image->xy (1,1), '*');
  is ($image->xy (2,1), ' ');
  is ($image->xy (3,3), ' ');
}

#------------------------------------------------------------------------------
# xy

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->xy (2,2, ' ');
  $image->xy (3,3, '*');
  is ($image->xy (2,2), ' ', 'xy()  ');
  is ($image->xy (3,3), '*', 'xy() *');
}

#------------------------------------------------------------------------------
# rectangle

{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->rectangle (5,5, 7,7, '*', 0);
  is ($image->xy (5,5), '*');
  is ($image->xy (5,6), '*');
  is ($image->xy (5,7), '*');

  is ($image->xy (6,5), '*');
  is ($image->xy (6,6), ' ');
  is ($image->xy (6,7), '*');

  is ($image->xy (7,5), '*');
  is ($image->xy (7,6), '*');
  is ($image->xy (7,7), '*');

  is ($image->xy (7,8), ' ');
  is ($image->xy (8,7), ' ');
  is ($image->xy (8,8), ' ');
}
{
  my $image = Image::Base::Text->new (-width => 20,
                                                      -height => 10);
  $image->rectangle (0,0, 19,9, ' ', 1);
  $image->rectangle (0,0, 2,2, '*', 1);
  is ($image->xy (0,0), '*');
  is ($image->xy (1,1), '*');
  is ($image->xy (2,1), '*');
  is ($image->xy (3,3), ' ');
}

#------------------------------------------------------------------------------
# get('-file')

{
  my $image = Image::Base::Text->new (-width => 10,
                                                      -height => 10);
  is (scalar ($image->get ('-file')), undef);
  is_deeply  ([$image->get ('-file')], [undef]);
}

#------------------------------------------------------------------------------

{
  require MyTestImageBase;
  my $image = Image::Base::Text->new
    (-width => 21,
     -height => 10,
     -character_to_colour => { ' ' => 'black',
                               '*' => 'white' });
  MyTestImageBase::check_image ($image,
                                base_ellipse => 1);
}

exit 0;
