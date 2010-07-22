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

use Smart::Comments;

{
  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 10, -height => 10);
  $image->rectangle (0,0, 9,9, 'black');
  $image->rectangle (3,3, 7,7, '#FFFF0000FFFF');

  exit 0;
}
