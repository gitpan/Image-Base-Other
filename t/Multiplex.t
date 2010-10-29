#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
use Test::More tests => 1899;

use lib 't';
use MyTestHelpers;
MyTestHelpers::nowarnings();

require Image::Base::Multiplex;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 3;
  is ($Image::Base::Multiplex::VERSION, $want_version, 'VERSION variable');
  is (Image::Base::Multiplex->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Image::Base::Multiplex->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Image::Base::Multiplex->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $multiplex = Image::Base::Multiplex->new;
  is ($multiplex->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $multiplex->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $multiplex->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# new()

{
  my $multiplex = Image::Base::Multiplex->new;
  isa_ok ($multiplex, 'Image::Base');
  isa_ok ($multiplex, 'Image::Base::Multiplex');

  is_deeply ($multiplex->get('-images'), [], '-images default empty []');

  $multiplex->add_colours ('black');
  ok (1, 'add_colours() when no images');
}

{
  require Image::Base::Text;
  my $text = Image::Base::Text->new (-width => 6,
                                     -height => 7);
  my $multiplex = Image::Base::Multiplex->new (-images => [$text]);
  is_deeply ($multiplex->get('-images'), [$text], '-images one Text');
  is ($multiplex->get('-width'), 6);
  is ($multiplex->get('-height'), 7);

  $multiplex->xy (0,0, '*');
  is ($text->xy(0,0), '*');

  $multiplex->add_colours ('black');
  ok (1, 'add_colours() to one Text');
}

{

  require Image::Base::Text;
  my $text1 = Image::Base::Text->new (-width => 6,
                                      -height => 7);
  my $text2 = Image::Base::Text->new (-width => 8,
                                      -height => 9);

  my $multiplex = Image::Base::Multiplex->new (-images => [$text1,$text2]);
  is_deeply ($multiplex->get('-images'), [$text1,$text2], '-images two Text');

  $multiplex->xy (0,0, '*');
  is ($text1->xy(0,0), '*');
  is ($text2->xy(0,0), '*');

  $multiplex->add_colours ('black');
  ok (1, 'add_colours() to two Text');
}

{
  require Image::Base::Text;
  my $text = Image::Base::Text->new
    (-width => 21,
     -height => 10,
     -character_to_colour => { ' ' => 'black',
                               '*' => 'white' });
  my $multiplex = Image::Base::Multiplex->new (-images => [$text]);

  require MyTestImageBase;
  MyTestImageBase::check_image ($multiplex);
}

exit 0;
