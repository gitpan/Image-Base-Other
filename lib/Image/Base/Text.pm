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


package Image::Base::Text;
use 5.004;  # maybe one day 5.005 for 4-arg substr() replacing
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Text::Tabs ();
use vars '$VERSION', '@ISA';

$VERSION = 3;

use Image::Base 1.09; # version 1.09 for ellipse() fixes chaining up to that
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments;


use constant default_colour_to_character => { 'black'         => ' ',
                                              'clear'         => ' ',
                                              '#000000'       => ' ',
                                              '#000000000000' => ' ',
                                              other           => '*',
                                            };

sub new {
  my ($class, %param) = @_;

  if (ref $class) {
    # clone by copying fields and data array
    my $self = bless { %$class }, $class;
    $self->{'-rows_array'} = [ @{$class->{'-rows_array'}} ];
    return $self;
  }

  my $self = bless
    { -rows_array          => [],
      -width               => 0,
      -colour_to_character => $class->default_colour_to_character,
    }, $class;

  if (defined (my $filename = delete $param{'-file'})) {
    $self->load($filename);
  }
  $self->set (%param);
  return $self;
}

sub _get {
  my ($self, $key) = @_;
  # ### Image-Base-Text _get(): $key

  if ($key eq '-height') {
    return scalar @{$self->{'-rows_array'}};
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### set(): \%param

  if (defined (my $width = delete $param{'-width'})) {
    foreach my $row (@{$self->{'-rows_array'}}) {
      if (length($row) < $width) {
        $row .= ' ' x ($width - length($row));
      } else {
        substr($row,$width) = '';
      }
    }
    # ready for -height to use
    $self->{'-width'} = $width;
  }

  if (defined (my $height = delete $param{'-height'})) {
    my $rows_array = $self->{'-rows_array'};
    if (@$rows_array >= $height) {
      ### rows_array shorten
      splice @$rows_array, $height;
    } else {
      ### rows_array extend by: ($height - scalar(@$rows_array))
      my $row = ' ' x $self->{'-width'};
      push @$rows_array, ($row) x ($height - scalar(@$rows_array));
    }
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-Text load()
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### $filename

  open my $fh, "<$filename" or croak "Cannot open $filename: $!";
  $self->load_fh ($fh);
  close $fh or croak "Error closing $filename: $!";
}

# these undocumented yet ...
sub load_fh {
  my ($self, $fh) = @_;
  ### Image-Base-Text load_fh(): $fh
  $self->load_lines (map {chomp; $_} <$fh>);
}
sub load_string {
  my ($self, $str) = @_;
  ### Image-Base-Text load_string(): $str
  # split
  my @lines = split /\n/, $str, -1;
  if (@lines && $lines[-1] eq '') {
    # drop the empty element after the last newline, but keep a non-empty
    # final element from chars without a final newline
    pop @lines;
  }
  $self->load_lines (@lines);
}
sub load_lines {
  my ($self, @rows_array) = @_;
  ### load_lines: @rows_array

  my $width = 0;
  foreach my $row (@rows_array) {
    $row = Text::Tabs::expand ($row);
    $width = max ($width, length($row));
  }

  $self->{'-rows_array'} = \@rows_array;
  $self->set (-width => $width);  # pad out shorter lines
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Text save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  my $fh;
  (open $fh, ">$filename"
   and $self->save_fh($fh)
   and close $fh)
    or croak "Error writing $filename: $!";
}

# these undocumented yet ...
sub save_fh {
  my ($self, $fh) = @_;
  my $rows_array = $self->{'-rows_array'};
  local $, = "\n";
  return print $fh @$rows_array,(@$rows_array ? '' : ());
}
sub save_string {
  my ($self) = @_;
  my $rows_array = $self->{'-rows_array'};
  return join ("\n", @$rows_array, (@$rows_array ? '' : ()));
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-Text xy(): @_[1 .. $#_]

  # supposed to clip? 
  return if ($x < 0 || $x >= $self->{'-width'}
             || $y < 0 || $y >= @{$self->{'-rows_array'}});

  for my $row ($self->{'-rows_array'}->[$y]) {
    if (@_ == 3) {
      return $self->character_to_colour (substr ($row, $x, 1));
    }
    substr ($row, $x, 1) = $self->colour_to_character($colour);
  }
}

sub rectangle {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-Text xy(): @_[1,$#_]

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  # supposed to clip?
  $x1 = max($x1,0);
  $y1 = max($y1,0);
  $x2 = min($x2,$self->{'-width'});
  my $rows_array = $self->{'-rows_array'};
  $y2 = min($y2,$#$rows_array);

  my $char = $self->colour_to_character($colour);
  my $x_width = $x2 - $x1 + 1;
  my $repl = $char x $x_width;

  # top, and whole thing if filled
  foreach my $y ($y1 .. ($fill ? $y2 : $y1)) {
    substr ($rows_array->[$y], $x1, $x_width) = $repl;
  }

  if (! $fill) {
    # sides, unfilled
    my @x = ($x1, ($x1 != $x2 ? $x2 : ()));
    for my $y ($y1+1 .. $y2-1) {
      for my $row ($rows_array->[$y]) {
        for my $x (@x) {
          substr ($row, $x, 1) = $char;
        }
      }
    }

    # bottom, if unfilled, and more than 1 high
    if ($y2 != $y1) {
      substr ($rows_array->[$y2], $x1, $x_width) = $repl;
    }
  }
}

sub colour_to_character {
  my ($self, $colour) = @_;
  ### colour_to_character(): $colour
  if (defined (my $char = $self->{'-colour_to_character'}->{$colour})) {
    return $char;
  }
  if (length($colour) == 1) {
    return $colour;
  }
  if (defined (my $char = $self->{'-colour_to_character'}->{'other'})) {
    return $char;
  }
  croak "Unknown colour: $colour";
}
sub character_to_colour {
  my ($self, $char) = @_;
  if (length ($char) == 0) {
    return undef;
  }
  if (defined (my $colour = $self->{'-character_to_colour'}->{$char})) {
    return $colour;
  }
  return $char;
}

1;
__END__

=for stopwords filename undef Ryde resizes

=head1 NAME

Image::Base::Text -- draw in a plain text file or grid

=head1 SYNOPSIS

 use Image::Base::Text;
 my $image = Image::Base::Text->new (-width  => 70,
                                     -height => 20);
 $image->rectangle (5,5, 65,15, '*');
 $image->save ('/some/filename.txt');

=head1 CLASS HIERARCHY

C<Image::Base::Text> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Text

=head1 DESCRIPTION

C<Image::Base::Text> extends C<Image::Base> to create or update text files
treated as grids of characters, or just to create a grid of characters in
memory.

Colours for drawing can be a single character to set in the image, or
there's an experimental C<-colour_to_character> attribute to map names to
characters.  Currently black, #000000, #000000000000 and clear all become
spaces and anything else becomes a "*".  Perhaps that will
change.

Perl wide characters can be used, in new enough Perl, though currently
there's nothing to set input or output encoding for file read/write (making
it fairly useless, unless perhaps you've got global PerlIO layers setup).

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::Text-E<gt>new (key=E<gt>value,...)>

Create and return an image object.  A image can be started with C<-width>
and C<-height>,

    $image = Image::Base::Text->new (-width  => 70,
                                     -height => 20);

Or an existing file can be read,

    $image = Image::Base::Text->new (-file => '/my/filename.txt');

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

Create and return a cloned copy of C<$image>.  The optional parameters are
applied to the new image as per C<set>.

=item C<$image-E<gt>load ()>

=item C<$image-E<gt>load ($filename)>

Read a text file into C<$image>, either from the current C<-file> option, or
set that option to C<$filename> and read from there.

Tab characters in the file are expanded to spaces per C<Text::Tabs>.  Its
C<$Text::Tabs::tabstop> controls the width of each tab.

C<-height> is set to the number of lines in the file, possibly zero.
C<-width> is set to the widest line in the file and other lines are padded
with spaces to that width as necessary.

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save the image to a text file, either the current C<-file> option, or set
that option to C<$filename> and save to there.

Trailing spaces are included in the output so that the width is represented
in the file, and to keep it a rectangular grid.  Tabs are not used in the
output.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting these resizes an image, either truncating or extending.  When
extending the new area is initialized to space characters.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Text::Tabs>,
L<Image::Xpm>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-other/index.html

=head1 LICENSE

Image-Base-Other is Copyright 2010 Kevin Ryde

Image-Base-Other is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Image-Base-Other is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
